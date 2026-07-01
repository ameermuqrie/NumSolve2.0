package model;

import java.sql.Date;

public class Quiz {
    private int quizId;
    private String quizTitle;
    private String quizDescription;
    private String visibility;
    private String timeLimit; // e.g., "30" for 30 minutes
    private String totalMarks;
    private String status;
    private Date createdDate;
    private int userId; // Educator who created it
    private Integer classId; // Use Integer instead of int so it can be null for Public quizzes
    private String quizType; // "Public" or "Private"
    private int questionCount; 
    
    // NEW: Variable to store the quiz cover image path
    private String photoPath;

    // Constructors
    public Quiz() {}

    // Getters and Setters
    public int getQuizId() { return quizId; }
    public void setQuizId(int quizId) { this.quizId = quizId; }

    public String getQuizTitle() { return quizTitle; }
    public void setQuizTitle(String quizTitle) { this.quizTitle = quizTitle; }

    public String getQuizDescription() { return quizDescription; }
    public void setQuizDescription(String quizDescription) { this.quizDescription = quizDescription; }

    public String getVisibility() { return visibility; }
    public void setVisibility(String visibility) { this.visibility = visibility; }

    public String getTimeLimit() { return timeLimit; }
    public void setTimeLimit(String timeLimit) { this.timeLimit = timeLimit; }

    public String getTotalMarks() { return totalMarks; }
    public void setTotalMarks(String totalMarks) { this.totalMarks = totalMarks; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Date getCreatedDate() { return createdDate; }
    public void setCreatedDate(Date createdDate) { this.createdDate = createdDate; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public Integer getClassId() { return classId; }
    public void setClassId(Integer classId) { this.classId = classId; }

    public String getQuizType() { return quizType; }
    public void setQuizType(String quizType) { this.quizType = quizType; }
    
    public int getQuestionCount() { return questionCount; }
    public void setQuestionCount(int questionCount) { this.questionCount = questionCount; }

    // NEW: Getters and Setters for photoPath
    public String getPhotoPath() { return photoPath; }
    public void setPhotoPath(String photoPath) { this.photoPath = photoPath; }
}