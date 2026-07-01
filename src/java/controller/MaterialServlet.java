package controller;

import dao.LearningMaterialDAO;
import model.LearningMaterial;
import model.User;

import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import java.io.*;
import java.util.List;

@WebServlet("/materials")
@MultipartConfig
public class MaterialServlet extends HttpServlet {

    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String keyword = req.getParameter("search");
        String type = req.getParameter("type");

        LearningMaterialDAO dao = new LearningMaterialDAO();
        List<LearningMaterial> list = dao.getPublicMaterials(keyword, type);

        req.setAttribute("materials", list);
        req.getRequestDispatcher("materials.jsp").forward(req, res);
    }

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        User u = (User) req.getSession().getAttribute("user");

        if ("delete".equals(req.getParameter("action"))) {
            try {
                new LearningMaterialDAO()
                    .delete(Integer.parseInt(req.getParameter("id")));
            } catch (Exception e) {}
            res.sendRedirect("materials");
            return;
        }
    }
}
