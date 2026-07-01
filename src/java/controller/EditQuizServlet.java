package controller;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import dao.QuizDAO;
import model.Quiz;
import model.QuizQuestion;

@WebServlet("/EditQuizServlet")
public class EditQuizServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idStr = request.getParameter("id");
        String classIdStr = request.getParameter("classId"); 
        // NEW: Capture the view context (e.g., "personal")
        String viewStr = request.getParameter("view"); 
        
        if (idStr != null) {
            int quizId = Integer.parseInt(idStr);
            QuizDAO dao = new QuizDAO();
            
            // Fetch the data
            Quiz quiz = dao.getQuizById(quizId);
            List<QuizQuestion> questions = dao.getQuestionsByQuizId(quizId);
            
            if (quiz != null) {
                // Send data to the JSP
                request.setAttribute("quiz", quiz);
                request.setAttribute("questions", questions);
                
                // Pass classId down to the JSP
                if (classIdStr != null && !classIdStr.trim().isEmpty()) {
                    request.setAttribute("classId", classIdStr);
                }
                
                // Pass the view state down to the JSP (default to personal if missing)
                if (viewStr != null && !viewStr.trim().isEmpty()) {
                    request.setAttribute("viewContext", viewStr);
                } else {
                    request.setAttribute("viewContext", "personal");
                }
                
                request.getRequestDispatcher("editQuiz.jsp").forward(request, response);
                return;
            }
        }
        
        // Error routing
        if (classIdStr != null && !classIdStr.trim().isEmpty()) {
             response.sendRedirect("class_dashboard.jsp?id=" + classIdStr + "&tab=quizzes&status=error");
        } else {
             response.sendRedirect("educatorQuizzes?error=Quiz not found");
        }
    }
}