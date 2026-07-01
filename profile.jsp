<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.User, java.text.SimpleDateFormat" %>
<%
    // 1. SECURITY & CACHE CONTROL
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    if (u == null) { response.sendRedirect(request.getContextPath() + "/login.jsp"); return; }
    
    // 2. SET ROLE CLASS (Used for dynamic CSS styling with safe fallback)
    String roleId = (u.getRoleId() != null) ? u.getRoleId() : "R003";
    String roleClass = "role-" + roleId;
    
    // 3. GET MESSAGES
    String msg = (String) session.getAttribute("msg");
    session.removeAttribute("msg"); 
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile | NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES & DYNAMIC ROLE THEMING --- */
        :root {
            --dark: #0f172a;
            --white: #ffffff;
            --gray: #475569;
            --border: rgba(255, 255, 255, 0.5);
            --shadow: 0 10px 40px rgba(0,0,0,0.06);
            --shadow-hover: 0 15px 50px rgba(0,0,0,0.12);
            --transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
            --radius: 24px;
        }

        /* Default (Admin - Red Glass) */
        body.role-R001 { 
            --primary: #ef4444; --primary-hover: #dc2626; --primary-glow: rgba(239, 68, 68, 0.35);
            --bg-1: #fef2f2; --bg-2: #fee2e2; --bg-3: #fca5a5;
            --nav-hover: rgba(239, 68, 68, 0.1);
        }
        /* Educator - Purple Glass */
        body.role-R002 { 
            --primary: #8b5cf6; --primary-hover: #7c3aed; --primary-glow: rgba(139, 92, 246, 0.35);
            --bg-1: #faf5ff; --bg-2: #f3e8ff; --bg-3: #d8b4fe;
            --nav-hover: rgba(139, 92, 246, 0.1);
        }
        /* Student - Blue Glass */
        body.role-R003 { 
            --primary: #3b82f6; --primary-hover: #2563eb; --primary-glow: rgba(59, 130, 246, 0.35);
            --bg-1: #eff6ff; --bg-2: #dbeafe; --bg-3: #93c5fd;
            --nav-hover: rgba(59, 130, 246, 0.1);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(135deg, var(--bg-1) 0%, var(--bg-2) 50%, var(--bg-3) 100%);
            background-attachment: fixed;
            color: var(--dark); 
            min-height: 100vh; 
            display: flex; 
            flex-direction: column; 
            align-items: center;
            overflow-x: hidden;
            position: relative;
        }

        /* Ambient Background Orbs for Premium Glassmorphism */
        body::before, body::after {
            content: ''; position: fixed; border-radius: 50%; filter: blur(120px); z-index: -1;
            animation: float 10s infinite ease-in-out alternate;
        }
        body::before { width: 400px; height: 400px; background: var(--primary); top: -100px; left: -100px; opacity: 0.2; }
        body::after { width: 500px; height: 500px; background: var(--bg-3); bottom: -150px; right: -150px; opacity: 0.4; animation-delay: -5s; }

        @keyframes float { 0% { transform: translate(0, 0) scale(1); } 100% { transform: translate(30px, 50px) scale(1.1); } }
        @keyframes dropDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
        
        .animated-nav { animation: dropDown 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .animated-panel { animation: fadeInUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }
        .delay-3 { animation-delay: 0.3s; }

        /* --- FLOATING GLASS NAV --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 25px auto;
            background: rgba(255, 255, 255, 0.5); 
            backdrop-filter: blur(16px); 
            -webkit-backdrop-filter: blur(16px);
            padding: 12px 25px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: var(--shadow);
            border: 1px solid var(--border); z-index: 100; position: sticky; top: 25px;
            gap: 20px;
            transition: var(--transition);
        }

        .brand { 
            font-size: 1.5rem; font-weight: 800; display: flex; align-items: center; gap: 8px; flex-shrink: 0;
            background: linear-gradient(135deg, var(--primary), var(--dark)); -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }
        .brand i { color: var(--primary); -webkit-text-fill-color: initial; font-size: 1.8rem; }
        
        .nav-menu { 
            list-style: none; display: flex; align-items: center; gap: 6px; 
            overflow-x: auto; scroll-snap-type: x mandatory; scrollbar-width: none;
            padding-bottom: 2px;
        }
        .nav-menu::-webkit-scrollbar { display: none; }

        .nav-link {
            display: flex; align-items: center; gap: 10px; padding: 10px; 
            border-radius: 40px; color: var(--gray); 
            font-weight: 600; font-size: 0.95rem; text-decoration: none; 
            max-width: 44px; 
            white-space: nowrap; overflow: hidden;
            transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
            scroll-snap-align: start;
        }

        .nav-link i { font-size: 1.4rem; min-width: 24px; text-align: center; }
        .nav-link span { opacity: 0; transform: translateX(-15px); transition: all 0.3s ease; }

        .nav-link:hover { background: rgba(255, 255, 255, 0.9); color: var(--primary); max-width: 160px; padding: 10px 20px; }
        .nav-link:hover span { opacity: 1; transform: translateX(0); }
        
        .nav-link.active {
            background: var(--primary); color: var(--white);
            box-shadow: 0 8px 20px var(--primary-glow); max-width: 160px; padding: 10px 20px;
        }
        .nav-link.active span { opacity: 1; transform: translateX(0); }

        .logout-item { margin-left: 10px; border-left: 1px solid var(--border); padding-left: 10px; transition: var(--transition); }
        .logout-item .nav-link:hover { background: var(--nav-hover); color: var(--primary); }

        /* --- MAIN CONTENT & HEADER --- */
        .main-content { padding: 10px 20px 60px 20px; flex: 1; max-width: 1100px; width: 100%; margin: 0 auto; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; 
            background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(16px); padding: 30px 40px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
        }
        .header-area h2 { font-size: 2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area p { color: var(--gray); font-size: 1.05rem; margin-top: 5px; font-weight: 500;}

        /* Alert Glass Message */
        .alert-success {
            background: rgba(220, 252, 231, 0.8); color: #166534; padding: 16px 24px; 
            border-radius: 16px; margin-bottom: 30px; border: 1px solid rgba(134, 239, 172, 0.6);
            display: flex; align-items: center; gap: 12px; font-weight: 600;
            backdrop-filter: blur(10px); box-shadow: var(--shadow);
        }

        /* --- GLASS CARDS --- */
        .glass-card { 
            background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
            border-radius: var(--radius); box-shadow: var(--shadow); 
            border: 1px solid var(--border); padding: 40px; margin-bottom: 30px;
            transition: var(--transition);
        }
        .glass-card:hover { box-shadow: var(--shadow-hover); transform: translateY(-2px); }

        .profile-header { display: flex; align-items: center; gap: 40px; }

        .profile-img-large {
            width: 140px; height: 140px; border-radius: 50%; object-fit: cover;
            border: 5px solid rgba(255,255,255,0.9); box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            background: var(--white);
        }
        
        .profile-avatar-placeholder {
            width: 140px; height: 140px; border-radius: 50%; 
            background: linear-gradient(135deg, var(--primary) 0%, var(--dark) 100%);
            color: var(--white); display: flex; align-items: center; justify-content: center;
            font-size: 4rem; font-weight: 700; box-shadow: 0 10px 30px var(--primary-glow);
            border: 5px solid rgba(255,255,255,0.9);
        }

        .tag {
            background: rgba(255, 255, 255, 0.8); color: var(--primary); padding: 8px 16px;
            border-radius: 30px; font-size: 0.85rem; font-weight: 700; display: inline-flex; align-items: center; gap: 6px;
            border: 1px solid var(--border); box-shadow: 0 2px 10px rgba(0,0,0,0.03);
        }

        /* --- INFO ROW STYLING --- */
        .info-row {
            padding: 20px 0; border-bottom: 1px solid rgba(0, 0, 0, 0.05); display: flex; align-items: center;
        }
        .info-row:last-child { border-bottom: none; }
        .info-label { width: 220px; font-weight: 600; color: var(--gray); display: flex; align-items: center; gap: 12px; font-size: 0.95rem; }
        .info-label i { font-size: 1.3rem; color: var(--primary); opacity: 0.9; }
        .info-value { color: var(--dark); flex: 1; font-weight: 600; line-height: 1.6; font-size: 1rem; }

        /* --- FORM STYLING --- */
        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px; }
        .form-group { margin-bottom: 8px; }
        .form-group label { display: block; color: var(--dark); font-weight: 700; font-size: 0.9rem; margin-bottom: 10px; }
        .form-control {
            width: 100%; padding: 15px 22px; border: 1px solid rgba(255, 255, 255, 0.8); 
            border-radius: 16px; font-size: 0.95rem; font-weight: 500; font-family: 'Poppins', sans-serif; 
            background: rgba(255, 255, 255, 0.6); color: var(--dark); transition: var(--transition);
            box-shadow: inset 0 2px 5px rgba(0,0,0,0.02); outline: none;
        }
        .form-control::placeholder { color: #94a3b8; font-weight: 400; }
        .form-control:hover { background: rgba(255, 255, 255, 0.8); }
        .form-control:focus { 
            border-color: var(--primary); background: var(--white); 
            box-shadow: 0 0 0 4px var(--primary-glow), inset 0 2px 5px rgba(0,0,0,0.01); 
        }
        textarea.form-control { height: 130px; resize: vertical; line-height: 1.6; }
        .full-width { grid-column: 1 / -1; }

        /* --- BUTTONS --- */
        .btn {
            padding: 14px 28px; border-radius: 30px; font-weight: 700; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; position: relative;
            outline: none;
        }
        .btn-primary { 
            background-color: var(--primary); 
            background-image: linear-gradient(135deg, rgba(255,255,255,0.15) 0%, rgba(255,255,255,0) 100%);
            color: var(--white); 
            box-shadow: 0 8px 25px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.3); 
            border: 1px solid rgba(255, 255, 255, 0.2); backdrop-filter: blur(10px);
        }
        .btn-primary:hover { 
            background-color: var(--primary-hover); transform: translateY(-3px); 
            box-shadow: 0 12px 30px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.5); 
        }
        .btn-secondary { 
            background: rgba(255, 255, 255, 0.8); color: var(--dark); 
            border: 1px solid var(--border); backdrop-filter: blur(10px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.04);
        }
        .btn-secondary:hover { 
            background: var(--white); transform: translateY(-3px); 
            box-shadow: 0 8px 25px rgba(0,0,0,0.1); 
        }

        /* --- RESPONSIVENESS --- */
        
        /* Tablet Breakpoint: Strict Icon-Based Navigation */
        @media (max-width: 1024px) {
            .nav-link span { display: none !important; }
            .nav-link:hover, .nav-link.active { 
                max-width: 44px; /* Prevent expansion */
                padding: 10px; 
                justify-content: center; 
            }
            .nav-link i { margin: 0; }
        }

        /* Mobile Breakpoint: Stacked Layout & Adjustments */
        @media (max-width: 768px) {
            .top-nav { width: 92%; padding: 15px; flex-direction: column; gap: 15px; border-radius: 25px; }
            .brand { justify-content: center; width: 100%; }
            .nav-menu { width: 100%; justify-content: center; flex-direction: row; flex-wrap: wrap; gap: 8px; }
            
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
            
            .header-area { flex-direction: column; align-items: flex-start; gap: 20px; padding: 25px; }
            .user-info { text-align: left !important; width: 100%; }
            
            .glass-card { padding: 25px; }
            
            .profile-header { flex-direction: column; text-align: center; gap: 20px; }
            .profile-header > div { display: flex; flex-direction: column; align-items: center; }
            
            .info-row { flex-direction: column; align-items: flex-start; gap: 8px; padding: 16px 0; }
            .info-label { width: 100%; }
            
            .btn { width: 100%; justify-content: center; }
            #view-mode > div:first-child { flex-direction: column; gap: 15px; align-items: flex-start; }
            #edit-mode form > div:last-child { flex-direction: column-reverse; }
        }
    </style>
