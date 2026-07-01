<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User u = (User) session.getAttribute("user");
    if (u == null || !"R003".equals(u.getRoleId())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    String roleId = (u.getRoleId() != null) ? u.getRoleId() : "R003";
    String roleClass = "role-" + roleId;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Dashboard | NumSolve</title>
    
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

            /* Card Accent Colors */
            --blue: #3b82f6;     --blue-glow: rgba(59, 130, 246, 0.12);
            --green: #10b981;    --green-glow: rgba(16, 185, 129, 0.12);
            --orange: #f97316;   --orange-glow: rgba(249, 115, 22, 0.12);
            --purple: #8b5cf6;   --purple-glow: rgba(139, 92, 246, 0.12);
            --red: #ef4444;      --red-glow: rgba(239, 68, 68, 0.12);
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
            overflow-x: hidden;
            overflow-y: auto;
        }

        /* --- ENTRANCE ANIMATIONS --- */
        @keyframes dropDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(30px) scale(0.98); } to { opacity: 1; transform: translateY(0) scale(1); } }
        
        .animated-nav { animation: dropDown 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .animated-panel { animation: fadeInUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.15s; }
        .delay-2 { animation-delay: 0.3s; }

        /* --- FLOATING GLASS NAV (MATCHED EXACTLY TO RECOMMENDATION.JSP) --- */
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

        /* --- MAIN CONTENT & HEADER --- */
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1400px; width: 100%; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 40px; 
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); padding: 30px 40px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
            gap: 20px;
        }
        .header-area h2 { font-size: 2.2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area p { color: var(--gray); font-size: 1.1rem; margin-top: 5px; font-weight: 500;}

        .user-profile {
            display: flex; align-items: center; gap: 14px; background: var(--white);
            padding: 8px 20px 8px 8px; border-radius: 50px; box-shadow: 0 8px 20px rgba(0,0,0,0.04);
            border: 1px solid var(--border); transition: var(--transition);
        }
        .user-profile:hover { box-shadow: var(--shadow-hover); transform: translateY(-3px); border-color: var(--primary); }
        .user-profile span { font-weight: 700; color: var(--dark); font-size: 0.95rem; white-space: nowrap; }
        
        .avatar {
            width: 45px; height: 45px; border-radius: 50%; background: var(--primary); color: var(--white); 
            display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 1.2rem; 
            overflow: hidden; box-shadow: 0 4px 10px var(--primary-glow); flex-shrink: 0;
        }
        .avatar img { width: 100%; height: 100%; object-fit: cover; }
        .profile-link { text-decoration: none; }

        /* --- DASHBOARD CARDS --- */
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 30px; }

        .card {
            background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(10px); padding: 35px; border-radius: var(--radius);
            box-shadow: var(--shadow); transition: var(--transition); display: flex; flex-direction: column; align-items: flex-start; 
            position: relative; border: 1px solid var(--border); overflow: hidden;
        }
        .card:hover { transform: translateY(-10px); box-shadow: var(--shadow-hover); border-color: transparent; }
        .card::before { content: ''; position: absolute; inset: 0; opacity: 0; transition: var(--transition); z-index: 1; }
        .card:hover::before { opacity: 1; }

        .icon-box {
            width: 65px; height: 65px; border-radius: 16px; display: flex; align-items: center; justify-content: center;
            font-size: 2rem; margin-bottom: 25px; transition: var(--transition); position: relative; z-index: 2;
        }
        .card:hover .icon-box { transform: scale(1.15) rotate(5deg); }

        .card h3 { font-size: 1.4rem; color: var(--dark); margin-bottom: 12px; font-weight: 800; z-index: 2; position: relative; }
        .card p { color: var(--gray); font-size: 1rem; margin-bottom: 30px; line-height: 1.6; flex-grow: 1; z-index: 2; position: relative; font-weight: 500;}

        /* --- BUTTONS --- */
        .btn {
            padding: 14px 25px; border-radius: 12px; font-weight: 700; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; width: 100%; z-index: 2; position: relative;
        }
        .btn i { font-size: 1.2rem; transition: var(--transition); }
        .btn:hover i { transform: translateX(5px); }

        /* Themes */
        .card-blue::before { background: var(--blue-glow); } .card-blue .icon-box { background: var(--blue-glow); color: var(--blue); }
        .btn-primary { background: var(--primary); color: var(--white); box-shadow: 0 8px 15px var(--primary-glow); }
        .btn-primary:hover { background: var(--primary-hover); transform: translateY(-3px); box-shadow: 0 12px 20px rgba(59, 130, 246, 0.4); }

        .card-purple::before { background: var(--purple-glow); } .card-purple .icon-box { background: var(--purple-glow); color: var(--purple); }
        .btn-purple { background: var(--purple); color: var(--white); box-shadow: 0 8px 15px rgba(139, 92, 246, 0.3); }
        .btn-purple:hover { background: #7c3aed; transform: translateY(-3px); box-shadow: 0 12px 20px rgba(139, 92, 246, 0.4); }

        .card-orange::before { background: var(--orange-glow); } .card-orange .icon-box { background: var(--orange-glow); color: var(--orange); }
        .btn-orange { background: var(--orange); color: var(--white); box-shadow: 0 8px 15px rgba(249, 115, 22, 0.3); }
        .btn-orange:hover { background: #ea580c; transform: translateY(-3px); box-shadow: 0 12px 20px rgba(249, 115, 22, 0.4); }

        .card-green::before { background: var(--green-glow); } .card-green .icon-box { background: var(--green-glow); color: var(--green); }
        .btn-green { background: var(--green); color: var(--white); box-shadow: 0 8px 15px rgba(16, 185, 129, 0.3); }
        .btn-green:hover { background: #059669; transform: translateY(-3px); box-shadow: 0 12px 20px rgba(16, 185, 129, 0.4); }

        .card-red::before { background: var(--red-glow); } .card-red .icon-box { background: var(--red-glow); color: var(--red); }
        .btn-red { background: var(--red); color: var(--white); box-shadow: 0 8px 15px rgba(239, 68, 68, 0.3); }
        .btn-red:hover { background: #dc2626; transform: translateY(-3px); box-shadow: 0 12px 20px rgba(239, 68, 68, 0.4); }

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
            .header-area { flex-direction: column; align-items: flex-start; padding: 25px 30px; }
        }

        /* Mobile Breakpoint: Stacked Layout & Adjustments */
        @media (max-width: 768px) {
            .top-nav { flex-direction: column; gap: 15px; border-radius: 25px; padding: 15px 20px; width: 92%; }
            .brand { justify-content: center; width: 100%; }
            .nav-menu { flex-direction: row; flex-wrap: wrap; justify-content: center; width: 100%; gap: 8px; }
            
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
            
            .header-area h2 { font-size: 1.6rem; }
            .header-area p { font-size: 0.95rem; }
            .grid { grid-template-columns: 1fr; gap: 20px; }
            .card { padding: 25px; }
        }
    </style>
</head>
<body class="<%= roleClass %>">

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            <li><a href="${pageContext.request.contextPath}/dashboard/student.jsp" class="nav-link active"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
            <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
            <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
            <li><a href="${pageContext.request.contextPath}/student_classes.jsp" class="nav-link"><i class='bx bxs-group'></i> <span>Classes</span></a></li>            
            <li><a href="${pageContext.request.contextPath}/StudentDashboardServlet" class="nav-link"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
            <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
        </ul>
    </nav>

    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <div>
                <h2>Hello, <%= u.getFullName() %> <span style="font-size: 2.5rem;">👋</span></h2>
                <p>Welcome to your intelligent learning space. What are we calculating today?</p>
            </div>
            <a href="${pageContext.request.contextPath}/profile.jsp" class="profile-link">
                <div class="user-profile">
                    <div class="avatar">
                        <% if(u.getPhotoPath() != null && !u.getPhotoPath().isEmpty()) { %>
                            <img src="${pageContext.request.contextPath}/<%= u.getPhotoPath() %>" alt="Profile">
                        <% } else { %>
                            <%= u.getFullName().charAt(0) %>
                        <% } %>
                    </div>
                    <span><%= u.getFullName() %></span>
                </div>
            </a>
        </div>

        <div class="grid animated-panel delay-2">
            
            <div class="card card-blue">
                <div class="icon-box"><i class='bx bxs-calculator'></i></div>
                <h3>Quick Compute</h3>
                <p>Start a new numerical analysis calculation and get step-by-step solutions instantly.</p>
                <a href="${pageContext.request.contextPath}/solver.jsp" class="btn btn-primary">Start Calculation <i class='bx bx-right-arrow-alt'></i></a>
            </div>
            
            <div class="card card-purple">
                <div class="icon-box"><i class='bx bxs-bulb'></i></div>
                <h3>Recommend Engine</h3>
                <p>Not sure which method to use? Let our intelligent system find the best approach.</p>
                <a href="${pageContext.request.contextPath}/recommendation.jsp" class="btn btn-purple">Find Method <i class='bx bx-right-arrow-alt'></i></a>
            </div>
            
            <div class="card card-orange">
                <div class="icon-box"><i class='bx bxs-edit'></i></div>
                <h3>Active Missions</h3>
                <p>Test your knowledge by completing public challenges or class-assigned missions.</p>
                <a href="${pageContext.request.contextPath}/StudentDashboardServlet" class="btn btn-orange">View Missions <i class='bx bx-right-arrow-alt'></i></a>
            </div>

            <div class="card card-blue">
                <div class="icon-box"><i class='bx bxs-group'></i></div>
                <h3>My Classes</h3>
                <p>Access your enrolled classrooms, view class resources, and manage pending assignments.</p>
                <a href="${pageContext.request.contextPath}/student_classes.jsp" class="btn btn-primary">Open Classes <i class='bx bx-right-arrow-alt'></i></a>
            </div>

            <div class="card card-green">
                <div class="icon-box"><i class='bx bxs-book-reader'></i></div>
                <h3>Learning Library</h3>
                <p>Browse PDF notes, interactive video tutorials, and highly-rated educational resources.</p>
                <a href="${pageContext.request.contextPath}/materials.jsp" class="btn btn-green">Browse Library <i class='bx bx-right-arrow-alt'></i></a>
            </div>
            
            <div class="card card-red">
                <div class="icon-box"><i class='bx bxs-time-five'></i></div>
                <h3>Past Records</h3>
                <p>Review your past calculation ledger and track your learning progress over time.</p>
                <a href="${pageContext.request.contextPath}/computations.jsp" class="btn btn-red">View Ledger <i class='bx bx-right-arrow-alt'></i></a>
            </div>
        </div>
    </main>
</body>
</html>