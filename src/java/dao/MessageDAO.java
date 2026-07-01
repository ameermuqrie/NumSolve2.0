package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import model.DirectMessage;
import model.User;

public class MessageDAO {

    public boolean sendDirectMessage(DirectMessage msg) {
        String sql = "INSERT INTO direct_messages (class_id, sender_id, receiver_id, message_body) VALUES (?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
             
            ps.setInt(1, msg.getClassId());
            ps.setInt(2, msg.getSenderId());
            ps.setInt(3, msg.getReceiverId());
            ps.setString(4, msg.getMessageBody());
            
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // === NEW METHOD TO WRITE TO GROUP CHAT TABLE ===
    public boolean sendGroupMessage(DirectMessage msg) {
        String sql = "INSERT INTO class_messages (class_id, sender_id, message_body) VALUES (?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
             
            ps.setInt(1, msg.getClassId());
            ps.setInt(2, msg.getSenderId());
            ps.setString(3, msg.getMessageBody());
            
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<DirectMessage> getConversation(int classId, int user1Id, int user2Id) {
        List<DirectMessage> chatHistory = new ArrayList<>();
        String sql = "SELECT * FROM direct_messages WHERE class_id = ? " +
                     "AND ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)) " +
                     "ORDER BY sent_at ASC";
                     
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
             
            ps.setInt(1, classId);
            ps.setInt(2, user1Id);
            ps.setInt(3, user2Id);
            ps.setInt(4, user2Id);
            ps.setInt(5, user1Id);
            
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DirectMessage msg = new DirectMessage();
                    msg.setMessageId(rs.getInt("message_id"));
                    msg.setClassId(rs.getInt("class_id"));
                    msg.setSenderId(rs.getInt("sender_id"));
                    msg.setReceiverId(rs.getInt("receiver_id"));
                    msg.setMessageBody(rs.getString("message_body"));
                    msg.setSentAt(rs.getTimestamp("sent_at"));
                    chatHistory.add(msg);
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return chatHistory;
    }
    
    public boolean hasUnreadMessages(int classId, int currentUserId, boolean isEducator) {
        try {
            ClassDAO classDao = new ClassDAO();
            
            if (isEducator) {
                List<User> students = classDao.getStudentsByClass(classId);
                if (students != null) {
                    for (User student : students) {
                        List<DirectMessage> chat = getConversation(classId, currentUserId, student.getUserId());
                        if (chat != null && !chat.isEmpty()) {
                            DirectMessage lastMsg = chat.get(chat.size() - 1);
                            if (lastMsg != null && lastMsg.getSenderId() == student.getUserId()) {
                                return true;
                            }
                        }
                    }
                }
            } else {
                model.Classroom currentClass = classDao.getClassById(classId);
                if (currentClass != null) {
                    int educatorId = currentClass.getUserId();
                    List<DirectMessage> chat = getConversation(classId, currentUserId, educatorId);
                    if (chat != null && !chat.isEmpty()) {
                        DirectMessage lastMsg = chat.get(chat.size() - 1);
                        if (lastMsg != null && lastMsg.getSenderId() == educatorId) {
                            return true;
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("Error checking unread messages: " + e.getMessage());
        }
        return false;
    }
    
    // === FIXED METHOD TO READ FROM THE CORRECT GROUP CHAT TABLE ===
    public List<DirectMessage> getGroupConversation(int classId) {
        List<DirectMessage> messages = new ArrayList<>();
        String query = "SELECT * FROM class_messages WHERE class_id = ? ORDER BY sent_at ASC";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {

            ps.setInt(1, classId);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                DirectMessage msg = new DirectMessage();
                msg.setMessageId(rs.getInt("group_message_id"));
                msg.setClassId(rs.getInt("class_id"));
                msg.setSenderId(rs.getInt("sender_id"));
                msg.setReceiverId(-1); // Hardcoded back to -1 so your view mapping logic stays functional
                msg.setMessageBody(rs.getString("message_body"));
                msg.setSentAt(rs.getTimestamp("sent_at"));
                messages.add(msg);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return messages;
    }
}