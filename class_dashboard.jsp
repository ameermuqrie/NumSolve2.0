<%-- 
    Document   : class_dashboard
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="dao.ClassDAO, dao.MessageDAO, dao.DBConnection, model.Classroom, model.User, model.DirectMessage, java.util.*, java.sql.*" %>
<%
    // 1. Security Check: Ensure user is logged in
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    
    // Default booleans
    boolean isEducator = false;
    boolean isStudent = false;
    boolean hasUnread = false; 
    boolean hasNewMaterial = false;
    boolean hasNewQuiz = false;
    boolean hasNewStudent = false;
    
    ClassDAO classDao = new ClassDAO();
    Classroom currentClass = null;
    int classId = 0;

    if (u == null) { 
        response.sendRedirect("login.jsp"); 
    } else {
        isEducator = "R002".equals(u.getRoleId());
        isStudent = "R003".equals(u.getRoleId());

        if (!isEducator && !isStudent) {
            response.sendRedirect("login.jsp");
        } else {
            // 2. Get Class Details
            currentClass = (Classroom) request.getAttribute("classDetails");
            
            if (currentClass == null) {
                String classIdStr = request.getParameter("classId");
                if (classIdStr == null || classIdStr.isEmpty()) classIdStr = request.getParameter("id"); 

                if (classIdStr != null && !classIdStr.isEmpty()) {
                    try {
                        classId = Integer.parseInt(classIdStr);
                        currentClass = classDao.getClassById(classId);
                    } catch (NumberFormatException e) { }
                }
            } else {
                classId = currentClass.getClassId();
            }
            
            if (currentClass == null) {
                response.sendRedirect(isEducator ? "manage_classes.jsp" : "student_classes.jsp"); 
            } else {
                boolean isAuthorized = true;
                if (isStudent && !classDao.isStudentEnrolled(classId, u.getUserId())) {
                    isAuthorized = false;
                    response.sendRedirect("student_classes.jsp"); 
                } else if (isEducator && currentClass.getUserId() != u.getUserId()) {
                    isAuthorized = false;
                    response.sendRedirect("manage_classes.jsp"); 
                }
                
                if (isAuthorized) {
                    // ---------------------------------------------------------
                    // 3A. SAFE Q&A NOTIFICATION CHECK
                    // ---------------------------------------------------------
                    try {
                        MessageDAO msgDao = new MessageDAO();
                        hasUnread = msgDao.hasUnreadMessages(classId, u.getUserId(), isEducator);
                        
                        if (isStudent) {
                            int educatorId = currentClass.getUserId();
                            Boolean isRead = (Boolean) session.getAttribute("read_chat_" + classId + "_" + educatorId);
                            if (isRead != null && isRead) hasUnread = false;
                        } else if (isEducator && hasUnread) {
                            List<User> enrolledStudents = classDao.getStudentsByClass(classId);
                            boolean actualUnreadFound = false;
                            if (enrolledStudents != null && !enrolledStudents.isEmpty()) {
                                for (User student : enrolledStudents) {
                                    List<DirectMessage> previewChat = msgDao.getConversation(classId, u.getUserId(), student.getUserId());
                                    if (!previewChat.isEmpty()) {
                                        DirectMessage lastMsg = previewChat.get(previewChat.size() - 1);
                                        if (lastMsg.getSenderId() == student.getUserId()) {
                                            Boolean isRead = (Boolean) session.getAttribute("read_chat_" + classId + "_" + student.getUserId());
                                            if (isRead == null || !isRead) { actualUnreadFound = true; break; }
                                        }
                                    }
                                }
                            }
                            hasUnread = actualUnreadFound;
                        }
                    } catch (Exception e) {
                        // Silently catch errors if MessageDAO method is missing from memory
                    }

                    // ---------------------------------------------------------
                    // 3B. SIMPLE DATABASE RADAR (Uses Safe Fallbacks)
                    // ---------------------------------------------------------
                    Connection conn = null;
                    try {
                        conn = DBConnection.getConnection();
                        if (conn != null) {
                            if (isStudent) {
                                // Check Materials
                                String[] matQueries = {
                                    "SELECT COUNT(*) FROM materials WHERE class_id = ? AND uploaded_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)",
                                    "SELECT COUNT(*) FROM class_materials WHERE class_id = ? AND uploaded_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)"
                                };
                                for (String q : matQueries) {
                                    try (PreparedStatement ps = conn.prepareStatement(q)) {
                                        ps.setInt(1, classId);
                                        try (ResultSet rs = ps.executeQuery()) { if (rs.next() && rs.getInt(1) > 0) { hasNewMaterial = true; break; } }
                                    } catch (Exception ignore) { } // Table might not match, ignore and try next
                                }
                                
                                // Check Quizzes
                                String[] quizQueries = {
                                    "SELECT COUNT(*) FROM quizzes WHERE class_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)",
                                    "SELECT COUNT(*) FROM quiz WHERE class_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)"
                                };
                                for (String q : quizQueries) {
                                    try (PreparedStatement ps = conn.prepareStatement(q)) {
                                        ps.setInt(1, classId);
                                        try (ResultSet rs = ps.executeQuery()) { if (rs.next() && rs.getInt(1) > 0) { hasNewQuiz = true; break; } }
                                    } catch (Exception ignore) { }
                                }
                            } else if (isEducator) {
                                // Check Roster using exact table from ClassDAO
                                String q = "SELECT COUNT(*) FROM class_enrollment WHERE class_id = ? AND enroll_date >= CURDATE()";
                                try (PreparedStatement ps = conn.prepareStatement(q)) {
                                    ps.setInt(1, classId);
                                    try (ResultSet rs = ps.executeQuery()) { if (rs.next() && rs.getInt(1) > 0) hasNewStudent = true; }
                                } catch (Exception ignore) { }
                            }
                        }
                    } catch(Exception e) { 
                        // Silent failover to prevent page crash
                    } finally {
                        if (conn != null) { try { conn.close(); } catch(Exception ex){} }
                    }

                    // ---------------------------------------------------------
                    // 3C. APPLY SMART SESSION OVERRIDES (Clears badge after click)
                    // ---------------------------------------------------------
                    if (session.getAttribute("clearedMaterials_" + classId) != null) hasNewMaterial = false;
                    if (session.getAttribute("clearedQuizzes_" + classId) != null) hasNewQuiz = false;
                    if (session.getAttribute("clearedRoster_" + classId) != null) hasNewStudent = false;

                } else {
                    currentClass = null; 
                }
            }
        }
    }
