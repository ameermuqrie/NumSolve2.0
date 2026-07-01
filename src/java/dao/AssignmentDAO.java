package dao;

import model.Assignment;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class AssignmentDAO {

    // --- 1. CREATE ASSIGNMENT ---
    public boolean createAssignment(int classId, String title, String dueDate, String allowedFormat) {
        String sql = "INSERT INTO assignment (class_id, title, due_date, allowed_format) VALUES (?, ?, ?, ?)";
        
        try (Connection conn = DBConnection.getConnection(); 
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, classId);
            ps.setString(2, title);
            ps.setString(3, dueDate);
            ps.setString(4, allowedFormat);
            
            return ps.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // --- 2. GET ASSIGNMENTS BY CLASS ---
    public List<Assignment> getAssignmentsByClass(int classId) {
        List<Assignment> list = new ArrayList<>();
        String sql = "SELECT * FROM assignment WHERE class_id = ? ORDER BY due_date ASC";
        
        try (Connection conn = DBConnection.getConnection(); 
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, classId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Assignment a = new Assignment();
                    a.setAssignmentId(rs.getInt("assignment_id"));
                    a.setClassId(rs.getInt("class_id"));
                    a.setTitle(rs.getString("title"));
                    
                    // Format the date nicely to remove the ".0" at the end of SQL timestamps
                    String dueDate = rs.getString("due_date");
                    if (dueDate != null && dueDate.endsWith(".0")) {
                        dueDate = dueDate.substring(0, dueDate.length() - 2);
                    }
                    a.setDueDate(dueDate);
                    
                    a.setAllowedFormat(rs.getString("allowed_format"));
                    list.add(a);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
    
    // --- 3. SECURE DELETE ASSESSMENT ---
    // This query links the assignment to the class table to ensure the user requesting the delete is the actual owner.
    public boolean deleteAssessmentSecure(int assessmentId, int educatorId) {
        String sql = "DELETE a FROM assignment a JOIN class c ON a.class_id = c.class_id WHERE a.assignment_id = ? AND c.user_id = ?";
        
        try (Connection conn = DBConnection.getConnection(); 
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, assessmentId);
            ps.setInt(2, educatorId); // Verify educator ownership!
            
            return ps.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    // --- 4. SAVE ASSIGNMENT SUBMISSION ---
    public boolean saveSubmission(int assignmentId, int userId, String fileName) {
        // Adjust the table name 'submission' and columns if they differ in your database schema
        String sql = "INSERT INTO submission (assignment_id, user_id, file_name, submission_date) VALUES (?, ?, ?, NOW())";
        
        try (Connection conn = DBConnection.getConnection(); 
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setInt(1, assignmentId);
            ps.setInt(2, userId);
            ps.setString(3, fileName);
            
            return ps.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}