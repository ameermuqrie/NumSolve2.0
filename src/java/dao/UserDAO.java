package dao;

import model.User;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {

    // 1. LOGIN
    public User login(String username, String password) {
        if (username == null || password == null || password.length() < 1) return null;
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT * FROM users WHERE username=? AND password=?")) {
            ps.setString(1, username);
            ps.setString(2, password);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapUser(rs);
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    // 2. REGISTER
    public boolean register(User u) {
        if (u.getPassword() == null || u.getPassword().isEmpty()) return false;
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("INSERT INTO users(username, password, full_name, email, role_id, membersince) VALUES(?,?,?,?,?,NOW())")) {
            ps.setString(1, u.getUsername());
            ps.setString(2, u.getPassword());
            ps.setString(3, u.getFullName());
            ps.setString(4, u.getEmail());
            ps.setString(5, u.getRoleId());
            ps.executeUpdate();
            return true;
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    // 3. UPDATE PROFILE
    public boolean updateProfile(User u) {
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("UPDATE users SET full_name=?, email=?, phone=?, location=?, department=?, bio=?, photoPath=? WHERE user_id=?")) {
            ps.setString(1, u.getFullName());
            ps.setString(2, u.getEmail());
            ps.setString(3, u.getPhone());
            ps.setString(4, u.getLocation());
            ps.setString(5, u.getDepartment());
            ps.setString(6, u.getBio());
            ps.setString(7, u.getPhotoPath());
            ps.setInt(8, u.getUserId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    // 4. GET USER BY ID
    public User getUserById(int id) {
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT * FROM users WHERE user_id=?")) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapUser(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    // 5. GET ALL USERS
    public List<User> getAllUsers() {
        List<User> list = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT * FROM users ORDER BY role_id ASC, user_id ASC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapUser(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // 6. GET MONTHLY REGISTRATIONS (For Graph)
    public int[] getMonthlyRegistrations(String roleId, int year) {
        int[] data = new int[12];
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT MONTH(membersince) as m, COUNT(*) as c FROM users WHERE role_id = ? AND YEAR(membersince) = ? GROUP BY MONTH(membersince)")) {
            ps.setString(1, roleId);
            ps.setInt(2, year);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                int month = rs.getInt("m");
                if (month >= 1 && month <= 12) data[month - 1] = rs.getInt("c"); 
            }
        } catch (Exception e) { e.printStackTrace(); }
        return data;
    }

    // 7. DELETE USER (New)
    public boolean deleteUser(int userId) {
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("DELETE FROM users WHERE user_id=?")) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    private User mapUser(ResultSet rs) throws SQLException {
        User u = new User();
        u.setUserId(rs.getInt("user_id"));
        u.setUsername(rs.getString("username"));
        u.setEmail(rs.getString("email"));
        u.setPassword(rs.getString("password"));
        u.setRoleId(rs.getString("role_id"));
        u.setFullName(rs.getString("full_name"));
        u.setPhone(rs.getString("phone"));
        u.setLocation(rs.getString("location"));
        u.setDepartment(rs.getString("department"));
        u.setBio(rs.getString("bio"));
        u.setMemberSince(rs.getDate("membersince"));
        u.setPhotoPath(rs.getString("photoPath"));
        return u;
    }
}