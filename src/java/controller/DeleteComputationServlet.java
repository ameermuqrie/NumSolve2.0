/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package controller;

import dao.ComputationDAO;
import model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/delete_computation")
public class DeleteComputationServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Security Check
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // 2. Get the computation ID from the URL
        String idParam = request.getParameter("id");
        
        if (idParam != null && !idParam.isEmpty()) {
            try {
                int compId = Integer.parseInt(idParam);
                ComputationDAO dao = new ComputationDAO();
                
                // 3. Delete securely (requires both computation ID and user ID)
                boolean isDeleted = dao.deleteComputation(compId, user.getUserId());
                
                if (isDeleted) {
                    response.sendRedirect("computations.jsp?msg=deleted");
                    return;
                }
            } catch (NumberFormatException e) {
                e.printStackTrace(); // Fails safely if someone messes with the URL string
            }
        }

        // 4. Redirect back if it fails or completes
        response.sendRedirect("computations.jsp?msg=error");
    }
}
