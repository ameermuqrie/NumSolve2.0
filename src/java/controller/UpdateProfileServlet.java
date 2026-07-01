package controller;

import dao.UserDAO;
import model.User;
import javax.servlet.*;
import javax.servlet.annotation.*;
import javax.servlet.http.*;
import java.io.*;
import java.nio.file.Paths;

@WebServlet("/updateProfile")
@MultipartConfig(fileSizeThreshold = 1024*1024, maxFileSize = 1024*1024*10) // 10MB limit
public class UpdateProfileServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
        HttpSession session = req.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            res.sendRedirect("login.jsp");
            return;
        }

        // 1. GET TEXT FIELDS
        user.setFullName(req.getParameter("full_name"));
        user.setEmail(req.getParameter("email"));
        user.setPhone(req.getParameter("phone"));
        user.setLocation(req.getParameter("location"));
        user.setDepartment(req.getParameter("department"));
        user.setBio(req.getParameter("bio"));

        // 2. HANDLE PHOTO UPLOAD WITH NETBEANS HACK
        Part filePart = req.getPart("photo");
        if (filePart != null && filePart.getSize() > 0) {
            
            // Get the temporary build path
            String buildPath = getServletContext().getRealPath("");
            
            // --- NETBEANS HACK: Reroute to the permanent Source folder ---
            String savePath = buildPath;
            if (savePath.contains("build" + File.separator + "web")) {
                // Change /build/web/ to just /web/ (which NetBeans shows as Web Pages)
                savePath = savePath.replace("build" + File.separator + "web", "web");
            }
            
            // Append the target folder
            savePath = savePath + File.separator + "profile_photos";
            
            File fileDir = new File(savePath);
            if (!fileDir.exists()) fileDir.mkdirs();

            // Extract the original file extension dynamically
            String submittedFileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            String fileExt = "";
            if (submittedFileName.contains(".")) {
                fileExt = submittedFileName.substring(submittedFileName.lastIndexOf("."));
            } else {
                fileExt = ".png"; // Fallback extension
            }

            // Create a unique file name
            String fileName = "user_" + user.getUserId() + "_" + System.currentTimeMillis() + fileExt;
            
            // Save the file to the server disk inside the permanent folder
            filePart.write(savePath + File.separator + fileName);
            
            // Set path for DB (Always use forward slash for web URLs)
            user.setPhotoPath("profile_photos/" + fileName);
        }

        // 3. UPDATE DATABASE
        UserDAO dao = new UserDAO();
        boolean success = dao.updateProfile(user);

        if (success) {
            // Refresh session with new data
            User updatedUser = dao.getUserById(user.getUserId());
            session.setAttribute("user", updatedUser);
            session.setAttribute("msg", "Profile updated successfully!");
        } else {
            session.setAttribute("error", "Failed to update profile.");
        }

        res.sendRedirect("profile.jsp");
    }
}