<%@ page import="java.sql.*, java.io.*, dao.DBConnection" %>
<%
    // Prevent caching so the check is always fresh
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setContentType("text/plain");
    
    String username = request.getParameter("username");
    String roleName = "none";
    
    if (username != null && !username.trim().isEmpty()) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            // Using your central DBConnection class!
            conn = DBConnection.getConnection();
            
            if (conn != null) {
                // Query joining users and role tables
                String sql = "SELECT r.role_name FROM users u JOIN role r ON u.role_id = r.role_id WHERE u.username = ?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, username);
                
                rs = ps.executeQuery();
                
                if (rs.next()) {
                    roleName = rs.getString("role_name").toLowerCase();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch(SQLException e) {}
            if (ps != null) try { ps.close(); } catch(SQLException e) {}
            if (conn != null) try { conn.close(); } catch(SQLException e) {}
        }
    }
    
    // Send the role back to the frontend
    out.print(roleName);
%>