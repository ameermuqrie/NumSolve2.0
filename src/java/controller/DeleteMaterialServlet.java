package controller;

import dao.LearningMaterialDAO;
import model.LearningMaterial;
import model.User;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/deleteMaterial")
public class DeleteMaterialServlet extends HttpServlet {
    
    // --- Added doPost to handle form submissions (Fixes the 405 Error) ---
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {
        processRequest(req, res);
    }

    // --- Keeps doGet for legacy links ---
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        processRequest(req, res);
    }

    // --- Unified Logic ---
    private void processRequest(HttpServletRequest req, HttpServletResponse res) throws IOException {
        User u = (User) req.getSession().getAttribute("user");
        if (u == null) { 
            res.sendRedirect("login.jsp"); 
            return; 
        }

        String idStr = req.getParameter("id");
        String sourcePage = req.getParameter("sourcePage"); // Retain user view persistence
        
        if (idStr != null) {
            try {
                int id = Integer.parseInt(idStr);
                LearningMaterialDAO dao = new LearningMaterialDAO();
                LearningMaterial m = dao.getById(id);
                
                // Security Check: Is it an Admin OR the Educator who owns the file?
                if (m != null && ("R001".equals(u.getRoleId()) || ("R002".equals(u.getRoleId()) && m.getUserId() == u.getUserId()))) {
                    Integer classId = m.getClassId();
                    dao.delete(id); // Execute Deletion
                    
                    // 1. Admin Redirect
                    if ("R001".equals(u.getRoleId()) && sourcePage == null) {
                        res.sendRedirect("admin/admin_materials.jsp?status=deleted");
                        return;
                    }

                    // 2. Educator / Standard Redirect
                    if ("view_class".equals(sourcePage) && classId != null) {
                        res.sendRedirect("view_class.jsp?id=" + classId + "&tab=materials&status=deleted");
                    } else if (classId != null && classId > 0) {
                        res.sendRedirect("materials.jsp?classId=" + classId + "&status=deleted");
                    } else {
                        res.sendRedirect("materials.jsp?status=deleted");
                    }
                    return;
                }
            } catch (Exception e) { 
                e.printStackTrace(); 
            }
        }
        
        // Error Fallback Redirection
        if ("R001".equals(u.getRoleId())) {
            res.sendRedirect("admin/admin_materials.jsp?status=error");
        } else {
            res.sendRedirect("materials.jsp?status=error");
        }
    }
}