package controller;

import dao.LearningMaterialDAO;
import dao.ClassDAO;
import model.LearningMaterial;
import model.User;
import model.LogManager;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import java.io.*;
import java.nio.file.Paths;

@WebServlet("/uploadMaterial")
@MultipartConfig(fileSizeThreshold = 1024*1024, maxFileSize = 1024*1024*100) // 100MB max
public class UploadMaterialServlet extends HttpServlet {
    
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException, ServletException {
        HttpSession session = req.getSession();
        User u = (User) session.getAttribute("user");
        
        // 1. Strict Role Validation
        if (u == null || !("R002".equals(u.getRoleId()) || "R001".equals(u.getRoleId()))) { 
            res.sendRedirect("login.jsp"); 
            return; 
        }

        // 2. Safe Context Parameter Parsing
        String classIdStr = req.getParameter("classId");
        Integer classId = null;
        try {
            if (classIdStr != null && !classIdStr.trim().isEmpty() && !classIdStr.equals("0")) {
                classId = Integer.parseInt(classIdStr);
            }
        } catch (NumberFormatException e) {
            res.sendRedirect("materials.jsp?error=Invalid_Classroom_Context");
            return;
        }

        // 3. Security Check: Verify Teacher teaches this class context (Admins bypass)
        if (classId != null && "R002".equals(u.getRoleId())) {
            ClassDAO classroomDao = new ClassDAO();
            boolean isAuthorizedTeacher = classroomDao.isTeacherOfClass(u.getUserId(), classId);
            if (!isAuthorizedTeacher) {
                System.out.println("SECURITY ALERT: Teacher " + u.getUserId() + " tried to upload to unauthorized Class " + classId);
                res.sendRedirect("dashboard/teacher.jsp?error=Unauthorized_Class_Access");
                return;
            }
        }

        // --- Persistent Dual Storage Framework ---
        String tempAppPath = getServletContext().getRealPath("");
        String permanentAppPath = "C:\\Users\\Asus\\OneDrive\\Documents\\NetBeansProjects\\NumSolve20\\web"; 
        
        String fileName = "";
        String photoName = null;
        Part filePart = req.getPart("file");
        Part photoPart = req.getPart("photo");
        
        if (filePart != null && filePart.getSize() > 0) {
            fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
        }
        if (photoPart != null && photoPart.getSize() > 0) {
            photoName = "thumb_" + System.currentTimeMillis() + "_" + Paths.get(photoPart.getSubmittedFileName()).getFileName().toString();
        }
        
        // --- Process and Save Main Material File Safely ---
        try {
            if (filePart != null && filePart.getSize() > 0) {
                File permMatFolder = new File(permanentAppPath + File.separator + "materials");
                permMatFolder.mkdirs();
                File permFile = new File(permMatFolder, fileName);
                
                // Read from multi-part stream and save permanently
                try (InputStream input = filePart.getInputStream();
                     OutputStream output = new FileOutputStream(permFile)) {
                    byte[] buffer = new byte[8192];
                    int length;
                    while ((length = input.read(buffer)) > 0) {
                        output.write(buffer, 0, length);
                    }
                }
                
                // Copy over to the runtime temporary deployment folder 
                if (tempAppPath != null) {
                    File tempMatFolder = new File(tempAppPath + File.separator + "materials");
                    tempMatFolder.mkdirs();
                    File tempFile = new File(tempMatFolder, fileName);
                    java.nio.file.Files.copy(permFile.toPath(), tempFile.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                }
            }
        } catch (Exception e) {
            System.out.println("Error saving main file to absolute path: " + e.getMessage());
            // Fallback emergency write if absolute path fails
            try {
                if (tempAppPath != null && filePart != null && filePart.getSize() > 0) {
                    filePart.write(tempAppPath + File.separator + "materials" + File.separator + fileName);
                }
            } catch (Exception ex) { ex.printStackTrace(); }
        }

        // --- Process and Save Thumbnail/Photo Safely ---
        try {
            if (photoPart != null && photoPart.getSize() > 0 && photoName != null) {
                File permPhotoFolder = new File(permanentAppPath + File.separator + "material_photos");
                permPhotoFolder.mkdirs();
                File permPhotoFile = new File(permPhotoFolder, photoName);
                
                // Read from multi-part stream and save permanently
                try (InputStream input = photoPart.getInputStream();
                     OutputStream output = new FileOutputStream(permPhotoFile)) {
                    byte[] buffer = new byte[8192];
                    int length;
                    while ((length = input.read(buffer)) > 0) {
                        output.write(buffer, 0, length);
                    }
                }
                
                // Copy over to the runtime temporary deployment folder
                if (tempAppPath != null) {
                    File tempPhotoFolder = new File(tempAppPath + File.separator + "material_photos");
                    tempPhotoFolder.mkdirs();
                    File tempPhotoFile = new File(tempPhotoFolder, photoName);
                    java.nio.file.Files.copy(permPhotoFile.toPath(), tempPhotoFile.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                }
            }
        } catch (Exception e) {
            System.out.println("Error saving thumbnail to absolute path: " + e.getMessage());
            // Fallback emergency write if absolute path fails
            try {
                if (tempAppPath != null && photoPart != null && photoPart.getSize() > 0 && photoName != null) {
                    photoPart.write(tempAppPath + File.separator + "material_photos" + File.separator + photoName);
                }
            } catch (Exception ex) { ex.printStackTrace(); }
        }

        // Assemble Model Safely
        LearningMaterial m = new LearningMaterial();
        m.setTopic(req.getParameter("topic"));
        
        String matType = req.getParameter("materialType");
        m.setMaterialType(matType != null ? matType : "Document");
        m.setDescription(req.getParameter("description"));
        m.setUserId(u.getUserId());
        m.setClassId(classId); 

        m.setFilePath("materials/" + fileName);
        m.setFileName(fileName);
        m.setFileSize(filePart != null ? (int)filePart.getSize() : 0); 
        
        if (photoName != null) {
            m.setPhotoPath("material_photos/" + photoName);
        }

        new LearningMaterialDAO().upload(m);
        
        // --- LOGGING: Material Upload ---
        String logPath = getServletContext().getRealPath("/WEB-INF");
        String roleName = u.getRoleId().equals("R001") ? "Admin" : "Educator";
        LogManager.logActivity(logPath, u.getUsername(), "Uploaded a new learning material: " + m.getTopic(), roleName);
        
        // Dynamic Redirection
        String sourcePage = req.getParameter("sourcePage");
        if ("view_class".equals(sourcePage) && classId != null) {
            res.sendRedirect("view_class.jsp?id=" + classId + "&tab=materials&status=uploaded");
        } else if (classId != null) {
            res.sendRedirect("materials.jsp?classId=" + classId + "&status=uploaded");
        } else {
            res.sendRedirect("materials.jsp?status=uploaded");
        }
    }
}