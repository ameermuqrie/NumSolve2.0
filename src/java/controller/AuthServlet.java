package controller;

import dao.UserDAO;
import model.User;
import model.LogManager;
import java.io.IOException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/auth")
public class AuthServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        String action = req.getParameter("action");
        UserDAO dao = new UserDAO();
        String logPath = getServletContext().getRealPath("/WEB-INF"); // Path for logging

        if ("login".equals(action)) {
            String username = req.getParameter("username");
            User u = dao.login(username, req.getParameter("password"));

            if (u != null) {
                req.getSession().setAttribute("user", u);
                
                // --- LOGGING: Successful Login ---
                String roleName = "R001".equals(u.getRoleId()) ? "Admin" : "R002".equals(u.getRoleId()) ? "Educator" : "Student";
                LogManager.logActivity(logPath, username, "Logged into the platform securely.", roleName);

                if ("R001".equals(u.getRoleId()))
                    res.sendRedirect(req.getContextPath() + "/dashboard/admin.jsp");
                else if ("R002".equals(u.getRoleId()))
                    res.sendRedirect(req.getContextPath() + "/dashboard/educator.jsp");
                else
                    res.sendRedirect(req.getContextPath() + "/dashboard/student.jsp");

            } else {
                // --- LOGGING: Failed Login ---
                LogManager.logActivity(logPath, username, "Failed login attempt.", "Unknown");
                res.sendRedirect(req.getContextPath()+"/login.jsp?error=Invalid username or password");
            }
        }

        if ("register".equals(action)) {
            User u = new User();
            u.setUsername(req.getParameter("username"));
            u.setPassword(req.getParameter("password"));
            u.setFullName(req.getParameter("fullName"));
            u.setEmail(req.getParameter("email"));
            u.setRoleId(req.getParameter("role"));

            if (dao.register(u)) {
                // --- LOGGING: Successful Registration ---
                String roleName = "R002".equals(u.getRoleId()) ? "Educator" : "Student";
                LogManager.logActivity(logPath, u.getUsername(), "Created a new account on the platform.", roleName);
                
                res.sendRedirect(req.getContextPath()+"/login.jsp?msg=Registration successful. Please login.");
            } else {
                // --- LOGGING: Failed Registration ---
                LogManager.logActivity(logPath, u.getUsername(), "Registration failed.", "Unknown");
                res.sendRedirect(req.getContextPath()+"/register.jsp?error=Registration failed");
            }
        }
    }
}