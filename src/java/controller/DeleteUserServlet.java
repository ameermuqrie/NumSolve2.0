package controller;

import dao.UserDAO;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import model.User;

@WebServlet("/deleteUser")
public class DeleteUserServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute("user");
        
        // Security check
        if (currentUser == null || !"R001".equals(currentUser.getRoleId())) {
            response.sendRedirect("login.jsp");
            return;
        }

        String idStr = request.getParameter("id");
        if (idStr != null) {
            int userIdToDelete = Integer.parseInt(idStr);
            // Prevent deleting self
            if (userIdToDelete != currentUser.getUserId()) {
                new UserDAO().deleteUser(userIdToDelete);
            }
        }
        response.sendRedirect("users.jsp");
    }
}