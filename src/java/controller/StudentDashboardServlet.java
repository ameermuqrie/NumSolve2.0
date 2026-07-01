package controller;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import model.Quiz;
import dao.QuizDAO;

@WebServlet("/StudentDashboardServlet")
public class StudentDashboardServlet extends HttpServlet {
    
    // Handle standard URL link clicks (GET requests)
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        
        // Ensure the user is logged in
        if (session.getAttribute("user") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        QuizDAO quizDAO = new QuizDAO();
        
        // By passing 'null' here, our DAO will safely ignore classes and ONLY fetch 'Public' quizzes!
        List<Quiz> availableQuizzes = quizDAO.getAvailableQuizzes(null); 
        
        request.setAttribute("availableQuizzes", availableQuizzes);
        
        // Forward to the Mission Select UI
        request.getRequestDispatcher("student_quizzes.jsp").forward(request, response);
    }

    // ADDED: Route POST requests directly into the doGet logic to eliminate 404/405 errors
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        doGet(request, response);
    }
}