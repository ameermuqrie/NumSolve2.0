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

@WebServlet("/JoinClassServlet")
public class JoinClassServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // 1. Security Check
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        
        // Ensure user is logged in AND is a Student (R003)
        if (u == null || !"R003".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp");
            return;
        }

        // 2. Get the Code from the Form
        String classCode = request.getParameter("classCode");

        // 3. Process the Join Request
        ClassDAO dao = new ClassDAO();
        Classroom targetClass = dao.getClassByCode(classCode);
        
        if (targetClass != null) {
            // The code is valid! Try to enroll the student.
            if (dao.enrollStudent(targetClass.getClassId(), u.getUserId())) {
                response.sendRedirect("student_classes.jsp?status=joined");
            } else {
                response.sendRedirect("student_classes.jsp?status=already_enrolled");
            }
        } else {
            // The code does not exist in the database
            response.sendRedirect("student_classes.jsp?status=invalid_code");
        }
    }
}