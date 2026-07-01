package dao;

import model.*;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class QuizDAO {

    // ==========================================
    // 1. CREATE: Save a full quiz with questions & options (Transaction Secured)
    // ==========================================
    public boolean createFullQuiz(Quiz quiz, List<QuizQuestion> questions) {
        // UPDATED: Added photoPath column to the INSERT string
        String sqlQuiz = "INSERT INTO quiz (quiz_title, quiz_description, visibility, time_limit, total_marks, status, user_id, class_id, quiz_type, created_date, photoPath) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)";
        String sqlQuestion = "INSERT INTO quiz_question (quiz_id, question_text, explanation, points) VALUES (?, ?, ?, ?)";
        String sqlOption = "INSERT INTO question_option (question_id, option_text, is_correct) VALUES (?, ?, ?)";
        boolean success = false;

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false); // Start Transaction

            try (PreparedStatement psQuiz = conn.prepareStatement(sqlQuiz, Statement.RETURN_GENERATED_KEYS);
                 PreparedStatement psQuestion = conn.prepareStatement(sqlQuestion, Statement.RETURN_GENERATED_KEYS);
                 PreparedStatement psOption = conn.prepareStatement(sqlOption)) {

                // Insert Quiz
                psQuiz.setString(1, quiz.getQuizTitle());
                psQuiz.setString(2, quiz.getQuizDescription());
                psQuiz.setString(3, quiz.getVisibility());
                psQuiz.setString(4, quiz.getTimeLimit());
                psQuiz.setString(5, quiz.getTotalMarks());
                psQuiz.setString(6, quiz.getStatus());
                psQuiz.setInt(7, quiz.getUserId());
                
                if (quiz.getClassId() != null && quiz.getClassId() > 0) {
                    psQuiz.setInt(8, quiz.getClassId());
                } else {
                    psQuiz.setNull(8, java.sql.Types.INTEGER);
                }
                psQuiz.setString(9, quiz.getQuizType());
                psQuiz.setString(10, quiz.getPhotoPath()); // UPDATED: Bound photoPath to index 10
                psQuiz.executeUpdate();

                int newQuizId = 0;
                try (ResultSet rs = psQuiz.getGeneratedKeys()) {
                    if (rs.next()) {
                        newQuizId = rs.getInt(1);
                    }
                }

                // Insert Questions and Options
                for (QuizQuestion q : questions) {
                    psQuestion.setInt(1, newQuizId);
                    psQuestion.setString(2, q.getQuestionText());
                    psQuestion.setString(3, q.getExplanation());
                    psQuestion.setInt(4, q.getPoints());
                    psQuestion.executeUpdate();

                    int newQuestionId = 0;
                    try (ResultSet rsQ = psQuestion.getGeneratedKeys()) {
                        if (rsQ.next()) {
                            newQuestionId = rsQ.getInt(1);
                        }
                    }

                    for (QuestionOption opt : q.getOptions()) {
                        psOption.setInt(1, newQuestionId);
                        psOption.setString(2, opt.getOptionText());
                        psOption.setBoolean(3, opt.isCorrect());
                        psOption.addBatch();
                    }
                    psOption.executeBatch(); 
                }

                conn.commit(); // Success! Save transaction block.
                success = true;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return success;
    }

    // ==========================================
    // 2. READ: Get Quizzes created by an Educator
    // ==========================================
    public List<Quiz> getQuizzesByEducator(int userId) {
        List<Quiz> quizList = new ArrayList<>();
        String sql = "SELECT q.*, (SELECT COUNT(*) FROM quiz_question qq WHERE qq.quiz_id = q.quiz_id) AS question_count " +
                     "FROM quiz q WHERE q.user_id = ? ORDER BY q.created_date DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    quizList.add(mapRowToQuiz(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return quizList;
    }

    // ==========================================
    // 3. READ: Get ALL Quizzes (Unified Platform View)
    // ==========================================
    public List<Quiz> getAllQuizzes() {
        List<Quiz> quizList = new ArrayList<>();
        String sql = "SELECT q.*, (SELECT COUNT(*) FROM quiz_question qq WHERE qq.quiz_id = q.quiz_id) AS question_count " +
                     "FROM quiz q ORDER BY q.created_date DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                quizList.add(mapRowToQuiz(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return quizList;
    }

    // ==========================================
    // 4. DELETE: Remove a Quiz
    // ==========================================
    public boolean deleteQuiz(int quizId) {
        boolean success = false;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM quiz WHERE quiz_id = ?")) {
            ps.setInt(1, quizId);
            if (ps.executeUpdate() > 0) {
                success = true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return success;
    }

    // ==========================================
    // 5. READ: Get a single Quiz by ID
    // ==========================================
    public Quiz getQuizById(int quizId) {
        Quiz quiz = null;
        String sql = "SELECT q.*, (SELECT COUNT(*) FROM quiz_question qq WHERE qq.quiz_id = q.quiz_id) AS question_count " +
                     "FROM quiz q WHERE q.quiz_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, quizId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    quiz = mapRowToQuiz(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return quiz;
    }

    // ==========================================
    // 6. READ: Get all Questions & Options for a Quiz
    // ==========================================
    public List<QuizQuestion> getQuestionsByQuizId(int quizId) {
        List<QuizQuestion> questions = new ArrayList<>();
        String sqlQ = "SELECT * FROM quiz_question WHERE quiz_id = ?";
        String sqlOpt = "SELECT * FROM question_option WHERE question_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement psQ = conn.prepareStatement(sqlQ);
             PreparedStatement psOpt = conn.prepareStatement(sqlOpt)) {
            
            psQ.setInt(1, quizId);
            try (ResultSet rsQ = psQ.executeQuery()) {
                while (rsQ.next()) {
                    QuizQuestion q = new QuizQuestion();
                    q.setQuestionId(rsQ.getInt("question_id"));
                    q.setQuizId(rsQ.getInt("quiz_id"));
                    q.setQuestionText(rsQ.getString("question_text"));
                    q.setExplanation(rsQ.getString("explanation"));
                    q.setPoints(rsQ.getInt("points"));

                    List<QuestionOption> options = new ArrayList<>();
                    psOpt.setInt(1, q.getQuestionId());
                    try (ResultSet rsOpt = psOpt.executeQuery()) {
                        while (rsOpt.next()) {
                            QuestionOption opt = new QuestionOption();
                            opt.setOptionId(rsOpt.getInt("option_id"));
                            opt.setQuestionId(rsOpt.getInt("question_id"));
                            opt.setOptionText(rsOpt.getString("option_text"));
                            opt.setCorrect(rsOpt.getBoolean("is_correct"));
                            options.add(opt);
                        }
                    }
                    q.setOptions(options);
                    questions.add(q);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return questions;
    }

    // ==========================================
    // 7. UPDATE: Update Quiz and Rebuild Questions safely
    // ==========================================
    public boolean updateFullQuiz(Quiz quiz, List<QuizQuestion> newQuestions) {
        // UPDATED: Added photoPath=? to the update string
        String sqlQuiz = "UPDATE quiz SET quiz_title=?, quiz_description=?, visibility=?, time_limit=?, total_marks=?, status=?, class_id=?, quiz_type=?, photoPath=? WHERE quiz_id=?";
        String sqlQuestion = "INSERT INTO quiz_question (quiz_id, question_text, explanation, points) VALUES (?, ?, ?, ?)";
        String sqlOption = "INSERT INTO question_option (question_id, option_text, is_correct) VALUES (?, ?, ?)";
        boolean success = false;

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false); // Start Transaction

            // 1. Update Quiz metadata
            try (PreparedStatement psQuiz = conn.prepareStatement(sqlQuiz)) {
                psQuiz.setString(1, quiz.getQuizTitle());
                psQuiz.setString(2, quiz.getQuizDescription());
                psQuiz.setString(3, quiz.getVisibility());
                psQuiz.setString(4, quiz.getTimeLimit());
                psQuiz.setString(5, quiz.getTotalMarks());
                psQuiz.setString(6, quiz.getStatus());
                if (quiz.getClassId() != null && quiz.getClassId() > 0) {
                    psQuiz.setInt(7, quiz.getClassId());
                } else {
                    psQuiz.setNull(7, java.sql.Types.INTEGER);
                }
                psQuiz.setString(8, quiz.getQuizType());
                psQuiz.setString(9, quiz.getPhotoPath());  // UPDATED: photoPath mapped to parameter index 9
                psQuiz.setInt(10, quiz.getQuizId());       // UPDATED: quiz_id shifted to index 10
                psQuiz.executeUpdate();
            }

            // 2. Clear out older structural nodes (Cascades automatically to options)
            try (PreparedStatement psDel = conn.prepareStatement("DELETE FROM quiz_question WHERE quiz_id=?")) {
                psDel.setInt(1, quiz.getQuizId());
                psDel.executeUpdate();
            }

            // 3. Batch re-insert structural dependencies
            try (PreparedStatement psQuestion = conn.prepareStatement(sqlQuestion, Statement.RETURN_GENERATED_KEYS);
                 PreparedStatement psOption = conn.prepareStatement(sqlOption)) {
                
                for (QuizQuestion q : newQuestions) {
                    psQuestion.setInt(1, quiz.getQuizId());
                    psQuestion.setString(2, q.getQuestionText());
                    psQuestion.setString(3, q.getExplanation());
                    psQuestion.setInt(4, q.getPoints());
                    psQuestion.executeUpdate();

                    int newQuestionId = 0;
                    try (ResultSet rsQ = psQuestion.getGeneratedKeys()) {
                        if (rsQ.next()) {
                            newQuestionId = rsQ.getInt(1);
                        }
                    }

                    for (QuestionOption opt : q.getOptions()) {
                        psOption.setInt(1, newQuestionId);
                        psOption.setString(2, opt.getOptionText());
                        psOption.setBoolean(3, opt.isCorrect());
                        psOption.addBatch();
                    }
                    psOption.executeBatch();
                }
            }

            conn.commit();
            success = true;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return success;
    }

    // ==========================================
    // 8. READ: Get Available Global Public Quizzes for Dashboard Search Modules
    // ==========================================
    public List<Quiz> getAvailableQuizzes(Integer studentClassId) {
        List<Quiz> quizList = new ArrayList<>();
        String sql = "SELECT q.*, (SELECT COUNT(*) FROM quiz_question qq WHERE qq.quiz_id = q.quiz_id) AS question_count " +
                     "FROM quiz q WHERE q.status = 'Active' AND (q.quiz_type = 'Public' OR q.class_id = ?) ORDER BY q.created_date DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
             
            if (studentClassId != null) {
                ps.setInt(1, studentClassId);
            } else {
                ps.setInt(1, -1); 
            }
            
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    quizList.add(mapRowToQuiz(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return quizList;
    }

    // ==========================================
    // 9. NEW/SECURED: Fetch Classroom Quizzes with Strict Enrollment Verification Gate
    // ==========================================
    public List<Quiz> getClassQuizzesSecure(int classId, int userId, String roleId) {
        List<Quiz> list = new ArrayList<>();
        boolean hasAccess = false;
        
        System.out.println("=== DEBUG: getClassQuizzesSecure Initiated ===");
        System.out.println("Checking Access -> ClassID: " + classId + " | UserID: " + userId + " | Role: " + roleId);

        // Admins bypass roster verification checks automatically
        if ("R001".equals(roleId)) {
            hasAccess = true;
            System.out.println("Access Granted: User is Admin (R001)");
        } else {
            // Confirm the user is either the Educator who created the class or an enrolled student
            String verifySql = "SELECT class_id FROM class WHERE class_id = ? AND user_id = ? " +
                               "UNION " +
                               "SELECT class_id FROM class_enrollment WHERE class_id = ? AND user_id = ?";
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement(verifySql)) {
                ps.setInt(1, classId);
                ps.setInt(2, userId);
                ps.setInt(3, classId);
                ps.setInt(4, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        hasAccess = true;
                        System.out.println("Access Granted: User is enrolled or owns the class.");
                    } else {
                        System.out.println("Access Denied: No matching enrollment found in DB for User ID " + userId);
                    }
                }
            } catch (Exception e) { 
                System.out.println("ERROR during verification query! Check column names in 'class_enrollment' table.");
                e.printStackTrace(); 
            }
        }

        // Drop out gracefully if someone attempts to view private workspace items unverified
        if (!hasAccess) {
            System.out.println("Returning empty list due to failed access verification.");
            return list;
        }

        String sql = "SELECT q.*, (SELECT COUNT(*) FROM quiz_question qq WHERE qq.quiz_id = q.quiz_id) AS question_count " +
                     "FROM quiz q WHERE q.class_id = ? ORDER BY q.quiz_id DESC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, classId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRowToQuiz(rs));
                }
                System.out.println("Success: Fetched " + list.size() + " quizzes for Class ID " + classId);
            }
        } catch (SQLException e) { 
            System.out.println("ERROR fetching quizzes from database.");
            e.printStackTrace(); 
        }
        
        System.out.println("=== DEBUG: getClassQuizzesSecure Completed ===");
        return list;
    }
    // ==========================================
    // 10. CREATE: Save Student Quiz Result (CRASH FIX)
    // ==========================================
    public boolean saveQuizResult(int quizId, int userId, int scoreAchieved, int totalScore, Integer classId) {
        String sql = "INSERT INTO quiz_result (quiz_id, user_id, score_achieved, total_score, attempt_date) VALUES (?, ?, ?, ?, NOW())";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, quizId);
            ps.setInt(2, userId);
            ps.setInt(3, scoreAchieved);
            ps.setInt(4, totalScore);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.out.println("DATABASE ERROR WHILE SAVING QUIZ: ");
            e.printStackTrace();
        }
        return false;
    }
    // ==========================================
    // 11. ADMIN: Get ALL Quizzes in the System
    // ==========================================
    public List<Quiz> getAllQuizzesForAdmin() {
        List<Quiz> list = new ArrayList<>();
        String sql = "SELECT q.*, (SELECT COUNT(*) FROM quiz_question qq WHERE qq.quiz_id = q.quiz_id) AS question_count " +
                     "FROM quiz q ORDER BY q.created_date DESC, q.quiz_id DESC";
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
             
            while (rs.next()) {
                list.add(mapRowToQuiz(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }
 
    // ==========================================
    // 12. EDUCATOR: Get Student Results for a Quiz
    // ==========================================
    public List<java.util.Map<String, Object>> getQuizResults(int quizId) {
        List<java.util.Map<String, Object>> results = new ArrayList<>();
        String sql = "SELECT u.full_name, r.score_achieved, r.total_score, r.attempt_date " +
                     "FROM quiz_result r " +
                     "JOIN users u ON r.user_id = u.user_id " +
                     "WHERE r.quiz_id = ? ORDER BY r.score_achieved DESC";
                     
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, quizId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    java.util.Map<String, Object> map = new java.util.HashMap<>();
                    map.put("studentName", rs.getString("full_name"));
                    map.put("score", rs.getInt("score_achieved"));
                    map.put("total", rs.getInt("total_score"));
                    map.put("date", rs.getDate("attempt_date"));

                    int score = rs.getInt("score_achieved");
                    int total = rs.getInt("total_score");
                    int percentage = (total > 0) ? (int) Math.round(((double) score / total) * 100) : 0;
                    map.put("percentage", percentage);
                    
                    results.add(map);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return results;
    }
    
    // ==========================================
    // 13. READ: Fallback fetching legacy list mapping routines
    // ==========================================
    public List<Quiz> getQuizzesByClass(int classId) {
        List<Quiz> list = new ArrayList<>();
        String sql = "SELECT q.*, (SELECT COUNT(*) FROM quiz_question qq WHERE qq.quiz_id = q.quiz_id) AS question_count " +
                     "FROM quiz q WHERE q.class_id = ? ORDER BY q.created_date DESC";
        
        try (Connection conn = DBConnection.getConnection(); 
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, classId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRowToQuiz(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    // ==========================================
    // HELPER METHOD: Maps Database Row to Java Object
    // ==========================================
    private Quiz mapRowToQuiz(ResultSet rs) throws SQLException {
        Quiz q = new Quiz();
        q.setQuizId(rs.getInt("quiz_id"));
        q.setQuizTitle(rs.getString("quiz_title"));
        q.setQuizDescription(rs.getString("quiz_description"));
        q.setVisibility(rs.getString("visibility"));
        q.setTimeLimit(rs.getString("time_limit"));
        q.setTotalMarks(rs.getString("total_marks"));
        q.setStatus(rs.getString("status"));
        q.setCreatedDate(rs.getDate("created_date"));
        q.setUserId(rs.getInt("user_id"));
        
        int classId = rs.getInt("class_id");
        q.setClassId(rs.wasNull() ? null : classId); 
        q.setQuizType(rs.getString("quiz_type"));
        
        // UPDATED: Now extracts the photo path column string from database queries
        q.setPhotoPath(rs.getString("photoPath")); 

        try {
            q.setQuestionCount(rs.getInt("question_count"));
        } catch (SQLException e) {
            // Safe fallback if target metric index is missing from an outer join
        }
        return q;
    }

    // --- CHECK IF STUDENT ALREADY TOOK THE QUIZ (Anti-Cheat) ---
    public boolean checkPreviousAttempt(int userId, int quizId) {
        String sql = "SELECT * FROM quiz_result WHERE user_id = ? AND quiz_id = ?";
        
        try (Connection con = DBConnection.getConnection(); 
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, userId);
            ps.setInt(2, quizId);
            ResultSet rs = ps.executeQuery();
            
            return rs.next(); // Returns true if they have already submitted this quiz
            
        } catch (Exception e) { 
            e.printStackTrace(); 
            return false; 
        }
    }
}