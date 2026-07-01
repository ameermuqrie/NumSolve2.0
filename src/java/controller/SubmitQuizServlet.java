package controller;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.QuizDAO;
import model.Quiz;
import model.QuestionOption;
import model.QuizQuestion;
import model.User;

@WebServlet("/SubmitQuizServlet")
public class SubmitQuizServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        
        if (u == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int quizId;
        String classIdStr = request.getParameter("classId");
        Integer parsedClassId = null;
        
        // Parse the incoming classroom tracking context safely
        if (classIdStr != null && !classIdStr.trim().isEmpty() && !"null".equalsIgnoreCase(classIdStr.trim())) {
            try {
                parsedClassId = Integer.parseInt(classIdStr.trim());
            } catch (NumberFormatException e) {
                parsedClassId = null;
            }
        }
        
        try {
            quizId = Integer.parseInt(request.getParameter("quizId"));
        } catch (NumberFormatException e) {
            response.sendRedirect("StudentDashboardServlet?error=Invalid_Submission");
            return;
        }

        QuizDAO dao = new QuizDAO();
        Quiz quiz = dao.getQuizById(quizId);
        
        if (quiz == null) {
            response.sendRedirect("StudentDashboardServlet?error=Quiz_Not_Found");
            return;
        }

        // Anti-Cheat Check for Students
        if ("R003".equals(u.getRoleId())) {
            boolean alreadyTaken = dao.checkPreviousAttempt(u.getUserId(), quizId);
            if (alreadyTaken) {
                response.sendRedirect("StudentDashboardServlet?error=Quiz_Already_Completed");
                return;
            }
        }

        // --- CORE GRADING MECHANISM & ANSWER COMPARISON MAP ---
        List<QuizQuestion> questions = dao.getQuestionsByQuizId(quizId);
        int totalScoreAchieved = 0;
        int maxPossibleScore = 0;

        List<Map<String, Object>> reviewDetailsList = new ArrayList<>();

        for (QuizQuestion q : questions) {
            maxPossibleScore += q.getPoints();
            String selectedOptionStr = request.getParameter("q_" + q.getQuestionId());
            
            boolean isCorrect = false;
            String chosenText = "No Answer Provided";
            String correctText = "";

            for (QuestionOption opt : q.getOptions()) {
                if (opt.isCorrect()) {
                    correctText = opt.getOptionText();
                }
                if (selectedOptionStr != null && !selectedOptionStr.isEmpty()) {
                    try {
                        int currentOptId = Integer.parseInt(selectedOptionStr);
                        if (opt.getOptionId() == currentOptId) {
                            chosenText = opt.getOptionText();
                            if (opt.isCorrect()) {
                                totalScoreAchieved += q.getPoints();
                                isCorrect = true;
                            }
                        }
                    } catch (NumberFormatException e) {}
                }
            }

            // Group the metrics for output presentation
            Map<String, Object> questionReview = new HashMap<>();
            questionReview.put("text", q.getQuestionText());
            questionReview.put("points", q.getPoints());
            questionReview.put("chosen", chosenText);
            questionReview.put("correctAnswer", correctText);
            questionReview.put("isCorrect", isCorrect);
            reviewDetailsList.add(questionReview);
        }

        // Save entry with the parsedClassId so educators can access it
        if ("R003".equals(u.getRoleId())) {
            dao.saveQuizResult(quizId, u.getUserId(), totalScoreAchieved, maxPossibleScore, parsedClassId);
        }

        // Set attributes for quizResult.jsp 
        request.setAttribute("score", totalScoreAchieved);
        request.setAttribute("maxScore", maxPossibleScore);
        
        int percentage = (maxPossibleScore > 0) ? (int) Math.round(((double) totalScoreAchieved / maxPossibleScore) * 100) : 0;
        request.setAttribute("percentage", percentage);
        request.setAttribute("classId", parsedClassId);
        request.setAttribute("questionReviewList", reviewDetailsList);
        
        request.getRequestDispatcher("quizResult.jsp").forward(request, response);
    }
}