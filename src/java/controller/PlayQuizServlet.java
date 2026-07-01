package controller;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.QuizDAO;
import model.Quiz;
import model.QuizQuestion;
import model.User;

@WebServlet("/PlayQuizServlet")
public class PlayQuizServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        
        // Security check: Must be logged in AND must be either an Educator (R002) or a Student (R003)
        User u = (User) session.getAttribute("user");
        if (u == null || (!"R002".equals(u.getRoleId()) && !"R003".equals(u.getRoleId()))) {
            response.sendRedirect("login.jsp");
            return;
        }

        // CRITICAL FIX: The parameter we passed from the JSP is "quizId", not "id"
        String quizIdStr = request.getParameter("quizId");
        
        // Capture classId if this is a private class mission
        String classIdStr = request.getParameter("classId");

        if (quizIdStr != null && !quizIdStr.trim().isEmpty()) {
            try {
                int quizId = Integer.parseInt(quizIdStr);
                QuizDAO dao = new QuizDAO();
                
                // 1. Get the Quiz Details (for the title and the timer)
                Quiz quiz = dao.getQuizById(quizId);
                // 2. Get all the Questions and Options
                List<QuizQuestion> questions = dao.getQuestionsByQuizId(quizId);
                
                if (quiz != null && questions != null && !questions.isEmpty()) {
                    request.setAttribute("quiz", quiz);
                    request.setAttribute("questions", questions);
                    
                    // Pass along the classId if it exists so the submission servlet tracks the score properly
                    if (classIdStr != null && !classIdStr.trim().isEmpty()) {
                        request.setAttribute("classId", Integer.parseInt(classIdStr));
                    }
                    
                    // Send them to the arena!
                    request.getRequestDispatcher("gameplay.jsp").forward(request, response);
                    return;
                }
            } catch (NumberFormatException e) {
                // If a user tampers with the URL (e.g., ?quizId=abc), this catches the error silently
                System.out.println("Invalid quizId format attempted: " + quizIdStr);
            }
        }
        
        // If the quiz ID is invalid, has no questions, or parsing fails, route safely
        if ("R002".equals(u.getRoleId())) {
            response.sendRedirect("educatorQuizzes?error=Mission_Unavailable");
        } else {
            response.sendRedirect("student_quizzes.jsp?error=Mission_Unavailable");
        }
    }
}