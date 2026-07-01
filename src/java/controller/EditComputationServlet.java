package controller; // Update if your package name is different

import dao.ComputationDAO;
import model.Computation;
import model.User;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/EditComputationServlet")
public class EditComputationServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Security Check: Ensure user is logged in
        HttpSession session = request.getSession();
        User u = (User) session.getAttribute("user");
        
        if (u == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // 2. Get computation ID from the URL (e.g., ?id=12)
        String compIdStr = request.getParameter("id");

        if (compIdStr != null && !compIdStr.trim().isEmpty()) {
            try {
                int compId = Integer.parseInt(compIdStr);
                ComputationDAO compDao = new ComputationDAO();

                // 3. Fetch record securely using the method from your DAO
                // This guarantees the user only loads their own data
                Computation comp = compDao.getComputationById(compId, u.getUserId());

                if (comp != null) {
                    // 4. Inject data into request attributes
                    request.setAttribute("loadedMethod", comp.getMethodId());
                    
                    // Use your custom getDisplayInputData() so symbols like '<' or '>' 
                    // render correctly in the calculator inputs instead of '&lt;'
                    request.setAttribute("loadedInputs", comp.getInputData());

                    // 5. Forward to your solver page
                    request.getRequestDispatcher("solver.jsp").forward(request, response);
                    return;
                }
            } catch (NumberFormatException e) {
                System.out.println("Invalid Computation ID format.");
                e.printStackTrace();
            }
        }

        // 6. If anything fails (wrong ID, record doesn't exist), send them back
        response.sendRedirect("computations.jsp");
    }
}