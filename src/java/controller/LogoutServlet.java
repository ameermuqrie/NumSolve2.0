package controller;

import java.io.IOException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {

    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        HttpSession session = req.getSession(false);
        if (session != null) {
            session.invalidate();
        }

        res.sendRedirect("login.jsp");
    }
}
