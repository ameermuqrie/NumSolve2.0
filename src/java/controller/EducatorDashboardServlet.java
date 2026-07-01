package controller;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import dao.QuizDAO;
import model.Quiz;
import model.User;

@WebServlet("/educatorQuizzes")
public class EducatorDashboardServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        
        // Security check: Must be logged in as Educator (R002)
        if (u == null || !"R002".equals(u.getRoleId())) {
            response.sendRedirect("login.jsp");
            return;
        }

        QuizDAO dao = new QuizDAO();
        
        // Check if they clicked the "View Grades" button
        String action = request.getParameter("action");
        if ("viewGrades".equals(action)) {
            String quizIdParam = request.getParameter("quizId");
            
            if (quizIdParam != null && !quizIdParam.trim().isEmpty()) {
                try {
                    int quizId = Integer.parseInt(quizIdParam);
                    
                    // 1. Fetch raw data from the database
                    List<Map<String, Object>> rawResults = dao.getQuizResults(quizId);
                    
                    // 2. CRITICAL FIX: Translate the Map keys so educatorQuizzes.jsp can read them!
                    List<Map<String, Object>> formattedGrades = new ArrayList<>();
                    for (Map<String, Object> row : rawResults) {
                        Map<String, Object> formatted = new HashMap<>(row);
                        formatted.put("submitDate", row.get("date"));
                        formatted.put("totalPossible", row.get("total"));
                        formattedGrades.add(formatted);
                    }
                    
                    // 3. Bind the data to "gradeList" instead of "quizResults"
                    request.setAttribute("gradeList", formattedGrades); 
                    request.setAttribute("showModal", true); 
                } catch (NumberFormatException e) {
                    System.out.println("Warning: Invalid quizId format passed: " + quizIdParam);
                }
            }
        }

        // Fetch all quizzes from the database pool
        List<Quiz> globalQuizzes = dao.getAllQuizzes();
        
        // Determine which view (Tab) the educator wants to access
        String view = request.getParameter("view");
        String targetJsp = "/educatorQuizzes.jsp"; 
        
        if ("personal".equals(view)) {
            // Filter out quizzes created exclusively by this educator
            List<Quiz> personalQuizzes = new ArrayList<>();
            if (globalQuizzes != null) {
                for (Quiz q : globalQuizzes) {
                    if (q.getUserId() == u.getUserId()) {
                        personalQuizzes.add(q);
                    }
                }
            }
            request.setAttribute("quizList", personalQuizzes);
            targetJsp = "/educatorQuizzes.jsp"; 
        } else {
            // Public Pool view gets the entire list
            request.setAttribute("quizList", globalQuizzes);
        }
        
        request.getRequestDispatcher(targetJsp).forward(request, response);
    }
}