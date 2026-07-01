package controller;

import dao.ClassDAO;
import model.User;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/RemoveStudentServlet")
public class RemoveStudentServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Security Check
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        if (u == null || !"R002".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp"); return;
        }

        // 2. Grab IDs from the URL
        String classIdStr = request.getParameter("classId");
        String studentIdStr = request.getParameter("studentId");
        
        if (classIdStr != null && studentIdStr != null) {
            try {
                int classId = Integer.parseInt(classIdStr);
                int studentId = Integer.parseInt(studentIdStr);
                
                // 3. Remove using DAO
                ClassDAO dao = new ClassDAO();
                if (dao.removeStudentFromClass(classId, studentId)) {
                    // Redirect back to class_roster.jsp
                    response.sendRedirect("class_roster.jsp?classId=" + classId + "&status=removed");
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