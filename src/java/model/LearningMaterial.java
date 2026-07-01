package model;
import java.util.Date;

public class LearningMaterial {
    private int materialId;
    private String topic;
    private String materialType;
    private String filePath;
    private String description;
    private int userId;
    private Integer classId;     // NEW: Null = Public, Number = Private Class
    private String fileName;
    private long fileSize;
    private String photoPath; 
    private Date uploadDate;

    // Optional fields for displaying names on the frontend easily
    private String uploaderName; 
    private String className;

    // --- Getters & Setters ---
    public int getMaterialId() { return materialId; }
    public void setMaterialId(int materialId) { this.materialId = materialId; }
    
    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }
    
    public String getMaterialType() { return materialType; }
    public void setMaterialType(String materialType) { this.materialType = materialType; }
    
    public String getFilePath() { return filePath; }
    public void setFilePath(String filePath) { this.filePath = filePath; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }
    
    public Integer getClassId() { return classId; }
    public void setClassId(Integer classId) { this.classId = classId; }
    
    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }
    
    public long getFileSize() { return fileSize; }
    public void setFileSize(long fileSize) { this.fileSize = fileSize; }
    
    public String getPhotoPath() { return photoPath; }
    public void setPhotoPath(String photoPath) { this.photoPath = photoPath; }
    
    public Date getUploadDate() { return uploadDate; }
    public void setUploadDate(Date uploadDate) { this.uploadDate = uploadDate; }
    
    public String getUploaderName() { return uploaderName; }
    public void setUploaderName(String uploaderName) { this.uploaderName = uploaderName; }
    
    public String getClassName() { return className; }
    public void setClassName(String className) { this.className = className; }
}