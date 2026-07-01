package model;

public class QuestionOption {
    private int optionId;
    private int questionId;
    private String optionText;
    private boolean isCorrect;

    public QuestionOption() {}

    // Getters and Setters
    public int getOptionId() { return optionId; }
    public void setOptionId(int optionId) { this.optionId = optionId; }

    public int getQuestionId() { return questionId; }
    public void setQuestionId(int questionId) { this.questionId = questionId; }

    public String getOptionText() { return optionText; }
    public void setOptionText(String optionText) { this.optionText = optionText; }

    public boolean isCorrect() { return isCorrect; }
    public void setCorrect(boolean isCorrect) { this.isCorrect = isCorrect; }
}