<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User u = (User) session.getAttribute("user");
    if (u == null || !"R001".equals(u.getRoleId())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard – NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES (Admin Theme - Red) --- */
        :root {
            --primary: #ef4444;         
            --primary-hover: #dc2626;
            --primary-glow: rgba(239, 68, 68, 0.3);
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
            --cyan: #0ea5e9;     --cyan-glow: rgba(14, 165, 233, 0.12);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 50%, #fecaca 100%);
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

        /* --- FLOATING GLASS NAV --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 25px auto;
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
            padding: 12px 25px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: 0 15px 35px rgba(239, 68, 68, 0.08);
            border: 1px solid var(--border); z-index: 100; position: sticky; top: 25px;
            flex-wrap: wrap; gap: 15px;
        }

        .brand { 
            font-size: 1.4rem; font-weight: 800; display: flex; align-items: center; gap: 10px; white-space: nowrap;
            background: linear-gradient(135deg, #ef4444, #f97316); -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }
        .brand i { color: var(--primary); -webkit-text-fill-color: initial; font-size: 1.8rem; }
        
        .nav-menu { list-style: none; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; justify-content: center; }

        .nav-link {
            display: flex; align-items: center; gap: 10px; padding: 10px; 
            border-radius: 40px; color: var(--gray); 
            font-weight: 600; font-size: 0.95rem; text-decoration: none; 
            max-width: 44px; white-space: nowrap; overflow: hidden;
            transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
        }

        .nav-link i { font-size: 1.4rem; min-width: 24px; text-align: center; }
        .nav-link span { opacity: 0; transform: translateX(-10px); transition: all 0.3s ease; }

        .nav-link:hover { 
            background: rgba(255, 255, 255, 0.9); 
            color: var(--primary); 
            max-width: 160px; padding: 10px 20px; 
        }
        .nav-link:hover span { opacity: 1; transform: translateX(0); }
        
        .nav-link.active {
            background: var(--primary); color: var(--white);
            box-shadow: 0 8px 20px var(--primary-glow);
            max-width: 160px; padding: 10px 20px;
        }
        .nav-link.active span { opacity: 1; transform: translateX(0); }

        .logout-item { margin-left: 10px; border-left: 1px solid var(--border); padding-left: 10px; }
        .logout-item .nav-link:hover { background: rgba(239, 68, 68, 0.1); color: #ef4444; }

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

        /* Card Themes */
        .card-cyan::before { background: var(--cyan-glow); } .card-cyan .icon-box { background: var(--cyan-glow); color: var(--cyan); }
        .btn-cyan { background: var(--cyan); color: var(--white); }

        .card-blue::before { background: var(--blue-glow); } .card-blue .icon-box { background: var(--blue-glow); color: var(--blue); }
        .btn-blue { background: var(--blue); color: var(--white); }

        .card-orange::before { background: var(--orange-glow); } .card-orange .icon-box { background: var(--orange-glow); color: var(--orange); }
        .btn-orange { background: var(--orange); color: var(--white); }

        .card-red::before { background: var(--red-glow); } .card-red .icon-box { background: var(--red-glow); color: var(--red); }
        .btn-red { background: var(--red); color: var(--white); }

        .card-purple::before { background: var(--purple-glow); } .card-purple .icon-box { background: var(--purple-glow); color: var(--purple); }
        .btn-purple { background: var(--purple); color: var(--white); }

        .card-green::before { background: var(--green-glow); } .card-green .icon-box { background: var(--green-glow); color: var(--green); }
        .btn-green { background: var(--green); color: var(--white); }

        /* --- MASTER TEMPLATE RESPONSIVENESS --- */
        @media (max-width: 1024px) {
            .nav-menu .nav-link span { display: none; }
            .nav-menu .nav-link { max-width: 44px; padding: 10px; }
            .header-area { flex-direction: column; align-items: flex-start; gap: 20px; padding: 25px 30px; }
        }

        @media (max-width: 768px) {
            .top-nav { flex-direction: column; justify-content: center; border-radius: 20px; top: 10px; padding: 15px; }
            .brand { width: 100%; justify-content: center; margin-bottom: 5px; }
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
            
            .header-area h2 { font-size: 1.8rem; }
            .user-profile { align-self: flex-start; }
        }

        /* Ultra-mobile specific tweaks for the dashboard */
        @media (max-width: 480px) {
            .header-area { padding: 20px; }
            .header-area h2 { font-size: 1.6rem; }
            .header-area p { font-size: 0.95rem; }
            
            /* Safe grid layout for small screens */
            .grid { grid-template-columns: 1fr; gap: 20px; }
            .card { padding: 25px; width: 100%; max-width: 100%; }
        }
    </style>
</head>
<body>

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-shield-x'></i> NumSolve Admin</div>
        <ul class="nav-menu">
            <li><a href="${pageContext.request.contextPath}/admin/admin.jsp" class="nav-link active"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="${pageContext.request.contextPath}/admin/admin_materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="${pageContext.request.contextPath}/users.jsp" class="nav-link"><i class='bx bxs-user-account'></i> <span>Users</span></a></li>
            <li><a href="${pageContext.request.contextPath}/logs.jsp" class="nav-link"><i class='bx bxs-server'></i> <span>Logs</span></a></li>
            <li><a href="${pageContext.request.contextPath}/reports.jsp" class="nav-link"><i class='bx bxs-chart'></i> <span>Reports</span></a></li>
            <li><a href="${pageContext.request.contextPath}/admin_quizzes.jsp" class="nav-link"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
            <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
        </ul>
    </nav>
    
    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <div>
                <h2>Hello, Administrator <%= u.getFullName() %> <span style="font-size: 2.5rem;">⚙️</span></h2>
                <p>Welcome to the System Control Center. Everything is running smoothly.</p>
            </div>
            <a href="${pageContext.request.contextPath}/profile.jsp" class="profile-link">
                <div class="user-profile">
                    <div class="avatar">
                        <%= u.getFullName().charAt(0) %>
                    </div>
                    <span><%= u.getFullName() %></span>
                </div>
            </a>
        </div>

        <div class="grid animated-panel delay-2">
            
            <div class="card card-cyan">
                <div class="icon-box"><i class='bx bxs-book-reader'></i></div>
                <h3>System Materials</h3>
                <p>Audit and manage all public and private learning resources across the platform.</p>
                <a href="${pageContext.request.contextPath}/admin/admin_materials.jsp" class="btn btn-cyan">Manage Resources <i class='bx bx-right-arrow-alt'></i></a>
            </div>

            <div class="card card-blue">
                <div class="icon-box"><i class='bx bxs-user-detail'></i></div>
                <h3>User Management</h3>
                <p>Manage accounts for Students and Educators. Verify credentials and adjust roles.</p>
                <a href="${pageContext.request.contextPath}/users.jsp" class="btn btn-blue">Manage Accounts <i class='bx bx-right-arrow-alt'></i></a>
            </div>

            <div class="card card-orange">
                <div class="icon-box"><i class='bx bx-list-ul'></i></div>
                <h3>System Logs</h3>
                <p>Monitor security events, login attempts, and critical system activities in real-time.</p>
                <a href="${pageContext.request.contextPath}/logs.jsp" class="btn btn-orange">View System Logs <i class='bx bx-right-arrow-alt'></i></a>
            </div>

            <div class="card card-red">
                <div class="icon-box"><i class='bx bxs-report'></i></div>
                <h3>Report Analysis</h3>
                <p>Generate registration stats, material growth trends, and overall platform analytics.</p>
                <a href="${pageContext.request.contextPath}/reports.jsp" class="btn btn-red">Analyze Data <i class='bx bx-right-arrow-alt'></i></a>
            </div>

            <div class="card card-purple">
                <div class="icon-box"><i class='bx bxs-edit'></i></div>
                <h3>Quiz Oversight</h3>
                <p>Monitor all active evaluations and quizzes deployed by educators in the system.</p>
                <a href="${pageContext.request.contextPath}/admin_quizzes.jsp" class="btn btn-purple">View Evaluations <i class='bx bx-right-arrow-alt'></i></a>
            </div>

            <div class="card card-green">
                <div class="icon-box"><i class='bx bxs-user-circle'></i></div>
                <h3>Admin Profile</h3>
                <p>Update your administrative credentials, change password, and manage your settings.</p>
                <a href="${pageContext.request.contextPath}/profile.jsp" class="btn btn-green">Go to Profile <i class='bx bx-right-arrow-alt'></i></a>
            </div>

        </div>
    </main>
</body>
</html>