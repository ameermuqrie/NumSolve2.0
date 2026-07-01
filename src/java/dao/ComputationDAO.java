package dao;

import model.Computation;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ComputationDAO {

    // --- SECURITY UTILITY: Prevent XSS (Cross-Site Scripting) ---
    private String sanitizeHTML(String input) {
        if (input == null) return null;
        // Replaces dangerous characters with safe HTML entities
        return input.replaceAll("<", "&lt;")
                    .replaceAll(">", "&gt;")
                    .replaceAll("\"", "&quot;")
                    .replaceAll("'", "&#x27;")
                    .replaceAll("&", "&amp;");
    }

    // --- 1. SAVE NEW COMPUTATION ---
    public boolean addComputation(Computation comp) {
        String sql = "INSERT INTO computation (user_id, method_id, input_data, result, errorValue, iteration, title, description, computation_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, curdate())";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, comp.getUserId());
            ps.setString(2, comp.getMethodId());
            
            // Apply XSS Sanitization to user inputs before saving
            ps.setString(3, sanitizeHTML(comp.getInputData()));
            ps.setString(4, sanitizeHTML(comp.getResult()));
            ps.setString(5, sanitizeHTML(comp.getErrorValue()));
            ps.setString(6, sanitizeHTML(comp.getIteration()));
            ps.setString(7, sanitizeHTML(comp.getTitle()));
            ps.setString(8, sanitizeHTML(comp.getDescription()));
            
            int rowsAffected = ps.executeUpdate();
            return rowsAffected > 0;
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // --- 2. GET COMPUTATION HISTORY FOR A USER ---
    public List<Computation> getComputationsByUser(int userId) {
        List<Computation> list = new ArrayList<>();
        // Fetch ordered by the newest computations first
        String sql = "SELECT * FROM computation WHERE user_id = ? ORDER BY computation_date DESC, computation_id DESC";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Computation comp = new Computation();
                comp.setComputationId(rs.getInt("computation_id"));
                comp.setUserId(rs.getInt("user_id"));
                comp.setMethodId(rs.getString("method_id"));
                comp.setInputData(rs.getString("input_data"));
                comp.setResult(rs.getString("result"));
                comp.setComputationDate(rs.getDate("computation_date"));
                comp.setErrorValue(rs.getString("errorValue"));
                comp.setIteration(rs.getString("iteration"));
                comp.setGraphType(rs.getString("graph_type"));
                comp.setTitle(rs.getString("title"));
                comp.setDescription(rs.getString("description"));
                
                list.add(comp);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // --- 3. DELETE A COMPUTATION ---
    public boolean deleteComputation(int computationId, int userId) {
        // We require userId to ensure a student can only delete THEIR OWN records
        String sql = "DELETE FROM computation WHERE computation_id = ? AND user_id = ?";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, computationId);
            ps.setInt(2, userId);
            
            int rowsAffected = ps.executeUpdate();
            return rowsAffected > 0;
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // --- 4. GET SINGLE COMPUTATION BY ID ---
    public Computation getComputationById(int computationId, int userId) {
        Computation comp = null;
        // Require user_id so students cannot view other people's data by guessing the ID
        String sql = "SELECT * FROM computation WHERE computation_id = ? AND user_id = ?";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, computationId);
            ps.setInt(2, userId);
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                comp = new Computation();
                comp.setComputationId(rs.getInt("computation_id"));
                comp.setUserId(rs.getInt("user_id"));
                comp.setMethodId(rs.getString("method_id"));
                comp.setInputData(rs.getString("input_data"));
                comp.setResult(rs.getString("result"));
                comp.setComputationDate(rs.getDate("computation_date"));
                comp.setErrorValue(rs.getString("errorValue"));
                comp.setIteration(rs.getString("iteration"));
                comp.setGraphType(rs.getString("graph_type"));
                comp.setTitle(rs.getString("title"));
                comp.setDescription(rs.getString("description"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return comp; 
    }

    // --- 5. UPDATE EXISTING COMPUTATION ---
    public boolean updateComputation(Computation comp) {
        // Updates the record matching both computation_id and user_id
        String sql = "UPDATE computation SET method_id = ?, input_data = ?, result = ?, errorValue = ?, iteration = ?, title = ?, description = ?, computation_date = curdate() WHERE computation_id = ? AND user_id = ?";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setString(1, comp.getMethodId());
            ps.setString(2, sanitizeHTML(comp.getInputData()));
            ps.setString(3, sanitizeHTML(comp.getResult()));
            ps.setString(4, sanitizeHTML(comp.getErrorValue()));
            ps.setString(5, sanitizeHTML(comp.getIteration()));
            ps.setString(6, sanitizeHTML(comp.getTitle()));
            ps.setString(7, sanitizeHTML(comp.getDescription()));
            
            // These match the WHERE clause
            ps.setInt(8, comp.getComputationId()); 
            ps.setInt(9, comp.getUserId()); 
            
            int rowsAffected = ps.executeUpdate();
            return rowsAffected > 0;
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}