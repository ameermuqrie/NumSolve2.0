package dao;
import java.sql.*;
import java.util.*;

public class AdminDAO {

    // --- USER & SYSTEM METHODS ---
    public List<String[]> getRecentActivity() {
        List<String[]> activityList = new ArrayList<>();
        String sql = "SELECT username, membersince, role_id FROM users ORDER BY membersince DESC LIMIT 10";
        try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while(rs.next()){
                String name = rs.getString("username");
                String date = rs.getString("membersince");
                String role = rs.getString("role_id");
                String action = "New " + (role.equals("R002") ? "Educator" : "Student") + " registered";
                activityList.add(new String[]{name, action, date});
            }
        } catch(Exception e) { e.printStackTrace(); }
        return activityList;
    }

    public int getCount(String roleId) {
        String sql = (roleId == null) ? "SELECT COUNT(*) FROM users" : "SELECT COUNT(*) FROM users WHERE role_id=?";
        try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            if(roleId != null) ps.setString(1, roleId);
            ResultSet rs = ps.executeQuery();
            if(rs.next()) return rs.getInt(1);
        } catch(Exception e) { e.printStackTrace(); }
        return 0;
    }

    // --- LEARNING MATERIAL ANALYTICS (Corrected for your DB) ---

    // 1. Get Total Count
    public int getMaterialCount() {
        String sql = "SELECT COUNT(*) FROM learning_material"; 
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            if(rs.next()) return rs.getInt(1);
        } catch(Exception e) { e.printStackTrace(); }
        return 0;
    }

    // 2. Get Monthly Uploads (Line Chart)
    public int[] getMonthlyMaterials(int year) {
        int[] data = new int[12];
        String sql = "SELECT MONTH(upload_date) as m, COUNT(*) as c " + 
                     "FROM learning_material " + 
                     "WHERE YEAR(upload_date) = ? " + 
                     "GROUP BY MONTH(upload_date)";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, year);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                int month = rs.getInt("m");
                if (month >= 1 && month <= 12) {
                    data[month - 1] = rs.getInt("c");
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return data;
    }

    // 3. Get Material Types (Pie Chart)
    public Map<String, Integer> getMaterialTypeCounts() {
        Map<String, Integer> map = new HashMap<>();
        String sql = "SELECT material_type, COUNT(*) as c " + 
                     "FROM learning_material " + 
                     "GROUP BY material_type";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String type = rs.getString(1);
                if(type == null || type.isEmpty()) type = "Unknown";
                int count = rs.getInt(2);
                map.put(type, count);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return map;
    }
}