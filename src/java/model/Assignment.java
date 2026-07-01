package model;

public class Assignment {
    private int assignmentId;
    private int classId;
    private String title;
    private String dueDate;
    private String allowedFormat;

    // Getters and Setters
    public int getAssignmentId() { return assignmentId; }
    public void setAssignmentId(int assignmentId) { this.assignmentId = assignmentId; }

    public int getClassId() { return classId; }
    public void setClassId(int classId) { this.classId = classId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDueDate() { return dueDate; }
    public void setDueDate(String dueDate) { this.dueDate = dueDate; }

    public String getAllowedFormat() { return allowedFormat; }
    public void setAllowedFormat(String allowedFormat) { this.allowedFormat = allowedFormat; }
}