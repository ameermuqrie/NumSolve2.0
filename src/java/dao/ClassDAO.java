package dao;

import model.Classroom;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import model.User;

public class ClassDAO {

    // --- 1. UPGRADED: GENERATE GUARANTEED UNIQUE CLASS CODE ---
    private String generateUniqueClassCode(Connection con) throws SQLException {
        String code = "";
        boolean isUnique = false;
        String checkSql = "SELECT class_id FROM class WHERE class_code = ?";
        
        try (PreparedStatement ps = con.prepareStatement(checkSql)) {
            do {
                // Generate the 6-character code
                code = UUID.randomUUID().toString().substring(0, 6).toUpperCase();
                ps.setString(1, code);
                
                // Check if it already exists in the database
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        isUnique = true; // It's unique! Break the loop.
                    }
                }
            } while (!isUnique);
        }
        return code;
    }

    // --- 2. UPGRADED: CREATE A NEW CLASS ---
    public boolean createClass(Classroom classroom) {
        // We insert the data into your 'class' table
        String sql = "INSERT INTO class (class_name, class_code, class_description, user_id, created_date) VALUES (?, ?, ?, ?, curdate())";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setString(1, classroom.getClassName());
            ps.setString(2, generateUniqueClassCode(con)); // Call safe method with active connection
            ps.setString(3, classroom.getClassDescription());
            ps.setInt(4, classroom.getUserId());
            
            int rowsAffected = ps.executeUpdate();
            return rowsAffected > 0;
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // --- 3. GET CLASSES BY EDUCATOR ---
    public List<Classroom> getClassesByEducator(int educatorId) {
        List<Classroom> list = new ArrayList<>();
        String sql = "SELECT * FROM class WHERE user_id = ? ORDER BY created_date DESC, class_id DESC";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, educatorId);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Classroom c = new Classroom();
                c.setClassId(rs.getInt("class_id"));
                c.setClassName(rs.getString("class_name"));
                c.setClassCode(rs.getString("class_code"));
                c.setClassDescription(rs.getString("class_description"));
                c.setUserId(rs.getInt("user_id"));
                c.setCreatedDate(rs.getDate("created_date"));
                
                list.add(c);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
    
    // --- 4. GET CLASS BY CODE (For Students Joining) ---
    public Classroom getClassByCode(String classCode) {
        String sql = "SELECT * FROM class WHERE class_code = ?";
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, classCode);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                Classroom c = new Classroom();
                c.setClassId(rs.getInt("class_id"));
                c.setClassName(rs.getString("class_name"));
                c.setClassCode(rs.getString("class_code"));
                c.setUserId(rs.getInt("user_id"));
                return c;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null; // Return null if the code is invalid
    }

    // --- 5. ENROLL STUDENT INTO CLASS ---
    public boolean enrollStudent(int classId, int userId) {
        // First, check if they are already enrolled to prevent duplicates
        String checkSql = "SELECT * FROM class_enrollment WHERE class_id = ? AND user_id = ?";
        String insertSql = "INSERT INTO class_enrollment (class_id, user_id, enroll_date) VALUES (?, ?, curdate())";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement checkPs = con.prepareStatement(checkSql);
             PreparedStatement insertPs = con.prepareStatement(insertSql)) {
            
            checkPs.setInt(1, classId);
            checkPs.setInt(2, userId);
            ResultSet rs = checkPs.executeQuery();
            
            if (rs.next()) {
                return false; // Already enrolled!
            }
            
            insertPs.setInt(1, classId);
            insertPs.setInt(2, userId);
            int rows = insertPs.executeUpdate();
            return rows > 0;
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // --- 6. GET CLASSES ENROLLED BY STUDENT ---
    public List<Classroom> getClassesByStudent(int studentId) {
        List<Classroom> list = new ArrayList<>();
        // Join the class table with the enrollment table
        String sql = "SELECT c.* FROM class c INNER JOIN class_enrollment ce ON c.class_id = ce.class_id WHERE ce.user_id = ? ORDER BY ce.enroll_date DESC";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, studentId);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                Classroom c = new Classroom();
                c.setClassId(rs.getInt("class_id"));
                c.setClassName(rs.getString("class_name"));
                c.setClassCode(rs.getString("class_code"));
                c.setClassDescription(rs.getString("class_description"));
                c.setUserId(rs.getInt("user_id")); // This is the Educator's ID
                c.setCreatedDate(rs.getDate("created_date"));
                
                list.add(c);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
    // --- 7. GET CLASS BY ID ---
    public Classroom getClassById(int classId) {
        String sql = "SELECT * FROM class WHERE class_id = ?";
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, classId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                Classroom c = new Classroom();
                c.setClassId(rs.getInt("class_id"));
                c.setClassName(rs.getString("class_name"));
                c.setClassCode(rs.getString("class_code"));
                c.setClassDescription(rs.getString("class_description"));
                c.setUserId(rs.getInt("user_id"));
                c.setCreatedDate(rs.getDate("created_date"));
                return c;
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    // --- 8. UPDATE CLASS (Edit Feature) ---
    public boolean updateClass(Classroom c) {
        String sql = "UPDATE class SET class_name = ?, class_description = ? WHERE class_id = ?";
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, c.getClassName());
            ps.setString(2, c.getClassDescription());
            ps.setInt(3, c.getClassId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // --- 9. GET STUDENTS IN CLASS (The Roster) ---
    public List<User> getStudentsByClass(int classId) {
        List<User> list = new ArrayList<>();
        // INNER JOIN to get the student's name and email alongside their enrollment date
        String sql = "SELECT u.user_id, u.full_name, u.email, ce.enroll_date " +
                     "FROM users u INNER JOIN class_enrollment ce ON u.user_id = ce.user_id " +
                     "WHERE ce.class_id = ? ORDER BY ce.enroll_date DESC";
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, classId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                User u = new User();
                u.setUserId(rs.getInt("user_id"));
                u.setFullName(rs.getString("full_name"));
                u.setEmail(rs.getString("email"));
                // We will temporarily use the MemberSince field to hold the Enroll Date for the UI
                u.setMemberSince(rs.getDate("enroll_date")); 
                list.add(u);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // --- 10. REMOVE STUDENT FROM CLASS ---
    public boolean removeStudentFromClass(int classId, int studentId) {
        String sql = "DELETE FROM class_enrollment WHERE class_id = ? AND user_id = ?";
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, classId);
            ps.setInt(2, studentId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
    // --- 11. CHECK IF STUDENT IS ENROLLED (Security Check) ---
    public boolean isStudentEnrolled(int classId, int studentId) {
        String sql = "SELECT * FROM class_enrollment WHERE class_id = ? AND user_id = ?";
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, classId);
            ps.setInt(2, studentId);
            ResultSet rs = ps.executeQuery();
            return rs.next(); // Returns true if they are in the class
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
    // --- 12. UPGRADED: DELETE A CLASS WITH TRANSACTION CONTROL ---
    public boolean deleteClass(int classId) {
        String deleteEnrollmentsSql = "DELETE FROM class_enrollment WHERE class_id = ?";
        String deleteClassSql = "DELETE FROM class WHERE class_id = ?";
        
        Connection con = null;
        PreparedStatement ps1 = null;
        PreparedStatement ps2 = null;
        
        try {
            con = DBConnection.getConnection();
            // Turn off auto-commit to manage an atomic unit of work (Transaction)
            con.setAutoCommit(false); 
            
            // Step 1: Clean up dependent student records
            ps1 = con.prepareStatement(deleteEnrollmentsSql);
            ps1.setInt(1, classId);
            ps1.executeUpdate();
            
            // Step 2: Safely remove the main core class structure
            ps2 = con.prepareStatement(deleteClassSql);
            ps2.setInt(1, classId);
            int rowsAffected = ps2.executeUpdate();
            
            // If both statements executed smoothly without throwing, finalize the process
            con.commit();
            return rowsAffected > 0;
            
        } catch (Exception e) {
            e.printStackTrace();
            // If anything slips, wipe out the query logs and roll back data to save state
            if (con != null) {
                try {
                    con.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            return false;
        } finally {
            // Manual safe-resource teardown for non-try-with-resources patterns across standard connections
            try { if (ps1 != null) ps1.close(); } catch (Exception e) {}
            try { if (ps2 != null) ps2.close(); } catch (Exception e) {}
            try { if (con != null) { con.setAutoCommit(true); con.close(); } } catch (Exception e) {}
        }
    }
    // --- 13. CHECK IF TEACHER OWNS THE CLASS (Security Check) ---
    public boolean isTeacherOfClass(int teacherId, int classId) {
        String sql = "SELECT * FROM class WHERE user_id = ? AND class_id = ?";
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, teacherId);
            ps.setInt(2, classId);
            ResultSet rs = ps.executeQuery();
            
            return rs.next(); // Returns true if the teacher owns this specific class
            
        } catch (Exception e) { 
            e.printStackTrace(); 
            return false; 
        }
    }
}