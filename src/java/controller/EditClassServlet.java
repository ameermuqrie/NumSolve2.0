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

@WebServlet("/EditClassServlet")
public class EditClassServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Core Authentication Check
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        if (u == null || !"R002".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp"); 
            return;
        }

        try {
            int classId = Integer.parseInt(request.getParameter("classId"));
            String className = request.getParameter("className");
            String classDesc = request.getParameter("classDescription");

            ClassDAO dao = new ClassDAO();
            
            // 2. Class Ownership Check
            Classroom targetClass = dao.getClassById(classId);
            if (targetClass == null || targetClass.getUserId() != u.getUserId()) {
                response.sendRedirect("manage_classes.jsp?status=error");
                return;
            }

            // 3. Execution Block
            Classroom c = new Classroom();
            c.setClassId(classId);
            c.setClassName(className);
            c.setClassDescription(classDesc);
            
            // Redirecting back to manage_classes.jsp so the alert banner triggers properly
            if (dao.updateClass(c)) {
                response.sendRedirect("manage_classes.jsp?status=edit_success");
            } else {
                response.sendRedirect("manage_classes.jsp?status=error");
            }
        } catch (NumberFormatException e) {
            response.sendRedirect("manage_classes.jsp?status=error");
        }
    }
}