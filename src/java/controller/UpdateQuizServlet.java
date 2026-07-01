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
import javax.servlet.http.Part;
import model.*;
import dao.QuizDAO;

@WebServlet("/UpdateQuizServlet")
// REQUIRED to handle file uploads when the form is submitted back!
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 10,       // 10MB
    maxRequestSize = 1024 * 1024 * 50     // 50MB
)
public class UpdateQuizServlet extends HttpServlet {
    
    private static final String UPLOAD_DIR = "quiz_covers";

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. READ CONTEXT WITH CASE-INSENSITIVE SAFETY
        String viewContext = request.getParameter("view");
        String quizType = request.getParameter("quizType");
        
        // Determine if we must force the user to stay in the personal/private workspace
        boolean staysInPersonal = false;
        if (viewContext != null && viewContext.trim().equalsIgnoreCase("personal")) {
            staysInPersonal = true;
        }
        if (quizType != null && quizType.trim().equalsIgnoreCase("Private")) {
            staysInPersonal = true;
        }
        
        try {
            Quiz quiz = new Quiz();
            quiz.setQuizId(Integer.parseInt(request.getParameter("quizId"))); 
            quiz.setQuizTitle(request.getParameter("quizTitle"));
            quiz.setQuizDescription(request.getParameter("quizDescription"));
            quiz.setTimeLimit(request.getParameter("timeLimit"));
            quiz.setTotalMarks(request.getParameter("totalMarks"));
            quiz.setStatus("Active");
            
            // Check both 'classId' and 'classIdInput' to match your JSP form names perfectly
            String classIdStr = request.getParameter("classId");
            if (classIdStr == null || classIdStr.trim().isEmpty()) {
                classIdStr = request.getParameter("classIdInput");
            }
            
            quiz.setQuizType(quizType);
            if ("Private".equalsIgnoreCase(quizType)) {
                if (classIdStr != null && !classIdStr.trim().isEmpty() && !classIdStr.equals("0")) {
                    quiz.setClassId(Integer.parseInt(classIdStr));
                }
            } else {
                quiz.setClassId(null);
            }
            quiz.setVisibility("Public".equalsIgnoreCase(quizType) ? "Visible" : "Hidden");

            // =========================================================
            // UPDATE: FILE UPLOAD LOGIC 
            // =========================================================
            String existingPhotoPath = request.getParameter("existingPhotoPath");
            Part filePart = request.getPart("quizCover"); 
            
            if (filePart != null && filePart.getSize() > 0) {
                // User uploaded a NEW image, process it
                String uploadPath = request.getServletContext().getRealPath("/" + UPLOAD_DIR);
                File uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }

                String originalFileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
                String uniqueFileName = System.currentTimeMillis() + "_" + originalFileName.replaceAll("\\s+", "_");
                
                String filePath = uploadPath + File.separator + uniqueFileName;
                filePart.write(filePath);
                
                quiz.setPhotoPath(UPLOAD_DIR + "/" + uniqueFileName);
            } else {
                // User left the file input blank, keep the old image path
                quiz.setPhotoPath(existingPhotoPath); 
            }
            // =========================================================

            List<QuizQuestion> questionList = new ArrayList<>();
            int questionCount = Integer.parseInt(request.getParameter("questionCount"));
            
            for (int i = 1; i <= questionCount; i++) {
                String qText = request.getParameter("questionText_" + i);
                if (qText == null || qText.trim().isEmpty()) continue; 

                QuizQuestion question = new QuizQuestion();
                question.setQuestionText(qText);
                question.setExplanation(request.getParameter("explanation_" + i));
                String pointsStr = request.getParameter("points_" + i);
                question.setPoints((pointsStr != null && !pointsStr.isEmpty()) ? Integer.parseInt(pointsStr) : 10);
                
                List<QuestionOption> optionsList = new ArrayList<>();
                String correctOptStr = request.getParameter("correctOption_" + i);
                int correctOptionIndex = (correctOptStr != null && !correctOptStr.isEmpty()) ? Integer.parseInt(correctOptStr) : 1;

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

            QuizDAO quizDAO = new QuizDAO();
            boolean isSuccess = quizDAO.updateFullQuiz(quiz, questionList);

            // 2. CRASH-PROOF SUCCESS REDIRECT (Updated to point to educatorQuizzes)
            String message = isSuccess ? "Mission updated successfully!" : "Failed to update mission.";
            String encodedMessage = URLEncoder.encode(message, "UTF-8");
            String paramLabel = isSuccess ? "msg=" : "error=";
            
            StringBuilder targetUrl = new StringBuilder("educatorQuizzes?");
            
            if (staysInPersonal) {
                targetUrl.append("view=personal&");
            }
            if (classIdStr != null && !classIdStr.trim().isEmpty() && !classIdStr.equals("0")) {
                targetUrl.append("classId=").append(classIdStr).append("&");
            }
            targetUrl.append(paramLabel).append(encodedMessage);

            response.sendRedirect(targetUrl.toString());

        } catch (Exception e) {
            e.printStackTrace();
            
            // 3. CRASH-PROOF CATCH REDIRECT (Updated to point to educatorQuizzes)
            String errorMessage = "An error occurred while saving changes.";
            String encodedError = URLEncoder.encode(errorMessage, "UTF-8");
            
            String catchClassIdStr = request.getParameter("classId");
            if (catchClassIdStr == null || catchClassIdStr.trim().isEmpty()) {
                catchClassIdStr = request.getParameter("classIdInput");
            }

            StringBuilder targetUrl = new StringBuilder("educatorQuizzes?");
            
            if (staysInPersonal) {
                targetUrl.append("view=personal&");
            }
            if (catchClassIdStr != null && !catchClassIdStr.trim().isEmpty() && !catchClassIdStr.equals("0")) {
                targetUrl.append("classId=").append(catchClassIdStr).append("&");
            }
            targetUrl.append("error=").append(encodedError);
            
            response.sendRedirect(targetUrl.toString());
        }
    }
}