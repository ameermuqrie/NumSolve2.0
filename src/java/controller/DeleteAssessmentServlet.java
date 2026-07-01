package controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import dao.AssignmentDAO;
import model.User;

@WebServlet("/DeleteAssessmentServlet")
public class DeleteAssessmentServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Security Check
        User u = (User) request.getSession().getAttribute("user");
        if (u == null || !"R002".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp");
            return;
        }

        try {
            // 2. Get IDs from URL
            int assessmentId = Integer.parseInt(request.getParameter("assessmentId"));
            String classIdStr = request.getParameter("classId");

            // 3. Delete from DB using the SECURE method (Verifies ownership)
            AssignmentDAO dao = new AssignmentDAO();
            boolean success = dao.deleteAssessmentSecure(assessmentId, u.getUserId());

            // 4. FIXED REDIRECT: Go back to view_class.jsp and open the quizzes tab
            if (success) {
                response.sendRedirect("view_class.jsp?id=" + classIdStr + "&tab=quizzes&status=assessment_deleted");
            } else {
                response.sendRedirect("view_class.jsp?id=" + classIdStr + "&tab=quizzes&status=error");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("manage_classes.jsp?status=error");
        }
    }
}