</head>
<body class="<%= roleClass %>">

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            
            <%-- Admin (R001) Links --%>
            <% if ("R001".equals(roleId)) { %>
                <li><a href="<%= request.getContextPath() %>/dashboard/admin.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="<%= request.getContextPath() %>/admin/admin_materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="<%= request.getContextPath() %>/users.jsp" class="nav-link"><i class='bx bxs-user-account'></i> <span>Users</span></a></li>
                <li><a href="<%= request.getContextPath() %>/logs.jsp" class="nav-link"><i class='bx bxs-server'></i> <span>Logs</span></a></li>
                <li><a href="<%= request.getContextPath() %>/reports.jsp" class="nav-link"><i class='bx bxs-chart'></i> <span>Reports</span></a></li>
                <li><a href="<%= request.getContextPath() %>/admin_quizzes.jsp" class="nav-link"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
                <li><a href="<%= request.getContextPath() %>/profile.jsp" class="nav-link active"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="<%= request.getContextPath() %>/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>

            <%-- Educator (R002) Links --%>
            <% } else if ("R002".equals(roleId)) { %>
                <li><a href="<%= request.getContextPath() %>/dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="<%= request.getContextPath() %>/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                <li><a href="<%= request.getContextPath() %>/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                <li><a href="<%= request.getContextPath() %>/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                <li><a href="<%= request.getContextPath() %>/manage_classes.jsp" class="nav-link"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
                <li><a href="<%= request.getContextPath() %>/educatorQuizzes" class="nav-link"><i class='bx bx-task'></i><span>Quizzes</span></a></li>
                <li><a href="<%= request.getContextPath() %>/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="<%= request.getContextPath() %>/profile.jsp" class="nav-link active"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="<%= request.getContextPath() %>/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
                
            <%-- Student (R003) Links --%>
            <% } else { %>
                <li><a href="<%= request.getContextPath() %>/dashboard/student.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="<%= request.getContextPath() %>/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                <li><a href="<%= request.getContextPath() %>/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                <li><a href="<%= request.getContextPath() %>/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                <li><a href="<%= request.getContextPath() %>/student_classes.jsp" class="nav-link"><i class='bx bxs-group'></i> <span>Classes</span></a></li>            
                <li><a href="<%= request.getContextPath() %>/StudentDashboardServlet" class="nav-link"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
                <li><a href="<%= request.getContextPath() %>/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="<%= request.getContextPath() %>/profile.jsp" class="nav-link active"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="<%= request.getContextPath() %>/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
            <% } %>
            
        </ul>
    </nav>

    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <div>
                <h2><i class='bx bxs-user-circle' style="color: var(--primary);"></i> My Profile</h2>
                <p>Manage your personal information and account settings.</p>
            </div>
            <div class="user-info" style="text-align: right; background: rgba(255,255,255,0.8); padding: 12px 24px; border-radius: 16px; border: 1px solid var(--border); box-shadow: 0 4px 15px rgba(0,0,0,0.03);">
                <p style="font-weight: 700; color: var(--dark); font-size: 1.1rem;"><%= u.getFullName() %></p>
                <p style="font-size: 0.9rem; color: var(--gray); font-weight: 500;">ID: <%= u.getUserId() %></p>
            </div>
        </div>

        <% if(msg != null) { %>
            <div class="alert-success animated-panel delay-1">
                <i class='bx bxs-check-circle' style="font-size: 1.5rem;"></i> <%= msg %>
            </div>
        <% } %>

        <div class="glass-card profile-header animated-panel delay-2">
            <% if(u.getPhotoPath() != null && !u.getPhotoPath().isEmpty()) { %>
                <img src="<%= u.getPhotoPath() %>" class="profile-img-large">
            <% } else { %>
                <div class="profile-avatar-placeholder">
                    <%= u.getFullName().charAt(0) %>
                </div>
            <% } %>
            
            <div>
                <h2 style="font-size: 2.2rem; margin-bottom: 6px; color: var(--dark); font-weight: 800; letter-spacing: -0.5px;"><%= u.getFullName() %></h2>
                <p style="color: var(--gray); font-size: 1.1rem; margin-bottom: 18px; display: flex; align-items: center; gap: 8px; font-weight: 500;"><i class='bx bx-envelope' style="font-size: 1.3rem; color: var(--primary);"></i> <%= u.getEmail() %></p>
                
                <div style="display: flex; gap: 12px; flex-wrap: wrap;">
                    <span class="tag">
                        <i class='bx bxs-badge-check'></i>
                        <%= "R001".equals(roleId) ? "Administrator" : ("R002".equals(roleId) ? "Educator" : "Student") %>
                    </span>
                    <span class="tag" style="background: rgba(255, 255, 255, 0.5); color: var(--dark);">
                        <i class='bx bx-calendar'></i> Member since <%= u.getMemberSince() %>
                    </span>
                </div>
            </div>
        </div>

        <div class="glass-card animated-panel delay-3">
            
            <div id="view-mode">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:24px; border-bottom:1px solid rgba(0, 0, 0, 0.05); padding-bottom:16px;">
                    <h3 style="color: var(--dark); font-size: 1.3rem; font-weight: 800; letter-spacing: -0.5px;">Personal Information</h3>
                    <button onclick="toggleEdit(true)" class="btn btn-primary"><i class='bx bxs-edit'></i> Edit Profile</button>
                </div>

                <div class="info-row">
                    <span class="info-label"><i class='bx bx-user'></i> Full Name</span>
                    <span class="info-value"><%= u.getFullName() %></span>
                </div>
                <div class="info-row">
                    <span class="info-label"><i class='bx bx-envelope'></i> Email Address</span>
                    <span class="info-value"><%= u.getEmail() %></span>
                </div>
                <div class="info-row">
                    <span class="info-label"><i class='bx bx-phone'></i> Phone Number</span>
                    <span class="info-value"><%= (u.getPhone() != null && !u.getPhone().isEmpty()) ? u.getPhone() : "<span style='color:var(--gray); font-style:italic; font-weight:400;'>Not set</span>" %></span>
                </div>
                <div class="info-row">
                    <span class="info-label"><i class='bx bx-buildings'></i> Department</span>
                    <span class="info-value"><%= (u.getDepartment() != null && !u.getDepartment().isEmpty()) ? u.getDepartment() : "<span style='color:var(--gray); font-style:italic; font-weight:400;'>Not set</span>" %></span>
                </div>
                <div class="info-row">
                    <span class="info-label"><i class='bx bx-map-pin'></i> Location</span>
                    <span class="info-value"><%= (u.getLocation() != null && !u.getLocation().isEmpty()) ? u.getLocation() : "<span style='color:var(--gray); font-style:italic; font-weight:400;'>Not set</span>" %></span>
                </div>
                <div class="info-row">
                    <span class="info-label"><i class='bx bx-info-circle'></i> Bio</span>
                    <span class="info-value"><%= (u.getBio() != null && !u.getBio().isEmpty()) ? u.getBio() : "<span style='color:var(--gray); font-style:italic; font-weight:400;'>No bio added yet.</span>" %></span>
                </div>
            </div>

            <div id="edit-mode" style="display:none;">
                <div style="margin-bottom:24px; border-bottom:1px solid rgba(0, 0, 0, 0.05); padding-bottom:16px;">
                    <h3 style="color: var(--dark); font-size: 1.3rem; font-weight: 800; letter-spacing: -0.5px;">Edit Profile Details</h3>
                </div>

                <form action="updateProfile" method="post" enctype="multipart/form-data">
                    <div class="form-grid">
                        
                        <div class="form-group full-width">
                            <label><i class='bx bx-image-add' style="font-size: 1.2rem; vertical-align: -2px; color: var(--primary);"></i> Change Profile Photo</label>
                            <input type="file" name="photo" accept="image/*" class="form-control" style="padding: 12px 18px;">
                        </div>

                        <div class="form-group">
                            <label>Full Name</label>
                            <input type="text" name="full_name" class="form-control" value="<%= u.getFullName() %>" required>
                        </div>

                        <div class="form-group">
                            <label>Email Address</label>
                            <input type="email" name="email" class="form-control" value="<%= u.getEmail() %>" required>
                        </div>

                        <div class="form-group">
                            <label>Phone Number</label>
                            <input type="text" name="phone" class="form-control" value="<%= u.getPhone()!=null?u.getPhone():"" %>" placeholder="+60...">
                        </div>

                        <div class="form-group">
                            <label>Department / Faculty</label>
                            <input type="text" name="department" class="form-control" value="<%= u.getDepartment()!=null?u.getDepartment():"" %>" placeholder="e.g. Computer Science">
                        </div>

                        <div class="form-group full-width">
                            <label>Location / Office</label>
                            <input type="text" name="location" class="form-control" value="<%= u.getLocation()!=null?u.getLocation():"" %>" placeholder="e.g. Block A, Level 2">
                        </div>

                        <div class="form-group full-width">
                            <label>Bio / About Me</label>
                            <textarea name="bio" class="form-control" placeholder="Tell us about yourself..."><%= u.getBio()!=null?u.getBio():"" %></textarea>
                        </div>
                    </div>

                    <div style="display:flex; justify-content:flex-end; gap:14px; margin-top:30px; border-top: 1px solid rgba(0, 0, 0, 0.05); padding-top: 24px;">
                        <button type="button" onclick="toggleEdit(false)" class="btn btn-secondary">Cancel</button>
                        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Save Changes</button>
                    </div>
                </form>
            </div>

        </div>
    </main>

    <script>
        function toggleEdit(showEdit) {
            var viewMode = document.getElementById('view-mode');
            var editMode = document.getElementById('edit-mode');
            
            if (showEdit) {
                viewMode.style.display = 'none';
                editMode.style.display = 'block';
                editMode.style.animation = 'fadeInUp 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards';
            } else {
                viewMode.style.display = 'block';
                editMode.style.display = 'none';
                viewMode.style.animation = 'fadeInUp 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards';
            }
        }
    </script>

</body>
</html>