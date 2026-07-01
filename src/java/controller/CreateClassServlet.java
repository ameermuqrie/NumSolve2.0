package controller;

import dao.ClassDAO;
import model.Classroom;
import model.User;
import model.LogManager;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/CreateClassServlet")
public class CreateClassServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Security Check
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        
        // Ensure user is logged in AND is an Educator (R002)
        if (u == null || !"R002".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp");
            return;
        }

        // 2. Get Data from Form
        String className = request.getParameter("className");
        String classDesc = request.getParameter("classDescription");

        // BACKEND VALIDATION: Prevent empty class names from reaching the database
        if (className == null || className.trim().isEmpty()) {
            response.sendRedirect("manage_classes.jsp?status=empty_name");
            return;
        }

        // 3. Save to Database
        Classroom newClass = new Classroom(className, classDesc, u.getUserId());
        ClassDAO dao = new ClassDAO();
        
        if (dao.createClass(newClass)) {
            // --- LOGGING: Class Creation ---
            String logPath = getServletContext().getRealPath("/WEB-INF");
            LogManager.logActivity(logPath, u.getUsername(), "Established a new classroom workspace: " + className, "Educator");
            
            // Success! Send them back to their dashboard with a success flag
            response.sendRedirect("manage_classes.jsp?status=success");
        } else {
            // Failed (e.g., database error)
            response.sendRedirect("manage_classes.jsp?status=error");
        }
    }
}