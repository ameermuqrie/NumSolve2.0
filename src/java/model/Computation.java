package model;

import java.sql.Date;

public class Computation {
    private int computationId;
    private int userId;
    private String methodId;
    private String inputData;
    private String result;
    private Date computationDate;
    private String errorValue;
    private String iteration;
    private String graphType;
    private String title;
    private String description;

    // Empty Constructor
    public Computation() {}

    // Constructor for creating a NEW computation
    public Computation(int userId, String methodId, String inputData, String result, String errorValue, String iteration, String title, String description) {
        this.userId = userId;
        this.methodId = methodId;
        this.inputData = inputData;
        this.result = result;
        this.errorValue = errorValue;
        this.iteration = iteration;
        this.title = title;
        this.description = description;
    }

    // --- Existing Getters and Setters ---
    public int getComputationId() { return computationId; }
    public void setComputationId(int computationId) { this.computationId = computationId; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getMethodId() { return methodId; }
    public void setMethodId(String methodId) { this.methodId = methodId; }

    public String getInputData() { return inputData; }
    public void setInputData(String inputData) { this.inputData = inputData; }

    public String getResult() { return result; }
    public void setResult(String result) { this.result = result; }

    public Date getComputationDate() { return computationDate; }
    public void setComputationDate(Date computationDate) { this.computationDate = computationDate; }

    public String getErrorValue() { return errorValue; }
    public void setErrorValue(String errorValue) { this.errorValue = errorValue; }

    public String getIteration() { return iteration; }
    public void setIteration(String iteration) { this.iteration = iteration; }

    public String getGraphType() { return graphType; }
    public void setGraphType(String graphType) { this.graphType = graphType; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    // --- NEW HELPER METHODS FOR DISPLAY ---

    // Automatically cleans up HTML entities and handles empty titles
    public String getDisplayTitle() {
        if (this.title == null || this.title.trim().isEmpty()) {
            return "Untitled Analysis";
        }
        return this.title.replace("&#x27;", "'")
                         .replace("&amp;#x27;", "'")
                         .replace("&quot;", "\"")
                         .replace("&amp;", "&")
                         .replace("&lt;", "<")
                         .replace("&gt;", ">");
    }

    // Do the same for input data so your math equations display cleanly!
    public String getDisplayInputData() {
        if (this.inputData == null || this.inputData.trim().isEmpty()) {
            return "N/A";
        }
        return this.inputData.replace("&#x27;", "'")
                             .replace("&amp;#x27;", "'")
                             .replace("&quot;", "\"")
                             .replace("&amp;", "&")
                             .replace("&lt;", "<")
                             .replace("&gt;", ">");
    }
}