package model;

import java.sql.Timestamp;

public class DirectMessage {
    private int messageId;
    private int classId;
    private int senderId;
    private int receiverId;
    private String messageBody;
    private Timestamp sentAt;

    // Constructors
    public DirectMessage() {}

    public DirectMessage(int classId, int senderId, int receiverId, String messageBody) {
        this.classId = classId;
        this.senderId = senderId;
        this.receiverId = receiverId;
        this.messageBody = messageBody;
    }

    // Getters and Setters
    public int getMessageId() { return messageId; }
    public void setMessageId(int messageId) { this.messageId = messageId; }

    public int getClassId() { return classId; }
    public void setClassId(int classId) { this.classId = classId; }

    public int getSenderId() { return senderId; }
    public void setSenderId(int senderId) { this.senderId = senderId; }

    public int getReceiverId() { return receiverId; }
    public void setReceiverId(int receiverId) { this.receiverId = receiverId; }

    public String getMessageBody() { return messageBody; }
    public void setMessageBody(String messageBody) { this.messageBody = messageBody; }

    public Timestamp getSentAt() { return sentAt; }
    public void setSentAt(Timestamp sentAt) { this.sentAt = sentAt; }
}