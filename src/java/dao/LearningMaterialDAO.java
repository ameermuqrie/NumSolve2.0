package dao;

import model.LearningMaterial;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class LearningMaterialDAO {

    // --- 1. GET PUBLIC MATERIALS (Platform-wide global bank) ---
    public List<LearningMaterial> getPublicMaterials(String keyword, String type) {
        List<LearningMaterial> list = new ArrayList<>();
        String sql = "SELECT m.*, u.full_name AS uploader_name FROM learning_material m " +
                     "INNER JOIN users u ON m.user_id = u.user_id " +
                     "WHERE m.class_id IS NULL";
        
        if (keyword != null && !keyword.isEmpty()) sql += " AND m.topic LIKE ?";
        if (type != null && !type.isEmpty()) sql += " AND m.material_type = ?";
        sql += " ORDER BY m.upload_date DESC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            int index = 1;
            if (keyword != null && !keyword.isEmpty()) ps.setString(index++, "%" + keyword + "%");
            if (type != null && !type.isEmpty()) ps.setString(index++, type);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRowToMaterial(rs));
            }

        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // --- 2. UPGRADED: GET CLASS MATERIALS WITH SECURITY VERIFICATION ---
    // Enforces the "Private Division" boundary: returns items only if the requester has valid access.
    public List<LearningMaterial> getClassMaterialsSecure(int classId, int userId, String roleId) {
        List<LearningMaterial> list = new ArrayList<>();
        
        // Step A: Administrative/Educator Bypass & Student Enrollment Security Check
        boolean hasAccess = false;
        if ("R001".equals(roleId)) {
            hasAccess = true; // Admin bypass
        } else {
            // Verify if user is either the owner (Educator) or an active student participant
            String securitySql = "SELECT class_id FROM class WHERE class_id = ? AND user_id = ? " +
                                 "UNION " +
                                 "SELECT class_id FROM class_enrollment WHERE class_id = ? AND user_id = ?";
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(securitySql)) {
                ps.setInt(1, classId);
                ps.setInt(2, userId);
                ps.setInt(3, classId);
                ps.setInt(4, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        hasAccess = true;
                    }
                }
            } catch (Exception e) { e.printStackTrace(); }
        }

        // Step B: Break execution if a malicious actor tries to intercept classroom materials
        if (!hasAccess) {
            return list; // Return empty array securely instead of leaking information
        }

        String sql = "SELECT m.*, u.full_name AS uploader_name FROM learning_material m " +
                     "INNER JOIN users u ON m.user_id = u.user_id " +
                     "WHERE m.class_id = ? ORDER BY m.upload_date DESC";
                     
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, classId);
            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next()) list.add(mapRowToMaterial(rs));
            }
        } catch(Exception e) { e.printStackTrace(); }
        return list;
    }

    // --- 3. GET MATERIALS BY USER ---
    public List<LearningMaterial> getMaterialsByUser(int userId) {
        List<LearningMaterial> list = new ArrayList<>();
        String sql = "SELECT m.*, c.class_name FROM learning_material m " +
                     "LEFT JOIN class c ON m.class_id = c.class_id " +
                     "WHERE m.user_id = ? ORDER BY m.upload_date DESC";
                     
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next()) list.add(mapRowToMaterial(rs));
            }
        } catch(Exception e) { e.printStackTrace(); }
        return list;
    }

    // --- 4. GET BY ID ---
    public LearningMaterial getById(int id) {
        String sql = "SELECT * FROM learning_material WHERE material_id=?";
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRowToMaterial(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    // --- 5. UPLOAD MATERIAL ---
    public void upload(LearningMaterial m) {
        String sql = "INSERT INTO learning_material(topic, material_type, user_id, class_id, file_path, description_material, file_name, file_size, photoPath_materials, upload_date) " +
                     "VALUES(?,?,?,?,?,?,?,?,?,NOW())";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, m.getTopic());
            ps.setString(2, m.getMaterialType());
            ps.setInt(3, m.getUserId());
            
            if (m.getClassId() == null || m.getClassId() == 0) {
                ps.setNull(4, java.sql.Types.INTEGER);
            } else {
                ps.setInt(4, m.getClassId());
            }
            
            ps.setString(5, m.getFilePath());
            ps.setString(6, m.getDescription());
            ps.setString(7, m.getFileName());
            ps.setLong(8, m.getFileSize());
            ps.setString(9, m.getPhotoPath());
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    // --- 6. UPDATE MATERIAL ---
    public void update(LearningMaterial m) {
        StringBuilder sql = new StringBuilder("UPDATE learning_material SET topic=?, material_type=?, description_material=?, class_id=?");
        if (m.getFilePath() != null) sql.append(", file_path=?, file_name=?, file_size=?");
        if (m.getPhotoPath() != null) sql.append(", photoPath_materials=?");
        sql.append(" WHERE material_id=?");

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {
            
            int index = 1;
            ps.setString(index++, m.getTopic());
            ps.setString(index++, m.getMaterialType());
            ps.setString(index++, m.getDescription());
            
            if (m.getClassId() == null || m.getClassId() == 0) {
                ps.setNull(index++, java.sql.Types.INTEGER);
            } else {
                ps.setInt(index++, m.getClassId());
            }
            
            if (m.getFilePath() != null) {
                ps.setString(index++, m.getFilePath());
                ps.setString(index++, m.getFileName());
                ps.setLong(index++, m.getFileSize());
            }
            if (m.getPhotoPath() != null) {
                ps.setString(index++, m.getPhotoPath());
            }
            ps.setInt(index++, m.getMaterialId());
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    // --- 7. DELETE MATERIAL ---
    public void delete(int id) {
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement("DELETE FROM learning_material WHERE material_id=?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    // --- INTERNAL DATA UTILITY LOGGER MAPPER ---
    private LearningMaterial mapRowToMaterial(ResultSet rs) throws SQLException {
        LearningMaterial m = new LearningMaterial();
        m.setMaterialId(rs.getInt("material_id"));
        m.setTopic(rs.getString("topic"));
        m.setMaterialType(rs.getString("material_type"));
        m.setDescription(rs.getString("description_material"));
        m.setFilePath(rs.getString("file_path"));
        m.setUserId(rs.getInt("user_id"));
        
        int cId = rs.getInt("class_id");
        if (!rs.wasNull()) { m.setClassId(cId); }
        
        m.setFileName(rs.getString("file_name"));
        m.setFileSize(rs.getLong("file_size"));
        m.setPhotoPath(rs.getString("photoPath_materials"));
        m.setUploadDate(rs.getDate("upload_date"));

        try { m.setUploaderName(rs.getString("uploader_name")); } catch (Exception ignored) {}
        try { m.setClassName(rs.getString("class_name")); } catch (Exception ignored) {}

        return m;
    }
    // --- ADD THIS NEW METHOD FOR ADMIN UNRESTRICTED VIEW ---
    public List<LearningMaterial> getAllMaterialsAdmin() {
        List<LearningMaterial> list = new ArrayList<>();
        String sql = "SELECT m.*, u.full_name AS uploader_name, c.class_name FROM learning_material m " +
                     "INNER JOIN users u ON m.user_id = u.user_id " +
                     "LEFT JOIN class c ON m.class_id = c.class_id " +
                     "ORDER BY m.upload_date DESC";
                     
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRowToMaterial(rs));
            }
        } catch (Exception e) { 
            e.printStackTrace(); 
        }
        return list;
    }
}