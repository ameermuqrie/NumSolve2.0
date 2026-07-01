package controller;

import java.io.File;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

import model.Quiz;
import model.QuizQuestion;
import model.QuestionOption;
import dao.QuizDAO;
import dao.ClassDAO;
import model.Classroom;
import model.User;
import model.LogManager;

@WebServlet("/CreateQuizServlet")
// MultipartConfig is REQUIRED to handle image file uploads
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 10,       // 10MB
    maxRequestSize = 1024 * 1024 * 50     // 50MB
)
public class CreateQuizServlet extends HttpServlet {
    
    // The exact name of your folder inside the "web" directory
    private static final String UPLOAD_DIR = "quiz_covers";

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Security & Role Check
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user"); 
        if (u == null || !"R002".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp");
            return;
        }

        String quizType = request.getParameter("quizType");
        String classIdStr = request.getParameter("classId");
        int classId = 0;

        try {
            // 2. Ownership Security Check (CRITICAL)
            if ("Private".equals(quizType)) {
                if (classIdStr != null && !classIdStr.trim().isEmpty() && !classIdStr.equals("0")) {
                    classId = Integer.parseInt(classIdStr);
                    ClassDAO classDao = new ClassDAO();
                    Classroom currentClass = classDao.getClassById(classId);
                    
                    // Prevent assigning a quiz to a class the educator doesn't own
                    if (currentClass == null || currentClass.getUserId() != u.getUserId()) {
                        response.sendRedirect("manage_classes.jsp?status=unauthorized");
                        return;
                    }
                }
            }

            // 3. Build the Quiz Object
            Quiz quiz = new Quiz();
            quiz.setQuizTitle(request.getParameter("quizTitle"));
            quiz.setQuizDescription(request.getParameter("quizDescription"));
            quiz.setTimeLimit(request.getParameter("timeLimit"));
            quiz.setStatus("Active");
            quiz.setUserId(u.getUserId()); 
            quiz.setQuizType(quizType);

            // Handle Public / Private Logic & Visibility
            if ("Private".equals(quizType) && classId > 0) {
                quiz.setClassId(classId);
                quiz.setVisibility("Hidden"); 
            } else {
                quiz.setClassId(null);
                quiz.setVisibility("Visible");
            }

            // =========================================================
            // NEW: DYNAMIC FILE UPLOAD LOGIC WITH NETBEANS HACK
            // =========================================================
            Part filePart = request.getPart("quizCover"); // Must match <input name="quizCover">
            
            if (filePart != null && filePart.getSize() > 0) {
                
                // Get the temporary build path
                String buildPath = request.getServletContext().getRealPath("");
                
                // --- NETBEANS HACK: Reroute to the permanent Source folder ---
                String savePath = buildPath;
                if (savePath.contains("build" + File.separator + "web")) {
                    savePath = savePath.replace("build" + File.separator + "web", "web");
                }
                
                // Append the target directory
                savePath = savePath + File.separator + UPLOAD_DIR;
                
                File uploadDir = new File(savePath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs(); 
                }

                // Get original filename and make it unique
                String originalFileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
                String uniqueFileName = System.currentTimeMillis() + "_" + originalFileName.replaceAll("\\s+", "_");
                
                // Write the file to the exact permanent path
                String filePath = savePath + File.separator + uniqueFileName;
                filePart.write(filePath);
                
                // Save THIS exact string format to the database (e.g., "quiz_covers/164344_math.png")
                quiz.setPhotoPath(UPLOAD_DIR + "/" + uniqueFileName);
                
            } else {
                // If the educator didn't upload a picture, set it to null so the JSP placeholder triggers
                quiz.setPhotoPath(null); 
            }
            // =========================================================

            // 4. Process Questions and Options (and auto-calculate total marks)
            List<QuizQuestion> questionList = new ArrayList<>();
            String countStr = request.getParameter("questionCount");
            int questionCount = (countStr != null && !countStr.isEmpty()) ? Integer.parseInt(countStr) : 0;
            
            int calculatedTotalMarks = 0;
            
            for (int i = 1; i <= questionCount; i++) {
                String qText = request.getParameter("questionText_" + i);
                if (qText == null || qText.trim().isEmpty()) continue; 

                QuizQuestion question = new QuizQuestion();
                question.setQuestionText(qText);
                question.setExplanation(request.getParameter("explanation_" + i));
                
                String pointsStr = request.getParameter("points_" + i);
                int points = (pointsStr != null && !pointsStr.isEmpty()) ? Integer.parseInt(pointsStr) : 10;
                question.setPoints(points);
                calculatedTotalMarks += points;
                
                List<QuestionOption> optionsList = new ArrayList<>();
                String correctOptStr = request.getParameter("correctOption_" + i);
                int correctOptionIndex = (correctOptStr != null) ? Integer.parseInt(correctOptStr) : 1;

                for (int j = 1; j <= 4; j++) {
                    String optText = request.getParameter("optionText_" + i + "_" + j);
                    if (optText != null && !optText.trim().isEmpty()) {
                        QuestionOption opt = new QuestionOption();
                        opt.setOptionText(optText);
                        opt.setCorrect(j == correctOptionIndex); 
                        optionsList.add(opt);
                    }
                }
                question.setOptions(optionsList);
                questionList.add(question);
            }

            quiz.setTotalMarks(String.valueOf(calculatedTotalMarks)); 

            // 5. Save to Database
            QuizDAO quizDAO = new QuizDAO();
            boolean isSuccess = quizDAO.createFullQuiz(quiz, questionList);

            // 6. Smart Redirection back to the private panel layout
            StringBuilder targetUrl = new StringBuilder("educatorQuizzes?");
            if ("Private".equals(quizType)) {
                targetUrl.append("view=personal&");
                if (classIdStr != null && !classIdStr.trim().isEmpty() && !classIdStr.equals("0")) {
                    targetUrl.append("classId=").append(classIdStr).append("&");
                }
            }
            
            if (isSuccess) {
                // --- LOGGING: Quiz Creation ---
                String logPath = getServletContext().getRealPath("/WEB-INF");
                LogManager.logActivity(logPath, u.getUsername(), "Created a new quiz mission titled: " + quiz.getQuizTitle(), "Educator");
            }

            String statusParam = isSuccess ? "status=" + URLEncoder.encode("quiz_created", "UTF-8") 
                                           : "error=" + URLEncoder.encode("Failed to save.", "UTF-8");
            targetUrl.append(statusParam);

            response.sendRedirect(targetUrl.toString());
            
        } catch (Exception e) {
            e.printStackTrace();
            
            StringBuilder errorUrl = new StringBuilder("educatorQuizzes?");
            if ("Private".equals(quizType)) {
                errorUrl.append("view=personal&");
                if (classIdStr != null && !classIdStr.trim().isEmpty() && !classIdStr.equals("0")) {
                    errorUrl.append("classId=").append(classIdStr).append("&");
                }
            }
            errorUrl.append("error=").append(URLEncoder.encode("An unexpected exception occurred.", "UTF-8"));
            response.sendRedirect(errorUrl.toString());
        }
    }
}