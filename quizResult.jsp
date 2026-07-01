<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, java.util.List, java.util.Map" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
    
    User u = (User) session.getAttribute("user");
    Object classId = request.getAttribute("classId");
    List<Map<String, Object>> reviewList = (List<Map<String, Object>>) request.getAttribute("questionReviewList");
    
    String returnUrl = "StudentDashboardServlet";
    if (u != null) {
        if ("R002".equals(u.getRoleId())) {
            // IF PRIVATE CLASS: Redirects to educatorQuizzes?classId=6&view=personal
            // IF PUBLIC QUIZ: Redirects to educatorQuizzes (the public page)
            returnUrl = (classId != null) ? "educatorQuizzes?classId=" + classId + "&view=personal" : "educatorQuizzes";
        } else {
            // Student routing remains standard
            returnUrl = (classId != null) ? "student_quizzes.jsp?classId=" + classId : "StudentDashboardServlet";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mission Complete – NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        :root {
            --student: #3b82f6;         
            --student-hover: #2563eb;   
            --dark: #2c3e50;
            --light: #f4f6f9;
            --white: #ffffff;
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
            --border: #e2e8f0;
            --shadow: 0 10px 25px rgba(0,0,0,0.1);
        }

        body { font-family: 'Poppins', sans-serif; background-color: var(--light); padding: 40px 20px; margin: 0; display: flex; flex-direction: column; align-items: center; min-height: 100vh; }
        
        .result-card {
            background: var(--white); width: 100%; max-width: 650px; padding: 40px 30px;
            border-radius: 20px; box-shadow: var(--shadow); text-align: center;
            border-top: 6px solid var(--student); margin-bottom: 30px;
        }

        .icon-circle {
            width: 90px; height: 90px; border-radius: 50%; display: flex; justify-content: center;
            align-items: center; margin: 0 auto 20px; font-size: 3rem; color: var(--white);
        }

        .color-excellent { background: var(--success); box-shadow: 0 0 20px rgba(16, 185, 129, 0.4); }
        .color-good { background: var(--warning); box-shadow: 0 0 20px rgba(245, 158, 11, 0.4); }
        .color-poor { background: var(--danger); box-shadow: 0 0 20px rgba(239, 68, 68, 0.4); }

        h1 { color: var(--dark); font-size: 2rem; margin: 0 0 5px; }
        p.subtitle { color: #6b7280; margin: 0 0 30px; }

        .score-box { background: var(--light); border: 2px dashed var(--border); padding: 20px; border-radius: 12px; margin-bottom: 25px; }
        .score-number { font-size: 3rem; font-weight: 700; color: var(--student); line-height: 1; margin-bottom: 5px; }
        .score-label { font-size: 1rem; color: var(--dark); font-weight: 500; }

        .review-container { width: 100%; max-width: 650px; text-align: left; margin-bottom: 50px; }
        .review-title { font-size: 1.4rem; font-weight: 600; color: var(--dark); margin-bottom: 15px; display: flex; align-items: center; gap: 8px; }
        
        .review-item {
            background: var(--white); border-radius: 12px; padding: 20px; margin-bottom: 15px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.05); border-left: 5px solid #cbd5e1;
        }
        .review-item.correct { border-left-color: var(--success); }
        .review-item.incorrect { border-left-color: var(--danger); }
        
        .rev-question { font-size: 1.05rem; font-weight: 600; color: var(--dark); margin-bottom: 10px; }
        .rev-details { font-size: 0.95rem; margin: 4px 0; }
        .rev-details strong { color: #475569; }
        
        .badge { display: inline-block; padding: 4px 10px; font-size: 0.8rem; font-weight: 600; border-radius: 20px; color: var(--white); margin-bottom: 8px; }
        .badge.bg-success { background-color: var(--success); }
        .badge.bg-danger { background-color: var(--danger); }

        .btn-home {
            display: inline-flex; align-items: center; justify-content: center; gap: 8px;
            background: var(--student); color: var(--white); width: 100%; padding: 15px;
            border-radius: 10px; text-decoration: none; font-weight: 600; font-size: 1.1rem;
            transition: all 0.3s; margin-top: 10px; box-sizing: border-box;
        }
        .btn-home:hover { background: var(--student-hover); transform: translateY(-2px); }
    </style>
</head>
<body>

    <div class="result-card">
        <% 
            Integer percentage = (Integer) request.getAttribute("percentage");
            if (percentage == null) percentage = 0;
            
            String iconClass = "bx-trophy";
            String colorClass = "color-excellent";
            String message = "Outstanding Work!";
            
            if (percentage < 50) {
                iconClass = "bx-tired";
                colorClass = "color-poor";
                message = "Keep Practicing!";
            } else if (percentage < 80) {
                iconClass = "bx-star";
                colorClass = "color-good";
                message = "Great Effort!";
            }
        %>

        <div class="icon-circle <%= colorClass %>">
            <i class='bx <%= iconClass %>'></i>
        </div>

        <h1><%= message %></h1>
        <p class="subtitle">Mission successfully submitted and auto-graded.</p>

        <div class="score-box">
            <div class="score-number">${score} / ${maxScore}</div>
            <div class="score-label">Total Points Earned (${percentage}%)</div>
        </div>

        <a href="${pageContext.request.contextPath}/<%= returnUrl %>" class="btn-home">
            <i class='bx bx-home-alt'></i> Return to Dashboard
        </a>
    </div>

    <% if (reviewList != null && !reviewList.isEmpty()) { %>
        <div class="review-container">
            <div class="review-title"><i class='bx bx-list-check'></i> Mission Breakdown</div>
            
            <% 
                int qNum = 1;
                for (Map<String, Object> rev : reviewList) { 
                    boolean isCorrect = (Boolean) rev.get("isCorrect");
            %>
                <div class="review-item <%= isCorrect ? "correct" : "incorrect" %>">
                    <span class="badge <%= isCorrect ? "bg-success" : "bg-danger" %>">
                        <%= isCorrect ? "CORRECT" : "INCORRECT" %> (+<%= rev.get("points") %> Pts)
                    </span>
                    <div class="rev-question">Question <%= qNum++ %>: <%= rev.get("text") %></div>
                    <div class="rev-details"><strong>Your Answer:</strong> <%= rev.get("chosen") %></div>
                    <div class="rev-details"><strong>Correct Answer:</strong> <%= rev.get("correctAnswer") %></div>
                </div>
            <% } %>
        </div>
    <% } %>

</body>
</html>