package model;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class LogManager {
    
    // Saves logs to a secure text file inside your server's WEB-INF directory
    public static void logActivity(String logDirPath, String username, String activityDetails, String role) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        
        // Using || as a delimiter so the logs.jsp page can split the data easily
        String logLine = timestamp + "||" + username + "||" + role + "||" + activityDetails;
        
        try {
            File logDir = new File(logDirPath);
            if (!logDir.exists()) {
                logDir.mkdirs(); 
            }
            
            File logFile = new File(logDir, "system_logs.txt");
            try (BufferedWriter writer = new BufferedWriter(new FileWriter(logFile, true))) {
                writer.write(logLine);
                writer.newLine();
            }
        } catch (IOException e) {
            System.out.println("Failed to write to log file: " + e.getMessage());
        }
    }
}