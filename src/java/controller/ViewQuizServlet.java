package controller;

import dao.QuizDAO;
import model.Quiz;
import model.QuizQuestion;
import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

// FIXED: Now it listens to BOTH "/viewQuiz" and "/ViewQuizServlet"
@WebServlet({"/viewQuiz", "/ViewQuizServlet"})
public class ViewQuizServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        String quizIdStr = request.getParameter("id");

        if (quizIdStr != null && !quizIdStr.trim().isEmpty()) {
            try {
                int quizId = Integer.parseInt(quizIdStr);
                QuizDAO dao = new QuizDAO();

                // 1. Fetch the main Quiz details
                Quiz quiz = dao.getQuizById(quizId);
                
                // 2. Fetch all questions and options for this quiz
                List<QuizQuestion> questions = dao.getQuestionsByQuizId(quizId);

                if (quiz != null) {
                    // 3. Attach data to the request so the JSP can read it
                    request.setAttribute("quiz", quiz);
                    request.setAttribute("questions", questions);
                    
                    // 4. Send the user to the viewing page
                    // (Change "view_quiz.jsp" if your viewing file has a different name)
                    request.getRequestDispatcher("view_quiz.jsp").forward(request, response);
                    return;
                }
            } catch (NumberFormatException e) {
                e.printStackTrace();
            }
        }
        
        // If the ID is missing or invalid, send them back
        response.sendRedirect("login.jsp"); 
    }
}