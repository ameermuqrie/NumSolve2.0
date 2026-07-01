package model;

import java.util.List;

public class QuizQuestion {
    private int questionId;
    private int quizId;
    private String questionText;
    private String explanation;
    private int points;
    
    // This list makes it super easy to attach options to a question and send it to the JSP!
    private List<QuestionOption> options; 

    public QuizQuestion() {}

    // Getters and Setters
    public int getQuestionId() { return questionId; }
    public void setQuestionId(int questionId) { this.questionId = questionId; }

    public int getQuizId() { return quizId; }
    public void setQuizId(int quizId) { this.quizId = quizId; }

    public String getQuestionText() { return questionText; }
    public void setQuestionText(String questionText) { this.questionText = questionText; }

    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }

    public int getPoints() { return points; }
    public void setPoints(int points) { this.points = points; }

    public List<QuestionOption> getOptions() { return options; }
    public void setOptions(List<QuestionOption> options) { this.options = options; }
}