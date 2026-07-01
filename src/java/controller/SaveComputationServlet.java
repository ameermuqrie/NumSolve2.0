package controller;

import dao.ComputationDAO;
import model.Computation;
import model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/SaveComputationServlet")
public class SaveComputationServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        // Security check
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // 1. Gather data from the hidden form in solver.jsp
        String compIdStr = request.getParameter("computationId"); // New: Grabbing the ID
        String methodId = request.getParameter("methodId");
        String inputData = request.getParameter("inputData");
        String result = request.getParameter("result");
        String iteration = request.getParameter("iteration");
        String errorValue = request.getParameter("errorValue");
        String title = request.getParameter("title");
        
        // 2. Create the Computation Object
        Computation comp = new Computation();
        comp.setUserId(user.getUserId());
        comp.setMethodId(methodId);
        comp.setInputData(inputData);
        comp.setResult(result);
        comp.setIteration(iteration);
        comp.setErrorValue(errorValue);
        comp.setTitle(title);
        comp.setDescription("Calculated via NumSolve Web Solver");

        // 3. Save to Database using the DAO
        ComputationDAO dao = new ComputationDAO();
        boolean isSaved = false;

        // --- The Check: Insert vs Update ---
        if (compIdStr != null && !compIdStr.trim().isEmpty()) {
            try {
                // If it has a valid ID, UPDATE the existing record
                int compId = Integer.parseInt(compIdStr);
                comp.setComputationId(compId);
                isSaved = dao.updateComputation(comp);
            } catch (NumberFormatException e) {
                // Failsafe: if the ID string is corrupted somehow, just save as new
                isSaved = dao.addComputation(comp);
            }
        } else {
            // If there is NO ID, INSERT a new record
            isSaved = dao.addComputation(comp);
        }

        // 4. Redirect back to history page
        if (isSaved) {
            response.sendRedirect("computations.jsp?status=success");
        } else {
            response.sendRedirect("computations.jsp?status=error");
        }
    }
}