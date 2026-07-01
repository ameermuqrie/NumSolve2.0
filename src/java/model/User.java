package model;

import java.sql.Date;

public class User {

    private int userId;
    private String username;
    private String email;
    private String password;
    private String roleId;
    private String fullName;
    
    // NEW FIELDS FOR PROFILE
    private String phone;
    private String location;
    private String department;
    private String bio;
    private Date memberSince;
    private String photoPath;

    // --- GETTERS AND SETTERS ---

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getRoleId() { return roleId; }
    public void setRoleId(String roleId) { this.roleId = roleId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    // --- NEW GETTERS AND SETTERS ---

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }

    public Date getMemberSince() { return memberSince; }
    public void setMemberSince(Date memberSince) { this.memberSince = memberSince; }

    public String getPhotoPath() { return photoPath; }
    public void setPhotoPath(String photoPath) { this.photoPath = photoPath; }

}