package controller;

import dao.LearningMaterialDAO;
import model.LearningMaterial;
import model.User;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import java.io.*;
import java.nio.file.Paths;

@WebServlet("/editMaterial")
@MultipartConfig(fileSizeThreshold = 1024*1024, maxFileSize = 1024*1024*100)
public class EditMaterialServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException, ServletException {
        User u = (User) req.getSession().getAttribute("user");
        if (u == null || !("R002".equals(u.getRoleId()) || "R001".equals(u.getRoleId()))) { 
            res.sendRedirect("login.jsp"); 
            return; 
        }

        String idParam = req.getParameter("materialId");
        if (idParam == null || idParam.isEmpty()) {
            idParam = req.getParameter("id");
        }
        int id = Integer.parseInt(idParam);

        LearningMaterialDAO dao = new LearningMaterialDAO();
        LearningMaterial m = dao.getById(id);
        
        if (m == null) {
            res.sendRedirect("materials.jsp?status=error");
            return;
        }

        if (req.getParameter("topic") != null) m.setTopic(req.getParameter("topic"));
        if (req.getParameter("description") != null) m.setDescription(req.getParameter("description"));
        if (req.getParameter("materialType") != null) m.setMaterialType(req.getParameter("materialType"));

        String classIdStr = req.getParameter("classId");
        if (classIdStr != null) {
            if (classIdStr.trim().isEmpty() || classIdStr.equals("0")) {
                m.setClassId(null); 
            } else {
                m.setClassId(Integer.parseInt(classIdStr));
            }
        }

        String contentType = req.getContentType();
        if (contentType != null && contentType.toLowerCase().startsWith("multipart/form-data")) {
            
            String tempAppPath = getServletContext().getRealPath("");
            String permanentAppPath = "C:\\Users\\Asus\\OneDrive\\Documents\\NetBeansProjects\\NumSolve20\\web";

            Part filePart = req.getPart("file");
            Part photoPart = req.getPart("photo");

            String newFileName = null;
            String newPhotoName = null;

            if (filePart != null && filePart.getSize() > 0) {
                newFileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            }
            if (photoPart != null && photoPart.getSize() > 0) {
                newPhotoName = "thumb_" + System.currentTimeMillis() + "_" + Paths.get(photoPart.getSubmittedFileName()).getFileName().toString();
            }

            // --- Save Edited Main Material File Safely ---
            try {
                if (newFileName != null) {
                    File permFolder = new File(permanentAppPath + File.separator + "materials");
                    permFolder.mkdirs();
                    File permFile = new File(permFolder, newFileName);
                    
                    try (InputStream input = filePart.getInputStream();
                         OutputStream output = new FileOutputStream(permFile)) {
                        byte[] buffer = new byte[8192];
                        int length;
                        while ((length = input.read(buffer)) > 0) {
                            output.write(buffer, 0, length);
                        }
                    }
                    
                    if (tempAppPath != null) {
                        File tempFolder = new File(tempAppPath + File.separator + "materials");
                        tempFolder.mkdirs();
                        File tempFile = new File(tempFolder, newFileName);
                        java.nio.file.Files.copy(permFile.toPath(), tempFile.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                    }
                }
            } catch (Exception e) {
                System.out.println("Error updating main file: " + e.getMessage());
                try {
                    if (tempAppPath != null && newFileName != null) {
                        filePart.write(tempAppPath + File.separator + "materials" + File.separator + newFileName);
                    }
                } catch (Exception ex) { ex.printStackTrace(); }
            }

            // --- Save Edited Photo Safely ---
            try {
                if (newPhotoName != null) {
                    File permFolder = new File(permanentAppPath + File.separator + "material_photos");
                    permFolder.mkdirs();
                    File permFile = new File(permFolder, newPhotoName);
                    
                    try (InputStream input = photoPart.getInputStream();
                         OutputStream output = new FileOutputStream(permFile)) {
                        byte[] buffer = new byte[8192];
                        int length;
                        while ((length = input.read(buffer)) > 0) {
                            output.write(buffer, 0, length);
                        }
                    }
                    
                    if (tempAppPath != null) {
                        File tempFolder = new File(tempAppPath + File.separator + "material_photos");
                        tempFolder.mkdirs();
                        File tempFile = new File(tempFolder, newPhotoName);
                        java.nio.file.Files.copy(permFile.toPath(), tempFile.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                    }
                }
            } catch (Exception e) {
                System.out.println("Error updating thumbnail: " + e.getMessage());
                try {
                    if (tempAppPath != null && newPhotoName != null) {
                        photoPart.write(tempAppPath + File.separator + "material_photos" + File.separator + newPhotoName);
                    }
                } catch (Exception ex) { ex.printStackTrace(); }
            }

            // Map data variations safely to the entity bean instance
            if (newFileName != null) {
                m.setFilePath("materials/" + newFileName);
                m.setFileName(newFileName);
                m.setFileSize(filePart.getSize());
            }
            if (newPhotoName != null) {
                m.setPhotoPath("material_photos/" + newPhotoName);
            }
        }

        dao.update(m);

       // Smart Adaptive Return Routing Logic
        String sourcePage = req.getParameter("sourcePage");
        
        if ("my_materials".equals(sourcePage)) {
            // Force redirect back to my_materials if the request originated there
            res.sendRedirect("my_materials.jsp?status=updated");
            
        } else if ("view_class".equals(sourcePage) && m.getClassId() != null) {
            // Redirect back to the specific class view
            res.sendRedirect("view_class.jsp?id=" + m.getClassId() + "&tab=materials&status=updated");
            
        } else if (m.getClassId() != null && m.getClassId() > 0) {
            // Fallback for private materials
            res.sendRedirect("materials.jsp?classId=" + m.getClassId() + "&status=updated");
            
        } else {
            // Fallback for public materials
            res.sendRedirect("materials.jsp?status=updated");
        }
    }
}