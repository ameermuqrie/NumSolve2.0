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
import model.User;

@WebServlet("/AdminQuizServlet")
public class AdminQuizServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        
        // Security Check: Must be logged in AND must be an Admin (R001)
        if (u == null || !"R001".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp");
            return;
        }

        // Handle deletion if the Admin clicked the delete button
        String action = request.getParameter("action");
        QuizDAO dao = new QuizDAO();
        
        if ("delete".equals(action)) {
            int quizId = Integer.parseInt(request.getParameter("id"));
            dao.deleteQuiz(quizId); // Reusing the delete method from Educator phase!
            response.sendRedirect("AdminQuizServlet?msg=Quiz+Deleted+Successfully");
            return;
        }

        // Fetch all quizzes for the dashboard
        List<Quiz> allQuizzes = dao.getAllQuizzesForAdmin();
        request.setAttribute("adminQuizzes", allQuizzes);
        
        request.getRequestDispatcher("admin_quizzes.jsp").forward(request, response);
    }
}