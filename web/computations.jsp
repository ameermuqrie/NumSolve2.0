<%-- 
    Document   : computations
    Created on : 23 Feb 2026, 11:08:22 PM
    Author     : Asus
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="dao.ComputationDAO, model.Computation, model.User, java.util.*" %>
<%
    // 1. Security Check: Ensure user is logged in
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    User u = (User) session.getAttribute("user");
    if (u == null) { 
        // Absolute redirect path for safety
        response.sendRedirect(request.getContextPath() + "/login.jsp"); 
        return; 
    }

    // 2. Fetch data using our secure DAO
    ComputationDAO compDao = new ComputationDAO();
    List<Computation> historyList = compDao.getComputationsByUser(u.getUserId());
    
    // 3. Set Role Class for Dynamic Theming (Safe fallback if roleId is missing)
    String roleId = (u.getRoleId() != null) ? u.getRoleId() : "R003";
    String roleClass = "role-" + roleId;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Computations | NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES & DYNAMIC ROLE THEMING (GLASSMORPHISM) --- */
        :root {
            --dark: #0f172a;
            --white: #ffffff;
            --gray: #64748b;
            --border: rgba(255, 255, 255, 0.4);
            --shadow: 0 10px 30px rgba(0,0,0,0.05);
            --shadow-hover: 0 20px 40px rgba(0,0,0,0.1);
            --transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
            --radius: 20px;
        }

        /* Default (Admin - Red Glass) */
        body.role-R001 { 
            --primary: #ef4444; --primary-hover: #dc2626; --primary-glow: rgba(239, 68, 68, 0.3);
            --bg-1: #fee2e2; --bg-2: #fecaca; --bg-3: #fca5a5;
            --nav-hover: rgba(239, 68, 68, 0.1);
        }
        /* Educator - Purple Glass */
        body.role-R002 { 
            --primary: #8b5cf6; --primary-hover: #7c3aed; --primary-glow: rgba(139, 92, 246, 0.3);
            --bg-1: #ede9fe; --bg-2: #ddd6fe; --bg-3: #c4b5fd;
            --nav-hover: rgba(139, 92, 246, 0.1);
        }
        /* Student - Blue Glass */
        body.role-R003 { 
            --primary: #3b82f6; --primary-hover: #2563eb; --primary-glow: rgba(59, 130, 246, 0.3);
            --bg-1: #dbeafe; --bg-2: #bfdbfe; --bg-3: #93c5fd;
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
        }

        /* --- ENTRANCE ANIMATIONS --- */
        @keyframes dropDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(30px) scale(0.98); } to { opacity: 1; transform: translateY(0) scale(1); } }
        
        .animated-nav { animation: dropDown 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .animated-panel { animation: fadeInUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.15s; }
        .delay-2 { animation-delay: 0.3s; }

        /* --- FLOATING GLASS NAV (MATCHED TO REFERENCE) --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 25px auto;
            background: rgba(255, 255, 255, 0.5); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
            padding: 12px 25px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: 0 15px 35px var(--primary-glow);
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

        /* --- DESKTOP BEHAVIOR (Expanding Links) --- */
        .nav-link {
            display: flex; align-items: center; gap: 10px; padding: 10px; 
            border-radius: 40px; color: var(--gray); 
            font-weight: 600; font-size: 0.95rem; text-decoration: none; 
            max-width: 44px; white-space: nowrap; overflow: hidden;
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

        /* --- MAIN CONTENT & HEADER (COMPUTATIONS SPECIFIC) --- */
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1100px; width: 100%; margin: 0 auto; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; 
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); padding: 30px 40px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
            gap: 20px;
        }
        .header-area h2 { font-size: 2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area p { color: var(--gray); font-size: 1.05rem; margin-top: 5px; font-weight: 500;}

        /* --- ACTIONS & SEARCH --- */
        .header-actions {
            display: flex; justify-content: space-between; align-items: center; 
            margin-bottom: 25px; gap: 15px; flex-wrap: wrap;
        }

        /* Glass Search Bar */
        .search-wrapper { position: relative; width: 100%; max-width: 350px; }
        .search-wrapper i {
            position: absolute; left: 18px; top: 50%; transform: translateY(-50%);
            color: var(--gray); font-size: 1.2rem; transition: var(--transition);
        }
        .search-input {
            width: 100%; padding: 14px 20px 14px 45px; 
            border: 1px solid rgba(255, 255, 255, 0.6); 
            border-radius: 30px; font-size: 0.95rem; font-weight: 500; outline: none; transition: var(--transition);
            background: rgba(241, 245, 249, 0.4); color: var(--dark);
            box-shadow: inset 0 4px 8px rgba(0,0,0,0.03); 
        }
        .search-input::placeholder { color: #94a3b8; }
        .search-input:hover { background: rgba(255, 255, 255, 0.5); }
        .search-input:focus { 
            border-color: rgba(255, 255, 255, 0.9); 
            background: rgba(255, 255, 255, 0.8); 
            box-shadow: 0 10px 30px var(--primary-glow), 0 0 0 3px rgba(255, 255, 255, 0.5);
        }
        .search-input:focus + i { color: var(--primary); }

        .btn-group { display: flex; gap: 15px; }
        
        /* Premium Buttons */
        .btn {
            padding: 12px 22px; border-radius: 30px; font-weight: 700; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; position: relative;
        }
        .btn i { font-size: 1.2rem; transition: var(--transition); }
        .btn:hover i { transform: translateX(3px); }

        .btn-primary { 
            background-color: var(--primary); 
            background-image: linear-gradient(135deg, rgba(255,255,255,0.2) 0%, rgba(255,255,255,0) 100%);
            color: var(--white); 
            box-shadow: 0 8px 25px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.4); 
            border: 1px solid rgba(255, 255, 255, 0.2); backdrop-filter: blur(10px);
        }
        .btn-primary:hover { 
            background-color: var(--primary-hover); transform: translateY(-3px); 
            box-shadow: 0 12px 30px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.6); 
        }
        
        .btn-ai { 
            background-color: #8b5cf6; 
            background-image: linear-gradient(135deg, rgba(255,255,255,0.2) 0%, rgba(255,255,255,0) 100%);
            color: white; box-shadow: 0 8px 25px rgba(139, 92, 246, 0.3), inset 0 1px 0 rgba(255, 255, 255, 0.4); 
            border: 1px solid rgba(255, 255, 255, 0.2); backdrop-filter: blur(10px);
        }
        .btn-ai:hover { 
            background-color: #7c3aed; transform: translateY(-3px); 
            box-shadow: 0 12px 30px rgba(139, 92, 246, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.6); 
        }

        /* --- GLASS DATA TABLE --- */
        .glass-card { 
            background: rgba(255, 255, 255, 0.65); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
            border-radius: var(--radius); box-shadow: var(--shadow); 
            border: 1px solid var(--border); overflow: hidden;
            transition: var(--transition);
        }
        .glass-card:hover { box-shadow: var(--shadow-hover); }

        .data-table { width: 100%; border-collapse: collapse; text-align: left; }
        .data-table th { 
            background: rgba(255, 255, 255, 0.4); padding: 18px 25px; font-weight: 700; 
            color: var(--dark); font-size: 0.9rem; text-transform: uppercase; 
            letter-spacing: 0.5px; border-bottom: 1px solid rgba(0,0,0,0.05);
        }
        .data-table td { 
            padding: 18px 25px; border-bottom: 1px solid rgba(255,255,255,0.3); 
            vertical-align: middle; transition: var(--transition);
        }
        
        .data-table tbody tr { transition: var(--transition); }
        .data-table tbody tr:hover { background: rgba(255, 255, 255, 0.9); }
        .data-table tbody tr:last-child td { border-bottom: none; }
        
        .badge {
            padding: 6px 12px; border-radius: 8px; font-size: 0.85rem; font-weight: 700;
            background-color: rgba(255, 255, 255, 0.7); color: var(--primary); 
            display: inline-block; border: 1px solid rgba(255, 255, 255, 0.9);
            box-shadow: 0 2px 5px rgba(0,0,0,0.02);
        }

        .action-btn {
            width: 38px; height: 38px; border-radius: 10px; display: inline-flex; 
            align-items: center; justify-content: center; text-decoration: none; 
            font-size: 1.3rem; transition: var(--transition); margin-right: 6px;
            background: rgba(255, 255, 255, 0.5); border: 1px solid rgba(255, 255, 255, 0.8);
        }
        .btn-view { color: var(--primary); }
        .btn-view:hover { background: var(--primary); color: var(--white); transform: translateY(-2px); box-shadow: 0 5px 15px var(--primary-glow); border-color: transparent;}
        
        .btn-delete { color: #ef4444; }
        .btn-delete:hover { background: #ef4444; color: var(--white); transform: translateY(-2px); box-shadow: 0 5px 15px rgba(239, 68, 68, 0.3); border-color: transparent;}

        .user-info p { margin: 0; line-height: 1.4; }

        /* --- RESPONSIVE MEDIA QUERIES --- */
        
        /* Tablet Breakpoint: Strict Icon-Based Navigation */
        @media (max-width: 1024px) {
            .nav-link span { display: none !important; }
            .nav-link:hover, .nav-link.active { 
                max-width: 44px; /* Prevent expansion */
                padding: 10px; 
                justify-content: center; 
            }
            .nav-link i { margin: 0; }
            
            .header-area { flex-direction: column; align-items: flex-start; gap: 20px; padding: 25px 30px; }
            .header-actions { flex-direction: column; align-items: stretch; }
            .search-wrapper { max-width: 100%; }
            .btn-group { flex-direction: column; }
        }

        /* Mobile Breakpoint: Stacked Layout & Adjustments */
        @media (max-width: 768px) {
            .top-nav { flex-direction: column; gap: 15px; border-radius: 25px; padding: 15px 20px; width: 92%; }
            .brand { justify-content: center; width: 100%; }
            .nav-menu { flex-direction: row; flex-wrap: wrap; justify-content: center; width: 100%; gap: 8px; }
            
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
            
            .header-area { flex-direction: column; align-items: flex-start; padding: 20px; }
            .header-area h2 { font-size: 1.8rem; }
            .user-info { width: 100%; text-align: left; }

            /* Responsive Table Conversion for Mobile */
            .glass-card { padding: 10px; background: transparent; border: none; box-shadow: none; }
            .data-table thead { display: none; }
            .data-table, .data-table tbody, .data-table tr, .data-table td { display: block; width: 100%; }
            .data-table tr { 
                margin-bottom: 15px; border-radius: var(--radius); 
                background: rgba(255, 255, 255, 0.65); backdrop-filter: blur(12px);
                border: 1px solid var(--border); box-shadow: var(--shadow);
                padding: 10px 0;
            }
            .data-table td { 
                text-align: right; padding-left: 45%; position: relative; 
                border-bottom: 1px solid rgba(255,255,255,0.2); 
                padding-top: 12px; padding-bottom: 12px;
            }
            .data-table td:last-child { border-bottom: none; text-align: center; padding-left: 25px; }
            .data-table td::before { 
                content: attr(data-label); position: absolute; left: 20px; width: 40%; 
                text-align: left; font-weight: 700; color: var(--dark); font-size: 0.85rem; text-transform: uppercase;
            }
        }
    </style>
</head>

<body class="<%= roleClass %>">

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            
            <%-- Admin (R001) Links --%>
            <% if ("R001".equals(roleId)) { %>
                <li><a href="${pageContext.request.contextPath}/dashboard/admin.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="${pageContext.request.contextPath}/users.jsp" class="nav-link"><i class='bx bxs-user-account'></i> <span>Users</span></a></li>
                <li><a href="${pageContext.request.contextPath}/logs.jsp" class="nav-link"><i class='bx bxs-server'></i> <span>Logs</span></a></li>
                <li><a href="${pageContext.request.contextPath}/reports.jsp" class="nav-link"><i class='bx bxs-chart'></i> <span>Reports</span></a></li>
                <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>

            <%-- Educator (R002) Links --%>
            <% } else if ("R002".equals(roleId)) { %>
                <li><a href="${pageContext.request.contextPath}/dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link active"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                <li><a href="${pageContext.request.contextPath}/manage_classes.jsp" class="nav-link"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
                <li><a href="${pageContext.request.contextPath}/educatorQuizzes" class="nav-link"><i class='bx bx-task'></i><span>Quizzes</span></a></li>
                <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
                
            <%-- Student (R003) Links --%>
            <% } else { %>
                <li><a href="${pageContext.request.contextPath}/dashboard/student.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link active"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                <li><a href="${pageContext.request.contextPath}/student_classes.jsp" class="nav-link"><i class='bx bxs-group'></i> <span>Classes</span></a></li>            
                <li><a href="${pageContext.request.contextPath}/StudentDashboardServlet" class="nav-link"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
                <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
            <% } %>
            
        </ul>
    </nav>

    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <div>
                <h2><i class='bx bxs-folder-open' style="color: var(--primary);"></i> My Computations</h2>
                <p>View, manage, and revisit your past numerical analyses</p>
            </div>
            
            <div class="user-info" style="text-align: right; background: rgba(255,255,255,0.5); padding: 10px 20px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.8);">
                <p style="font-weight: 700; color: var(--dark); font-size: 1.1rem;"><%= u.getFullName() %></p>
                <p style="font-size: 0.9rem; color: var(--gray); font-weight: 500;">ID: <%= u.getUserId() %></p>
            </div>
        </div>

        <div class="header-actions animated-panel delay-1">
            <div class="search-wrapper">
                <input type="text" id="searchInput" class="search-input" placeholder="Search by title or method..." onkeyup="filterTable()">
                <i class='bx bx-search'></i>
            </div>

            <div class="btn-group">
                <a href="${pageContext.request.contextPath}/recommendation.jsp" class="btn btn-ai">
                    <i class='bx bx-brain'></i> AI Advisor
                </a>
                <a href="${pageContext.request.contextPath}/solver.jsp" class="btn btn-primary">
                    <i class='bx bx-plus-circle'></i> New Computation
                </a>
            </div>
        </div>

        <div class="glass-card animated-panel delay-2">
            <table class="data-table" id="historyTable">
                <thead>
                    <tr>
                        <th width="15%">Date</th>
                        <th width="35%">Title / Equation</th>
                        <th width="15%">Method</th>
                        <th width="20%">Result</th>
                        <th width="15%" style="text-align: center;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (historyList.isEmpty()) { %>
                        <tr>
                            <td colspan="5" style="text-align:center; padding: 60px 20px; color: var(--gray);">
                                <div style="background: rgba(255,255,255,0.6); display: inline-block; padding: 25px; border-radius: 50%; margin-bottom: 15px; box-shadow: inset 0 4px 8px rgba(0,0,0,0.03);">
                                    <i class='bx bx-folder-open' style="font-size: 3.5rem; color: var(--primary); opacity: 0.7;"></i>
                                </div>
                                <h3 style="color: var(--dark); margin-bottom: 5px; font-weight: 800;">No Computations Yet</h3>
                                <p style="font-weight: 500;">Click "New Computation" to run your first numerical method.</p>
                            </td>
                        </tr>
                    <% } else { 
                        for(Computation c : historyList) { 
                    %>
                        <tr>
                            <td data-label="Date" style="color: var(--gray); font-size: 0.9rem; font-weight: 500;">
                                <i class='bx bx-calendar' style="vertical-align: middle; margin-right: 5px; color: var(--primary);"></i>
                                <%= c.getComputationDate() %>
                            </td>
                            <td data-label="Equation">
                                <div style="font-weight: 700; color: var(--dark); font-size: 1.05rem; letter-spacing: -0.3px;"><%= c.getDisplayTitle() %></div>
                                <div style="font-size: 0.85rem; color: var(--gray); font-family: monospace; margin-top: 6px; background: rgba(255,255,255,0.7); padding: 4px 10px; border-radius: 6px; display: inline-block; border: 1px solid rgba(255,255,255,0.9);">
                                    <%= c.getDisplayInputData() %>
                                </div>
                            </td>
                            <td data-label="Method"><span class="badge"><%= c.getMethodId() %></span></td>
                            <td data-label="Result" style="font-weight: 700; color: #059669; font-size: 1.05rem;">
                                <%= c.getResult() != null ? c.getResult() : "Processing..." %>
                            </td>
                            <td data-label="Actions" style="text-align: center;">
                                <a href="${pageContext.request.contextPath}/EditComputationServlet?id=<%= c.getComputationId() %>" class="action-btn btn-view" title="Load into Solver">
                                    <i class='bx bx-refresh'></i>
                                </a>
                                <a href="${pageContext.request.contextPath}/view_computation.jsp?id=<%= c.getComputationId() %>" class="action-btn btn-view" title="View Report & Export">
                                    <i class='bx bx-file'></i>
                                </a>
                                <a href="${pageContext.request.contextPath}/delete_computation?id=<%= c.getComputationId() %>" class="action-btn btn-delete" title="Delete" onclick="return confirm('Are you sure? This cannot be undone.');">
                                    <i class='bx bx-trash'></i>
                                </a>
                            </td>
                        </tr>
                    <%  } 
                       } %>
                </tbody>
            </table>
        </div>

    </main>

<script>
    // Simple frontend search filter for the table
    function filterTable() {
        var input = document.getElementById("searchInput");
        var filter = input.value.toUpperCase();
        var table = document.getElementById("historyTable");
        var tr = table.getElementsByTagName("tr");

        // Loop through all table rows (excluding headers)
        for (var i = 1; i < tr.length; i++) {
            var tdTitle = tr[i].getElementsByTagName("td")[1]; // Title / Equation column
            var tdMethod = tr[i].getElementsByTagName("td")[2]; // Method column
            
            if (tdTitle || tdMethod) {
                var txtTitle = tdTitle.textContent || tdTitle.innerText;
                var txtMethod = tdMethod.textContent || tdMethod.innerText;
                
                if (txtTitle.toUpperCase().indexOf(filter) > -1 || txtMethod.toUpperCase().indexOf(filter) > -1) {
                    tr[i].style.display = "";
                } else {
                    tr[i].style.display = "none";
                }
            }       
        }
    }
</script>
</body>
</html>