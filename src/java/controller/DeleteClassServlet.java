package controller;

import dao.ClassDAO;
import model.Classroom;
import model.User;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/deleteClass")
public class DeleteClassServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Rigorous Security & Role Check
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        
        if (u == null || !"R002".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String classIdStr = request.getParameter("classId");
        if (classIdStr != null && !classIdStr.isEmpty()) {
            try {
                int classId = Integer.parseInt(classIdStr);
                ClassDAO dao = new ClassDAO();
                
                // 2. Class Ownership Check: Verify this class belongs to the logged-in educator
                Classroom targetClass = dao.getClassById(classId);
                if (targetClass == null || targetClass.getUserId() != u.getUserId()) {
                    // Unauthorized access attempt - send to error state or security log
                    response.sendRedirect("manage_classes.jsp?status=error");
                    return;
                }
                
                // 3. Proceed with deletion now that it's safe
                boolean isDeleted = dao.deleteClass(classId); 
                
                if (isDeleted) {
                    response.sendRedirect("manage_classes.jsp?status=deleted");
                } else {
                    response.sendRedirect("manage_classes.jsp?status=error");
                }
                
            } catch (NumberFormatException e) {
                response.sendRedirect("manage_classes.jsp?status=error");
            }
        } else {
            response.sendRedirect("manage_classes.jsp?status=error");
        }
    }
}