package controller;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;

@WebServlet("/FileHandler")
public class FileHandlerServlet extends HttpServlet {
    
    // IMPORTANT: Replace 'YOUR_USERNAME' with your actual Cursor login/matric account identifier
    private static final String BASE_UPLOAD_DIR = "/home/s72433/numsolve_data";

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Accepts database stored format parameters directly: path=materials/filename.pdf
        String relativePath = request.getParameter("path");
        
        if (relativePath == null || relativePath.isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing file path parameter.");
            return;
        }

        // Directory Traversal Security Guard against malicious string injections
        if (relativePath.contains("..")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid file path access request.");
            return;
        }

        File file = new File(BASE_UPLOAD_DIR, relativePath);

        if (!file.exists() || file.isDirectory()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "File not found on server.");
            return;
        }

        // Automatically assign correct content-type header context (PDF, JPEG, PNG, etc.)
        String mimeType = getServletContext().getMimeType(file.getName());
        if (mimeType == null) {
            mimeType = "application/octet-stream";
        }
        
        response.setContentType(mimeType);
        response.setContentLengthLong(file.length());
        
        // "inline" allows browsers to display images/PDF documents natively instead of forcing download prompts
        response.setHeader("Content-Disposition", "inline; filename=\"" + file.getName() + "\"");

        // Stream raw byte chunks smoothly to user
        try (FileInputStream inStream = new FileInputStream(file);
             OutputStream outStream = response.getOutputStream()) {
            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = inStream.read(buffer)) != -1) {
                outStream.write(buffer, 0, bytesRead);
            }
        }
    }
}