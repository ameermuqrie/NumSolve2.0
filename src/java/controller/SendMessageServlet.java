package controller;

import dao.MessageDAO;
import model.DirectMessage;
import model.User;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/SendMessageServlet")
public class SendMessageServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User currentUser = (User) session.getAttribute("user");
        
        if (currentUser == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String classIdStr = request.getParameter("classId");
        String receiverIdStr = request.getParameter("receiverId");
        String messageBody = request.getParameter("messageBody");

        if (classIdStr != null && receiverIdStr != null && messageBody != null && !messageBody.trim().isEmpty()) {
            try {
                int classId = Integer.parseInt(classIdStr);
                int receiverId = Integer.parseInt(receiverIdStr);
                int senderId = currentUser.getUserId();

                MessageDAO messageDAO = new MessageDAO();
                DirectMessage msg = new DirectMessage(classId, senderId, receiverId, messageBody);

                boolean isSent = false;

                // === CORRECTED GROUP CHAT LOGIC ===
                if (receiverId == -1) {
                    // Save to the specific class_messages table
                    isSent = messageDAO.sendGroupMessage(msg);
                } else {
                    // Standard 1-on-1 Private Message Logic
                    isSent = messageDAO.sendDirectMessage(msg);
                }
                // ==================================

                if (isSent) {
                    // Always redirect back to the exact conversation thread they were looking at
                    response.sendRedirect("class_qa.jsp?classId=" + classId + "&studentId=" + receiverId);
                } else {
                    request.setAttribute("errorMessage", "Database error: Could not send message.");
                    request.getRequestDispatcher("error.jsp").forward(request, response);
                }
                
            } catch (NumberFormatException e) {
                System.out.println("Error parsing IDs in SendMessageServlet: " + e.getMessage());
                response.sendRedirect("error.jsp");
            }
        } else {
            response.sendRedirect("class_qa.jsp?classId=" + classIdStr); 
        }
    }
}