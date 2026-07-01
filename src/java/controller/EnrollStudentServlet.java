package controller;

import dao.ClassDAO;
import model.User;
import model.LogManager;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/EnrollStudentServlet")
public class EnrollStudentServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Security Check (Only Educators R002 can enroll)
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        if (u == null || !"R002".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp"); 
            return;
        }

        // 2. Grab IDs from the URL query string
        String classIdStr = request.getParameter("classId");
        String studentIdStr = request.getParameter("studentId");
        
        if (classIdStr != null && studentIdStr != null) {
            try {
                int classId = Integer.parseInt(classIdStr);
                int studentId = Integer.parseInt(studentIdStr);
                
                // 3. Enroll using DAO
                ClassDAO dao = new ClassDAO();
                
                if (dao.enrollStudent(classId, studentId)) {
                    // --- LOGGING: Student Enrollment ---
                    String logPath = getServletContext().getRealPath("/WEB-INF");
                    LogManager.logActivity(logPath, u.getUsername(), "Enrolled Student ID " + studentId + " into Class ID " + classId, "Educator");

                    // Redirect back to class_roster.jsp
                    response.sendRedirect("class_roster.jsp?classId=" + classId + "&status=enrolled");
                    return;
                }
            } catch (NumberFormatException e) {
                e.printStackTrace();
            }
        }
        
        // If it fails but we know the class ID, go back to the roster. Otherwise, manage_classes.
        if (classIdStr != null) {
            response.sendRedirect("class_roster.jsp?classId=" + classIdStr + "&status=error");
        } else {
            response.sendRedirect("manage_classes.jsp?status=error");
        }
    }
}