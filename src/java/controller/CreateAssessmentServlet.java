package controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import dao.AssignmentDAO;
import dao.ClassDAO;
import model.Classroom;
import model.User;

@WebServlet("/CreateAssessmentServlet")
public class CreateAssessmentServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Security Check
        User u = (User) request.getSession().getAttribute("user");
        if (u == null || !"R002".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp");
            return;
        }

        try {
            // 2. Get Data from the Modal Form
            int classId = Integer.parseInt(request.getParameter("classId"));
            String title = request.getParameter("title");
            String allowedFormat = request.getParameter("allowedFormat");
            
            // 3. Class Ownership Verification (Crucial Security Check)
            ClassDAO classDao = new ClassDAO();
            Classroom currentClass = classDao.getClassById(classId);
            
            if (currentClass == null || currentClass.getUserId() != u.getUserId()) {
                response.sendRedirect("manage_classes.jsp?status=error");
                return;
            }
            
            // 4. MySQL needs a space instead of a "T" and seconds added, so we format it:
            String rawDueDate = request.getParameter("dueDate");
            String formattedDueDate = rawDueDate.replace("T", " ") + ":00";

            // 5. Save to Database
            AssignmentDAO dao = new AssignmentDAO();
            boolean success = dao.createAssignment(classId, title, formattedDueDate, allowedFormat);

            // 6. FIXED REDIRECT: Go back to view_class.jsp and open the quizzes tab
            if (success) {
                response.sendRedirect("view_class.jsp?id=" + classId + "&tab=quizzes&status=assessment_created");
            } else {
                response.sendRedirect("view_class.jsp?id=" + classId + "&tab=quizzes&status=error");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("manage_classes.jsp?status=error");
        }
    }
}