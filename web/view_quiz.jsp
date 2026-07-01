<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.*, java.util.List" %>
<%
    // Prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Security check
    User u = (User) session.getAttribute("user");
    if (u == null || (!"R001".equals(u.getRoleId()) && !"R002".equals(u.getRoleId()))) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Retrieve data passed from ViewQuizServlet
    Quiz quiz = (Quiz) request.getAttribute("quiz");
    List<QuizQuestion> questions = (List<QuizQuestion>) request.getAttribute("questions");

    if (quiz == null) {
        // Fallback if accessed directly without going through the servlet
        out.println("<script>alert('Error loading quiz details.'); history.back();</script>");
        return;
    }

    // --- SUPER SMART ROUTING FOR BACK BUTTON ---
    String backLink = "";
    String roleId = u.getRoleId();
    String classIdParam = request.getParameter("classId");
    String viewParam = request.getParameter("view");

    if ("R001".equals(roleId)) {
        // Admin goes back to Admin Dashboard
        backLink = request.getContextPath() + "/admin_quizzes.jsp";
    } else {
        // Educator dynamic return logic
        backLink = request.getContextPath() + "/educatorQuizzes";
        boolean hasParam = false;
        
        // If they came from a specific class, attach the class ID
        if (classIdParam != null && !classIdParam.trim().isEmpty()) {
            backLink += "?classId=" + classIdParam;
            hasParam = true;
        }
        
        // If they came from personal/public tabs, attach the view state
        if (viewParam != null && !viewParam.trim().isEmpty()) {
            backLink += (hasParam ? "&" : "?") + "view=" + viewParam;
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Quiz: <%= quiz.getQuizTitle() != null ? quiz.getQuizTitle() : "Untitled" %></title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        :root {
            --primary: #3b82f6;         
            --primary-hover: #2563eb;
            --dark: #0f172a;
            --white: #ffffff;
            --gray: #64748b;
            --bg: #f8fafc;
            --border: rgba(0, 0, 0, 0.08);
            --shadow: 0 10px 30px rgba(0,0,0,0.05);
            --radius: 16px;
            
            --correct-bg: #dcfce3;
            --correct-text: #166534;
            --correct-border: #22c55e;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
            background-attachment: fixed;
            color: var(--dark); 
            min-height: 100vh; 
            padding-bottom: 50px;
        }

        /* --- HEADER NAVIGATION --- */
        .header-nav {
            width: 100%; max-width: 900px; margin: 30px auto;
            display: flex; justify-content: space-between; align-items: center;
        }
        .btn-back {
            display: inline-flex; align-items: center; gap: 8px;
            background: var(--white); color: var(--dark);
            padding: 10px 20px; border-radius: 30px;
            text-decoration: none; font-weight: 600; font-size: 0.95rem;
            box-shadow: 0 4px 15px rgba(0,0,0,0.05); transition: all 0.3s ease;
        }
        .btn-back:hover { transform: translateX(-5px); box-shadow: 0 6px 20px rgba(0,0,0,0.1); color: var(--primary); }

        /* --- MAIN CONTAINER --- */
        .container {
            width: 95%; max-width: 900px; margin: 0 auto;
        }

        /* --- QUIZ META CARD --- */
        .quiz-header-card {
            background: rgba(255, 255, 255, 0.8); backdrop-filter: blur(15px);
            border-radius: var(--radius); padding: 35px; box-shadow: var(--shadow);
            border: 1px solid rgba(255,255,255,0.5); margin-bottom: 30px;
            text-align: center;
        }

        .quiz-cover {
            width: 100%; max-height: 300px; object-fit: cover; border-radius: 12px;
            margin-bottom: 20px; box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .no-cover-icon {
            font-size: 5rem; color: var(--primary); margin-bottom: 15px; opacity: 0.8;
        }

        .quiz-title { font-size: 2.2rem; font-weight: 800; color: var(--dark); margin-bottom: 10px; }
        .quiz-desc { font-size: 1.05rem; color: var(--gray); margin-bottom: 25px; line-height: 1.6; }

        .quiz-stats {
            display: flex; justify-content: center; gap: 20px; flex-wrap: wrap;
        }
        .stat-badge {
            background: var(--white); padding: 8px 16px; border-radius: 20px;
            font-weight: 600; font-size: 0.9rem; color: var(--dark);
            display: flex; align-items: center; gap: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid var(--border);
        }
        .stat-badge i { color: var(--primary); font-size: 1.2rem; }

        /* --- QUESTION CARDS --- */
        .questions-wrapper { display: flex; flex-direction: column; gap: 20px; }
        
        .question-card {
            background: var(--white); border-radius: var(--radius); padding: 30px;
            box-shadow: var(--shadow); border: 1px solid var(--border);
        }

        .q-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
        .q-number { font-weight: 800; color: var(--primary); font-size: 1.1rem; text-transform: uppercase; letter-spacing: 1px; }
        .q-points { background: #f1f5f9; color: #475569; padding: 4px 12px; border-radius: 20px; font-size: 0.85rem; font-weight: 700; }

        .q-text { font-size: 1.2rem; font-weight: 600; color: var(--dark); margin-bottom: 20px; line-height: 1.5; }

        .options-list { list-style: none; display: flex; flex-direction: column; gap: 10px; }
        .option-item {
            padding: 15px 20px; border-radius: 10px; background: var(--bg);
            border: 2px solid #e2e8f0; font-size: 1rem; font-weight: 500; color: #334155;
            display: flex; align-items: center; justify-content: space-between; transition: all 0.2s;
        }
        
        /* Highlight correct option */
        .option-item.correct {
            background: var(--correct-bg); border-color: var(--correct-border); color: var(--correct-text);
        }
        .option-item.correct i { font-size: 1.4rem; color: var(--correct-border); }

        .explanation-box {
            margin-top: 20px; padding: 15px 20px; border-radius: 8px;
            background: #f0fdf4; border-left: 4px solid #22c55e;
            font-size: 0.95rem; color: #166534; line-height: 1.5;
        }
        .explanation-box strong { display: flex; align-items: center; gap: 5px; margin-bottom: 5px; color: #15803d; }
    </style>
</head>
<body>

    <div class="header-nav">
        <a href="<%= backLink %>" class="btn-back">
            <i class='bx bx-left-arrow-alt'></i> Back to Dashboard
        </a>
    </div>

    <div class="container">
        
        <div class="quiz-header-card">
            <% if (quiz.getPhotoPath() != null && !quiz.getPhotoPath().trim().isEmpty()) { %>
                <img src="<%= request.getContextPath() %>/<%= quiz.getPhotoPath() %>" class="quiz-cover" alt="Quiz Cover">
            <% } else { %>
                <i class='bx bx-brain no-cover-icon'></i>
            <% } %>

            <h1 class="quiz-title"><%= quiz.getQuizTitle() != null ? quiz.getQuizTitle() : "Untitled Quiz" %></h1>
            <p class="quiz-desc"><%= quiz.getQuizDescription() != null && !quiz.getQuizDescription().isEmpty() ? quiz.getQuizDescription() : "No description provided for this assessment." %></p>

            <div class="quiz-stats">
                <span class="stat-badge"><i class='bx bx-stopwatch'></i> <%= quiz.getTimeLimit() != null ? quiz.getTimeLimit() : "--" %> Mins</span>
                <span class="stat-badge"><i class='bx bx-target-lock'></i> <%= quiz.getTotalMarks() != null ? quiz.getTotalMarks() : "0" %> Total Points</span>
                <span class="stat-badge"><i class='bx bx-list-ol'></i> <%= questions != null ? questions.size() : "0" %> Questions</span>
                <span class="stat-badge"><i class='bx bx-globe'></i> <%= quiz.getVisibility() != null ? quiz.getVisibility() : "Unknown" %></span>
            </div>
        </div>

        <div class="questions-wrapper">
            <% 
                if (questions == null || questions.isEmpty()) { 
            %>
                <div class="question-card" style="text-align: center; color: var(--gray);">
                    <i class='bx bx-error-circle' style="font-size: 3rem; margin-bottom: 10px; opacity: 0.5;"></i>
                    <p>No questions have been added to this quiz yet.</p>
                </div>
            <% 
                } else {
                    int questionNum = 1;
                    for (QuizQuestion q : questions) {
            %>
                <div class="question-card">
                    <div class="q-header">
                        <span class="q-number">Question <%= questionNum++ %></span>
                        <span class="q-points"><%= q.getPoints() %> Points</span>
                    </div>
                    
                    <div class="q-text">
                        <%= q.getQuestionText() != null ? q.getQuestionText() : "Untitled Question" %>
                    </div>

                    <ul class="options-list">
                        <% 
                            List<QuestionOption> options = q.getOptions();
                            if (options != null) {
                                for (QuestionOption opt : options) {
                                    boolean isCorrect = opt.isCorrect();
                                    String optionClass = isCorrect ? "option-item correct" : "option-item";
                        %>
                            <li class="<%= optionClass %>">
                                <span><%= opt.getOptionText() %></span>
                                <% if (isCorrect) { %><i class='bx bxs-check-circle'></i><% } %>
                            </li>
                        <% 
                                }
                            }
                        %>
                    </ul>

                    <% if (q.getExplanation() != null && !q.getExplanation().trim().isEmpty()) { %>
                        <div class="explanation-box">
                            <strong><i class='bx bx-bulb'></i> Educator's Explanation</strong>
                            <%= q.getExplanation() %>
                        </div>
                    <% } %>
                </div>
            <% 
                    }
                }
            %>
        </div>

    </div>

</body>
</html>