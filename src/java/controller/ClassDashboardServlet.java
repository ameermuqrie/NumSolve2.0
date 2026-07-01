package controller;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

// Models and DAOs
import dao.ClassDAO;
import dao.LearningMaterialDAO;
import dao.QuizDAO; 
import model.Classroom;
import model.LearningMaterial;
import model.Quiz; 
import model.User;

@WebServlet("/ClassDashboardServlet")
public class ClassDashboardServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        
        // FIX: Retrieve the "user" object from session just like your JSP pages do
        User user = (User) session.getAttribute("user");
        
        // If no user object is found, then unauthorized -> redirect to login
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // Extract ID and Role dynamically from the authenticated User model instance
        int loggedUserId = user.getUserId();
        String userRole = user.getRoleId(); 

        String classIdStr = request.getParameter("classId");
        if (classIdStr == null || classIdStr.isEmpty()) {
            response.sendRedirect("error.jsp"); 
            return;
        }
        
        int classId = Integer.parseInt(classIdStr);

        try {
            // 1. GET CLASS INFO
            ClassDAO classDAO = new ClassDAO();
            Classroom currentClass = classDAO.getClassById(classId);
            request.setAttribute("classDetails", currentClass);

            // 2. GET LEARNING MATERIALS (Secured)
            LearningMaterialDAO materialDAO = new LearningMaterialDAO();
            List<LearningMaterial> materialsList = materialDAO.getClassMaterialsSecure(classId, loggedUserId, userRole);
            request.setAttribute("materialsList", materialsList);

            // 3. GET CLASS QUIZZES
            QuizDAO quizDAO = new QuizDAO();
            List<Quiz> quizzesList = quizDAO.getQuizzesByClass(classId);
            request.setAttribute("quizzesList", quizzesList);

            // 4. GET CLASS ASSIGNMENTS (Placeholder for future)
            // dao.AssignmentDAO assignmentDAO = new dao.AssignmentDAO();
            // request.setAttribute("assignmentsList", assignmentDAO.getAssignmentsByClass(classId));

            // 5. ROLE-SPECIFIC DATA (R002 = Educator, R003 = Student)
            if ("R002".equals(userRole)) {
                // Educator: Needs the roster of students enrolled in this class
                List<User> roster = classDAO.getStudentsByClass(classId);
                request.setAttribute("studentRoster", roster);
                request.setAttribute("isEducator", true);
            } else if ("R003".equals(userRole)) {
                request.setAttribute("isEducator", false);
            }

            // 6. SEND TO JSP
            request.getRequestDispatcher("class_dashboard.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("error.jsp");
        }
    }
}