%>

<% if (currentClass != null && u != null) { %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= currentClass.getClassName() %> | NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES (Premium UI Theme) --- */
        :root {
            --primary: #6366f1;         
            --primary-hover: #4f46e5;
            --primary-glow: rgba(99, 102, 241, 0.25);
            --dark: #1e293b;
            --text-main: #334155;
            --text-muted: #64748b;
            --white: #ffffff;
            
            /* Background Gradients */
            --bg-gradient-1: #e0e7ff;
            --bg-gradient-2: #c7d2fe;
            --bg-gradient-3: #ddd6fe;
            
            /* Glass Effects */
            --glass-bg: rgba(255, 255, 255, 0.75);
            --glass-border: rgba(255, 255, 255, 0.6);
            
            /* Shadows & Transitions */
            --shadow-sm: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
            --shadow-md: 0 10px 25px -5px rgba(0, 0, 0, 0.05);
            --shadow-lg: 0 20px 25px -5px rgba(0, 0, 0, 0.05);
            --shadow-hover: 0 25px 30px -5px rgba(99, 102, 241, 0.15);
            --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            --radius-lg: 24px;
            --radius-md: 16px;

            /* Elegant Card Accent Colors */
            --blue: #3b82f6;     --blue-bg: #eff6ff;
            --green: #10b981;    --green-bg: #ecfdf5;
            --orange: #f97316;   --orange-bg: #fff7ed;
            --purple: #8b5cf6;   --purple-bg: #f5f3ff;
            --cyan: #0ea5e9;     --cyan-bg: #f0f9ff;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(135deg, var(--bg-gradient-1) 0%, var(--bg-gradient-2) 50%, var(--bg-gradient-3) 100%);
            background-attachment: fixed;
            color: var(--text-main); 
            min-height: 100vh; 
            display: flex; 
            flex-direction: column; 
            align-items: center;
            overflow-x: hidden;
        }

        /* --- ENTRANCE ANIMATIONS --- */
        @keyframes slideDown { from { opacity: 0; transform: translateY(-20px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
        
        .animated-nav { animation: slideDown 0.6s ease-out forwards; }
        .animated-panel { animation: fadeUp 0.6s ease-out forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }

        /* --- FLOATING GLASS NAV --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 24px auto;
            background: var(--glass-bg); 
            backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
            padding: 12px 24px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: var(--shadow-sm);
            border: 1px solid var(--glass-border); z-index: 100; position: sticky; top: 24px;
        }

        .brand { 
            font-size: 1.4rem; font-weight: 800; display: flex; align-items: center; gap: 8px; letter-spacing: -0.5px;
            color: var(--dark);
        }
        .brand i { color: var(--primary); font-size: 1.8rem; }

        .back-btn {
            display: flex; align-items: center; gap: 8px; padding: 10px 18px; 
            border-radius: 40px; color: var(--text-main); font-weight: 600; font-size: 0.95rem; 
            text-decoration: none; transition: var(--transition); background: rgba(255, 255, 255, 0.5);
            border: 1px solid var(--glass-border);
        }
        .back-btn:hover { background: var(--white); color: var(--primary); box-shadow: var(--shadow-sm); transform: translateX(-4px); }

        /* --- MAIN CONTENT & HERO SECTION --- */
        .main-content { padding: 10px 24px 48px 24px; flex: 1; max-width: 1400px; width: 100%; }
        
        .hero-section { 
            background: linear-gradient(135deg, var(--primary) 0%, #a855f7 100%); 
            padding: 40px 48px; border-radius: var(--radius-lg); box-shadow: var(--shadow-md); 
            margin-bottom: 40px; display: flex; justify-content: space-between; align-items: center; 
            flex-wrap: wrap; gap: 24px; position: relative; overflow: hidden;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .hero-section::after {
            content: ''; position: absolute; top: -50%; right: -10%; width: 300px; height: 300px;
            background: rgba(255, 255, 255, 0.15); border-radius: 50%; filter: blur(40px); pointer-events: none;
        }

        .hero-title { position: relative; z-index: 2; color: var(--white); }
        .hero-title h1 { font-size: 2.4rem; font-weight: 700; margin-bottom: 8px; letter-spacing: -0.5px; }
        .hero-title p { color: rgba(255, 255, 255, 0.9); font-size: 1.05rem; max-width: 600px; font-weight: 400; }
        
        .educator-badge { 
            background: rgba(255, 255, 255, 0.2); backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px);
            padding: 12px 24px; border-radius: 30px; font-size: 0.95rem; font-weight: 600; color: var(--white); 
            display: inline-flex; align-items: center; gap: 10px; border: 1px solid rgba(255, 255, 255, 0.3); 
            box-shadow: var(--shadow-sm); position: relative; z-index: 2;
        }
        .educator-badge i { font-size: 1.3rem; }
        
        .section-heading { margin-bottom: 24px; color: var(--dark); font-weight: 700; font-size: 1.5rem; letter-spacing: -0.3px; display: flex; align-items: center; gap: 10px;}

        /* --- DASHBOARD CARDS (GRID) --- */
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; }

        .card {
            background: var(--glass-bg); backdrop-filter: blur(20px); padding: 32px 24px; border-radius: var(--radius-lg);
            box-shadow: var(--shadow-sm); transition: var(--transition); display: flex; flex-direction: column; 
            border: 1px solid var(--glass-border); position: relative; z-index: 1; text-align: center;
        }
        .card:hover { transform: translateY(-6px); box-shadow: var(--shadow-hover); border-color: rgba(255, 255, 255, 0.9); }

        .icon-box {
            width: 70px; height: 70px; border-radius: var(--radius-md); display: flex; align-items: center; justify-content: center;
            font-size: 2.2rem; margin: 0 auto 20px auto; transition: var(--transition);
        }
        .card:hover .icon-box { transform: scale(1.08) rotate(5deg); }

        .card h3 { font-size: 1.25rem; color: var(--dark); font-weight: 700; margin-bottom: 12px; }
        .card p { color: var(--text-muted); font-size: 0.95rem; margin-bottom: 28px; line-height: 1.6; flex-grow: 1; }

        /* --- BUTTONS --- */
        .button-group { display: flex; flex-direction: column; gap: 12px; width: 100%; margin-top: auto; }
        
        .btn {
            padding: 12px 20px; border-radius: 12px; font-weight: 600; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; width: 100%;
        }
        .btn i { font-size: 1.2rem; transition: transform 0.3s ease; }
        .btn:hover i { transform: translateX(4px); }

        /* Outline Button Variant */
        .btn-outline { background: transparent; border: 2px solid; }
        .btn-outline:hover i { transform: translateY(-3px); }

        /* --- THEME APPLICATION BY MODULE --- */
        /* Quiz (Orange) */
        .card-orange .icon-box { background: var(--orange-bg); color: var(--orange); }
        .card-orange:hover { border-color: var(--orange-bg); }
        .btn-orange { background: var(--orange-bg); color: var(--orange); }
        .btn-orange:hover { background: var(--orange); color: var(--white); box-shadow: 0 8px 16px rgba(249, 115, 22, 0.2); }
        .btn-outline.orange { color: var(--orange); border-color: var(--orange); }

        /* Material (Cyan) */
        .card-cyan .icon-box { background: var(--cyan-bg); color: var(--cyan); }
        .card-cyan:hover { border-color: var(--cyan-bg); }
        .btn-cyan { background: var(--cyan-bg); color: var(--cyan); }
        .btn-cyan:hover { background: var(--cyan); color: var(--white); box-shadow: 0 8px 16px rgba(14, 165, 233, 0.2); }
        .btn-outline.cyan { color: var(--cyan); border-color: var(--cyan); }

        /* Roster (Purple) */
        .card-purple .icon-box { background: var(--purple-bg); color: var(--purple); }
        .card-purple:hover { border-color: var(--purple-bg); }
        .btn-purple { background: var(--purple-bg); color: var(--purple); }
        .btn-purple:hover { background: var(--purple); color: var(--white); box-shadow: 0 8px 16px rgba(139, 92, 246, 0.2); }

        /* Q&A (Green) */
        .card-green .icon-box { background: var(--green-bg); color: var(--green); }
        .card-green:hover { border-color: var(--green-bg); }
        .btn-green { background: var(--green-bg); color: var(--green); }
        .btn-green:hover { background: var(--green); color: var(--white); box-shadow: 0 8px 16px rgba(16, 185, 129, 0.2); }

        /* --- REFINED NOTIFICATION BADGE --- */
        .notification-badge {
            position: absolute; top: -12px; right: -12px;
            color: white; font-size: 0.75rem; font-weight: 700; text-transform: uppercase;
            letter-spacing: 0.5px; padding: 6px 14px; border-radius: 20px;
            animation: pulse-soft 2.5s infinite; z-index: 10; border: 2px solid var(--white);
        }
        
        .badge-orange { background-color: var(--orange); box-shadow: 0 4px 10px rgba(249, 115, 22, 0.4); }
        .badge-cyan { background-color: var(--cyan); box-shadow: 0 4px 10px rgba(14, 165, 233, 0.4); }
        .badge-purple { background-color: var(--purple); box-shadow: 0 4px 10px rgba(139, 92, 246, 0.4); }
        .badge-green { background-color: var(--green); box-shadow: 0 4px 10px rgba(16, 185, 129, 0.4); }

        @keyframes pulse-soft {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }

        @media (max-width: 1024px) {
            .hero-section { flex-direction: column; align-items: flex-start; }
            .top-nav { width: 90%; border-radius: 20px; }
        }
    </style>
</head>

<body>

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <a href="<%= isEducator ? "manage_classes.jsp" : "student_classes.jsp" %>" class="back-btn">
            <i class='bx bx-left-arrow-alt'></i> Back to Classes
        </a>
    </nav>

    <main class="main-content">
        
        <div class="hero-section animated-panel delay-1">
            <div class="hero-title">
                <h1><%= currentClass.getClassName() %></h1>
                <p><%= currentClass.getClassDescription() != null ? currentClass.getClassDescription() : "No class description provided." %></p>
            </div>
            
            <div class="hero-actions">
                <div class="educator-badge">
                    <% if (isEducator) { %>
                        <i class='bx bx-barcode-reader'></i>
                        Class Code: <strong><%= currentClass.getClassCode() %></strong>
                    <% } else { %>
                        <i class='bx bxs-user-badge'></i>
                        Educator ID: <%= currentClass.getUserId() %>
                    <% } %>
                </div>
            </div>
        </div>

        <h3 class="section-heading animated-panel delay-1"><i class='bx bx-grid-alt' style="color: var(--primary);"></i> Class Workspace</h3>

        <div class="grid animated-panel delay-2">
            
            <div class="card card-orange">
                <% if (hasNewQuiz) { %>
                    <span class="notification-badge badge-orange">New Quiz!</span>
                <% } %>
                <div class="icon-box"><i class='bx bx-task'></i></div>
                <h3><%= isEducator ? "Manage Quizzes" : "Assessments" %></h3>
                <p>
                    <% if (isEducator) { %>
                        Create, edit, and monitor student quiz results for this class setup workspace.
                    <% } else { %>
                        Take quizzes assigned by your educator and track your scoring progress.
                    <% } %>
                </p>
                <div class="button-group">
                    <% if (isEducator) { %>
                        <a href="educatorQuizzes?classId=<%= classId %>" class="btn btn-orange">
                            Manage Quizzes <i class='bx bx-edit-alt'></i>
                        </a>
                        <a href="CreateQuiz.jsp?classId=<%= classId %>" class="btn btn-outline orange">
                            Upload Quiz <i class='bx bx-bar-chart-alt-2'></i>
                        </a>
                    <% } else { %>
                        <a href="student_quizzes.jsp?classId=<%= classId %>" class="btn btn-orange">
                            View Quizzes <i class='bx bx-right-arrow-alt'></i>
                        </a>
                    <% } %>
                </div>
            </div>

            <div class="card card-cyan">
                <% if (hasNewMaterial) { %>
                    <span class="notification-badge badge-cyan">New Material!</span>
                <% } %>
                <div class="icon-box"><i class='bx bxs-book-content'></i></div>
                <h3>Learning Materials</h3>
                <p>
                    <% if (isEducator) { %>
                        Upload and distribute resource files, digital notes, or slides to this class safely.
                    <% } else { %>
                        Access notes, PDF slides, and tutorial videos uploaded for this active class.
                    <% } %>
                </p>
                <div class="button-group">
                    <a href="materials.jsp?classId=<%= classId %>" class="btn btn-cyan">
                        Browse Materials <i class='bx bx-right-arrow-alt'></i>
                    </a>
                    <% if (isEducator) { %>
                        <a href="educator/upload_material.jsp?classId=<%= classId %>" class="btn btn-outline cyan">
                            Upload Material <i class='bx bx-cloud-upload'></i>
                        </a>
                    <% } %>
                </div>
            </div>
            
            <div class="card card-purple">
                <% if (hasNewStudent) { %>
                    <span class="notification-badge badge-purple">New Student!</span>
                <% } %>
                <div class="icon-box"><i class='bx bx-group'></i></div>
                <h3><%= isEducator ? "Class Roster" : "Classmates" %></h3>
                <p>
                    <% if (isEducator) { %>
                        View enrolled profiles, control user states and manage your workspace roster.
                    <% } else { %>
                        See who else is actively enrolled alongside you in this class group.
                    <% } %>
                </p>
                <div class="button-group">
                    <a href="class_roster.jsp?classId=<%= classId %>" class="btn btn-purple">
                        View People <i class='bx bx-user'></i>
                    </a>
                </div>
            </div>

            <div class="card card-green">
                <% if (hasUnread) { %>
                    <span class="notification-badge badge-green">New Message!</span>
                <% } %>
                <div class="icon-box"><i class='bx bx-conversation'></i></div>
                <h3>Q&A Discussions</h3>
                <p>
                    <% if (isEducator) { %>
                        Answer student requests and post important contextual updates or global feeds.
                    <% } else { %>
                        Ask questions and discuss processing steps directly with your educator.
                    <% } %>
                </p>
                <div class="button-group">
                    <a href="class_qa.jsp?classId=<%= classId %>" class="btn btn-green">
                        Open Q&A <i class='bx bx-message-rounded-dots'></i>
                    </a>
                </div>
            </div>
            
        </div>
    </main>

</body>
</html>
<% } %>