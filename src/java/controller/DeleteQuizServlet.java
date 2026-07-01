package controller;

import java.io.IOException;
import java.net.URLEncoder;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import dao.QuizDAO;
import model.User;

@WebServlet("/deleteQuiz") // Matches the clean URL pattern
public class DeleteQuizServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        processRequest(request, response);
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        processRequest(request, response);
    }

    protected void processRequest(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");

        String quizIdStr = request.getParameter("id");
        String classIdStr = request.getParameter("classId"); 
        String viewContext = request.getParameter("view");
        
        if (quizIdStr != null && !quizIdStr.isEmpty()) {
            int quizId = Integer.parseInt(quizIdStr);
            
            QuizDAO quizDAO = new QuizDAO();
            boolean success = quizDAO.deleteQuiz(quizId);
            
            // --- SMART ROUTING FOR ADMIN ---
            if (u != null && "R001".equals(u.getRoleId())) {
                // CORRECTED: Prepended context path for safe redirection
                response.sendRedirect(request.getContextPath() + "/admin/admin_quizzes.jsp?status=deleted");
                return;
            }
            
            // --- ROUTING FOR EDUCATOR ---
            boolean staysInPersonal = false;
            if (viewContext != null && viewContext.trim().equalsIgnoreCase("personal")) {
                staysInPersonal = true;
            }
            if (classIdStr != null && !classIdStr.trim().isEmpty() && !classIdStr.equals("0")) {
                staysInPersonal = true;
            }

            // Build the URL to redirect back to educatorQuizzes
            // CORRECTED: Formulated target URL dynamically using request.getContextPath()
            StringBuilder targetUrl = new StringBuilder(request.getContextPath() + "/educatorQuizzes?");
            
            if (staysInPersonal) {
                targetUrl.append("view=personal&");
            }
            if (classIdStr != null && !classIdStr.trim().isEmpty() && !classIdStr.equals("0")) {
                targetUrl.append("classId=").append(classIdStr).append("&");
            }
            
            String message = success ? "Mission deleted successfully!" : "Failed to delete mission.";
            String encodedMessage = URLEncoder.encode(message, "UTF-8");
            String paramLabel = success ? "msg=" : "error=";

            targetUrl.append(paramLabel).append(encodedMessage);

            response.sendRedirect(targetUrl.toString());

        } else {
            String encodedError = URLEncoder.encode("Invalid Mission ID.", "UTF-8");
            // CORRECTED: Added context path constraint here
            response.sendRedirect(request.getContextPath() + "/educatorQuizzes?error=" + encodedError);
        }
    }
}