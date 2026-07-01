<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*, model.*, dao.*" %>
<%
    // 1. Security & Cache Control
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    if (u == null) { response.sendRedirect("login.jsp"); return; }
    
    // 2. Get Filters
    String keyword = request.getParameter("keyword");
    String type = request.getParameter("type");
    String classIdStr = request.getParameter("classId");
    
    // 3. Smart Context Routing (Public vs Private)
    LearningMaterialDAO dao = new LearningMaterialDAO();
    List<LearningMaterial> list;
    boolean isPrivate = false;
    
    if (classIdStr != null && !classIdStr.trim().isEmpty()) {
        
        int classId = Integer.parseInt(classIdStr);
        list = dao.getClassMaterialsSecure(classId, u.getUserId(), u.getRoleId());
        isPrivate = true;
        request.setAttribute("isPrivate", true);
        request.setAttribute("classId", classId);
    } else {
        // PUBLIC MODE: Fetch global open-source files
        list = dao.getPublicMaterials(keyword, type);
        request.setAttribute("isPrivate", false);
    }
    
    // 4. Set Role Class (Used for dynamic CSS styling)
    String roleClass = "role-" + u.getRoleId();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isPrivate ? "Class Materials" : "Public Library" %> | NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        
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

        
        body.role-R001 { 
            --primary: #ef4444; --primary-hover: #dc2626; --primary-glow: rgba(239, 68, 68, 0.3);
            --bg-1: #fee2e2; --bg-2: #fecaca; --bg-3: #fca5a5;
        }
        
        body.role-R002 { 
            --primary: #8b5cf6; --primary-hover: #7c3aed; --primary-glow: rgba(139, 92, 246, 0.3);
            --bg-1: #ede9fe; --bg-2: #ddd6fe; --bg-3: #c4b5fd;
        }
        /* Student - Blue Glass */
        body.role-R003 { 
            --primary: #3b82f6; --primary-hover: #2563eb; --primary-glow: rgba(59, 130, 246, 0.3);
            --bg-1: #dbeafe; --bg-2: #bfdbfe; --bg-3: #93c5fd;
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

        
        @keyframes dropDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(30px) scale(0.98); } to { opacity: 1; transform: translateY(0) scale(1); } }
        
        .animated-nav { animation: dropDown 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .animated-panel { animation: fadeInUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }
        
       
        .nav-wrapper { width: 100%; }

        /* --- UPGRADED FLOATING GLASS NAV CSS --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 25px auto;
            background: rgba(255, 255, 255, 0.5); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
            padding: 12px 25px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: 0 15px 35px var(--primary-glow);
            border: 1px solid var(--border); z-index: 100; position: sticky; top: 25px;
            gap: 20px; transition: var(--transition);
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
        .logout-item .nav-link:hover { background: rgba(239, 68, 68, 0.1); color: #ef4444; }

        
        .back-btn-private { 
            display: flex; align-items: center; gap: 8px; font-weight: 600; color: var(--gray); text-decoration: none; 
            padding: 10px 20px; border-radius: 30px; background: rgba(255, 255, 255, 0.6); transition: var(--transition); border: 1px solid rgba(255, 255, 255, 0.4); 
        }
        .back-btn-private:hover { background: var(--primary); color: white; box-shadow: 0 8px 20px var(--primary-glow); transform: translateY(-2px); }
        
        .sub-nav { display: flex; justify-content: center; gap: 15px; margin-bottom: 20px; flex-wrap: wrap; }
        .sub-nav-item { 
            padding: 10px 25px; border-radius: 30px; background: rgba(255, 255, 255, 0.5); color: var(--gray); 
            font-weight: 600; font-size: 0.95rem; text-decoration: none; display: flex; align-items: center; gap: 8px; 
            border: 1px solid var(--border); transition: var(--transition); backdrop-filter: blur(10px); 
        }
        .sub-nav-item i { font-size: 1.2rem; }
        .sub-nav-item:hover { background: rgba(255, 255, 255, 0.9); color: var(--primary); transform: translateY(-2px); }
        .sub-nav-item.active { background: var(--primary); color: white; box-shadow: 0 8px 20px var(--primary-glow); border-color: transparent; }

        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1200px; width: 100%; margin: 0 auto; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; 
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); padding: 30px 40px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
        }
        .header-area h2 { font-size: 2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}

        .filter-card {
            background: rgba(255, 255, 255, 0.65); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
            padding: 20px 30px; border-radius: var(--radius); box-shadow: var(--shadow);
            border: 1px solid var(--border); margin-bottom: 30px; transition: var(--transition);
        }
        .filter-card:hover { box-shadow: var(--shadow-hover); }
        
        .filter-form { display: flex; gap: 15px; flex-wrap: wrap; align-items: center; justify-content: space-between; }

        .search-wrapper { position: relative; flex: 1; min-width: 250px; }
        .search-wrapper i { position: absolute; left: 18px; top: 50%; transform: translateY(-50%); color: var(--gray); font-size: 1.2rem; transition: var(--transition); }
        
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
            border-color: rgba(255, 255, 255, 0.9); background: rgba(255, 255, 255, 0.8); 
            box-shadow: 0 10px 30px var(--primary-glow), 0 0 0 3px rgba(255, 255, 255, 0.5);
        }
        .search-input:focus + i { color: var(--primary); }

        .select-wrapper { position: relative; min-width: 200px; flex: 0 1 auto; }
        .select-wrapper select {
            width: 100%; padding: 14px 40px 14px 20px; border: 1px solid rgba(255, 255, 255, 0.6);
            border-radius: 30px; font-size: 0.95rem; font-weight: 500; background: rgba(241, 245, 249, 0.4); color: var(--dark);
            outline: none; appearance: none; transition: var(--transition); box-shadow: inset 0 4px 8px rgba(0,0,0,0.03); cursor: pointer;
        }
        .select-wrapper i { position: absolute; right: 18px; top: 50%; transform: translateY(-50%); color: var(--gray); pointer-events: none; }
        .select-wrapper select:hover { background: rgba(255, 255, 255, 0.5); }
        .select-wrapper select:focus { border-color: rgba(255, 255, 255, 0.9); background: rgba(255, 255, 255, 0.8); box-shadow: 0 10px 30px var(--primary-glow), 0 0 0 3px rgba(255, 255, 255, 0.5); }

        .btn {
            padding: 12px 22px; border-radius: 30px; font-weight: 700; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; position: relative;
        }
        .btn-primary { 
            background-color: var(--primary); 
            background-image: linear-gradient(135deg, rgba(255,255,255,0.2) 0%, rgba(255,255,255,0) 100%);
            color: var(--white); box-shadow: 0 8px 25px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.4); 
            border: 1px solid rgba(255, 255, 255, 0.2); backdrop-filter: blur(10px);
        }
        .btn-primary:hover { 
            background-color: var(--primary-hover); transform: translateY(-3px); 
            box-shadow: 0 12px 30px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.6); 
        }
        .btn-full { flex: 1; }
        .btn-icon { width: 42px; height: 42px; padding: 0; border-radius: 12px; font-size: 1.2rem; }
        .btn-outline { background: rgba(255,255,255,0.5); border: 1px solid var(--primary); color: var(--primary); }
        .btn-outline:hover { background: var(--primary); color: var(--white); box-shadow: 0 8px 25px var(--primary-glow); transform: translateY(-2px); border-color: transparent;}
        .btn-danger { background: rgba(255,255,255,0.5); color: #ef4444; border: 1px solid #ef4444; }
        .btn-danger:hover { background: #ef4444; color: var(--white); box-shadow: 0 8px 25px rgba(239, 68, 68, 0.3); transform: translateY(-2px); border-color: transparent;}

        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 25px; }

        .material-card {
            background: rgba(255, 255, 255, 0.65); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
            border-radius: var(--radius); border: 1px solid var(--border); box-shadow: var(--shadow); 
            overflow: hidden; display: flex; flex-direction: column; transition: var(--transition);
        }
        .material-card:hover { transform: translateY(-5px); box-shadow: var(--shadow-hover); }
        
        .thumbnail { height: 180px; position: relative; background: rgba(0,0,0,0.03); display: flex; align-items: center; justify-content: center; overflow: hidden; border-bottom: 1px solid var(--border); }
        .thumbnail img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s ease; }
        .material-card:hover .thumbnail img { transform: scale(1.05); }
        .fallback-icon-container { font-size: 4rem; color: var(--primary); opacity: 0.6; }
        
        .tag { 
            position: absolute; top: 15px; right: 15px; background: rgba(255,255,255,0.85); 
            backdrop-filter: blur(4px); padding: 6px 12px; border-radius: 20px; font-size: 0.8rem; font-weight: 700; 
            color: var(--dark); display: flex; align-items: center; gap: 5px; box-shadow: 0 4px 10px rgba(0,0,0,0.05); 
            border: 1px solid rgba(255,255,255,0.9);
        }
        .tag-video { color: #ef4444; }
        .tag-pdf { color: var(--primary); }

        .card-body { padding: 25px; display: flex; flex-direction: column; flex: 1; }
        .uploader-info-row { display: flex; align-items: center; gap: 10px; margin-bottom: 15px; }
        .uploader-avatar { width: 32px; height: 32px; background: var(--primary-glow); color: var(--primary); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 1.1rem; }
        .uploader-name { font-size: 0.9rem; font-weight: 600; color: var(--gray); }
        
        .card-title { font-size: 1.25rem; font-weight: 700; color: var(--dark); margin-bottom: 10px; line-height: 1.3; }
        .card-desc { font-size: 0.9rem; color: var(--gray); line-height: 1.6; margin-bottom: 25px; flex: 1; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
        .card-actions { display: flex; gap: 10px; align-items: center; }

        .empty-state { text-align: center; padding: 60px 20px; grid-column: 1 / -1; }
        .empty-state .icon-wrap { background: rgba(255,255,255,0.6); display: inline-flex; padding: 25px; border-radius: 50%; margin-bottom: 20px; box-shadow: inset 0 4px 8px rgba(0,0,0,0.03); }
        .empty-state i { font-size: 3.5rem; color: var(--primary); opacity: 0.7; }
        .empty-state h3 { color: var(--dark); margin-bottom: 10px; font-size: 1.5rem; font-weight: 800; }
        .empty-state p { color: var(--gray); font-weight: 500; }

        .modal-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(15, 23, 42, 0.4); backdrop-filter: blur(8px); display: none; align-items: center; justify-content: center; z-index: 1000; }
        
        /* --- UPDATED: Targets the form popup wrapper directly --- */
        .modal-content { 
            background: rgba(255, 255, 255, 0.85); 
            backdrop-filter: blur(16px); 
            width: 90%; 
            max-width: 500px; 
            border-radius: var(--radius); 
            padding: 30px; 
            box-shadow: 0 25px 50px rgba(0,0,0,0.2); 
            border: 1px solid var(--border); 
            animation: fadeInUp 0.4s ease-out; 

            /* --- FIX: Locks layout to viewport height and handles overflow --- */
            max-height: 85vh;                  /* Prevents the form box scaling past screen boundaries */
            overflow-y: auto;                  /* Generates an internal scrollbar dynamically */
            scrollbar-width: thin;             /* Safe fallback styling rules for Firefox engine */
            scrollbar-color: var(--bg-3) transparent;
        }

        /* --- NEW: Custom Glassmorphic scrollbar styling rules --- */
        .modal-content::-webkit-scrollbar {
            width: 6px;
        }
        .modal-content::-webkit-scrollbar-track {
            background: transparent;
        }
        .modal-content::-webkit-scrollbar-thumb {
            background: var(--bg-3);
            border-radius: 10px;
        }
        .modal-content::-webkit-scrollbar-thumb:hover {
            background: var(--primary);
        }

        .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; }
        .modal-header h3 { font-size: 1.4rem; color: var(--dark); display: flex; align-items: center; gap: 10px; font-weight: 800; }
        .modal-header h3 i { color: var(--primary); }
        .close-btn { background: none; border: none; font-size: 1.5rem; color: var(--gray); cursor: pointer; transition: var(--transition); }
        .close-btn:hover { color: #ef4444; transform: rotate(90deg); }
        
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; font-weight: 600; color: var(--dark); margin-bottom: 8px; font-size: 0.9rem; }
        .form-group input, .form-group select, .form-group textarea { width: 100%; padding: 14px 20px; border: 1px solid rgba(255, 255, 255, 0.6); border-radius: 15px; font-size: 0.95rem; font-family: inherit; background: rgba(241, 245, 249, 0.5); color: var(--dark); outline: none; transition: var(--transition); box-shadow: inset 0 4px 8px rgba(0,0,0,0.02); }
        .form-group input:focus, .form-group select:focus, .form-group textarea:focus { border-color: rgba(255, 255, 255, 0.9); background: rgba(255, 255, 255, 0.9); box-shadow: 0 10px 30px var(--primary-glow), 0 0 0 3px rgba(255, 255, 255, 0.5); }

        /* --- UPDATED RESPONSIVE MEDIA QUERIES --- */
        @media (max-width: 1024px) {
            .nav-link span { display: none !important; }
            .nav-link:hover, .nav-link.active { max-width: 44px; padding: 10px; justify-content: center; }
            .nav-link i { margin: 0; }
        }
        @media (max-width: 900px) {
            .header-area { flex-direction: column; align-items: flex-start; gap: 20px; padding: 20px; }
            .filter-form { flex-direction: column; align-items: stretch; }
            .search-wrapper, .select-wrapper { max-width: 100%; width: 100%; }
            .grid { grid-template-columns: 1fr; }
        }
        @media (max-width: 768px) {
            .top-nav { flex-direction: column; gap: 15px; border-radius: 25px; padding: 15px 20px; width: 92%; }
            .brand { justify-content: center; width: 100%; }
            .nav-menu { flex-direction: row; flex-wrap: wrap; justify-content: center; width: 100%; gap: 8px; }
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
        }
</style>
</head>
<body class="<%= roleClass %>">

    <canvas id="mathCanvas" style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: -1; pointer-events: none; opacity: 0.3;"></canvas>

    <div class="nav-wrapper">
        <% if (isPrivate) { %>
            <nav class="top-nav animated-nav">
                <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
                <a href="${pageContext.request.contextPath}/class_dashboard.jsp?classId=<%= classIdStr %>" class="back-btn-private">
                    <i class='bx bx-left-arrow-alt'></i> <span>Workspace Hub</span>
                </a>
            </nav>
        <% } else { %>
            <nav class="top-nav animated-nav">
                <div class="brand"><i class='bx bxs-cube-alt'></i> <span>NumSolve</span></div>
                <ul class="nav-menu">
                    <% if ("R001".equals(u.getRoleId())) { %>
                        <li><a href="${pageContext.request.contextPath}/dashboard/admin.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link active"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/users.jsp" class="nav-link"><i class='bx bxs-user-account'></i> <span>Users</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/logs.jsp" class="nav-link"><i class='bx bxs-server'></i> <span>Logs</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/reports.jsp" class="nav-link"><i class='bx bxs-chart'></i> <span>Reports</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                    <% } else if ("R002".equals(u.getRoleId())) { %>
                        <li><a href="${pageContext.request.contextPath}/dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/manage_classes.jsp" class="nav-link"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/educatorQuizzes" class="nav-link"><i class='bx bx-task'></i><span>Quizzes</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link active"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                    <% } else { %>
                        <li><a href="${pageContext.request.contextPath}/dashboard/student.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/student_classes.jsp" class="nav-link"><i class='bx bxs-group'></i> <span>Classes</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/student_quizzes.jsp" class="nav-link"><i class='bx bx-task'></i> <span>Quizzes</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link active"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                        <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                    <% } %>
                    <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
                </ul>
            </nav>
            
            <% if ("R002".equals(u.getRoleId())) { %>   
                <div class="sub-nav animated-panel delay-1">
                    <a href="${pageContext.request.contextPath}/materials.jsp" class="sub-nav-item active"><i class='bx bx-world'></i> Public Pool</a>
                    <a href="${pageContext.request.contextPath}/educator/my_materials.jsp" class="sub-nav-item"><i class='bx bx-folder'></i> My Materials</a>
                </div>
            <% } %>
        <% } %>
    </div>

    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <h2>
                <i class='bx <%= isPrivate ? "bx-folder-open" : "bx-book-open" %>' style="color: var(--primary);"></i> 
                <%= isPrivate ? "Class Materials" : "Public Library" %>
            </h2>
            
            <%-- RENDER UPLOAD BUTTON ONLY FOR EDUCATORS --%>
            <% if ("R002".equals(u.getRoleId())) { %>
                <button type="button" class="btn btn-primary" onclick="document.getElementById('uploadModal').style.display='flex'">
                    <i class='bx bx-cloud-upload'></i> Upload Material
                </button>
            <% } %>
        </div>

        <div class="filter-card animated-panel delay-1">
            <form method="get" class="filter-form">
                <% if (isPrivate) { %>
                    <input type="hidden" name="classId" value="<%= classIdStr %>">
                <% } %>

                <div class="search-wrapper">
                    <input type="text" name="keyword" class="search-input" placeholder="Search resources, topics, or keywords..." value="<%= keyword != null ? keyword : "" %>">
                    <i class='bx bx-search'></i>
                </div>
                
                <div class="select-wrapper">
                    <select name="type" onchange="this.form.submit()">
                        <option value="">All Formats</option>
                        <option value="PDF" <%= "PDF".equals(type) ? "selected" : "" %>>PDF Documents</option>
                        <option value="Video" <%= "Video".equals(type) ? "selected" : "" %>>Video Tutorials</option>
                    </select>
                    <i class='bx bx-chevron-down'></i>
                </div>
                
                <button type="submit" class="btn btn-primary"><i class='bx bx-filter-alt'></i> Filter</button>
            </form>
        </div>

        <div class="grid animated-panel delay-2">
            <% for (LearningMaterial m : list) { %>
                <div class="material-card">
                    
                    <div class="thumbnail">
                        <% if(m.getPhotoPath() != null && !m.getPhotoPath().isEmpty()) { %>
                            <img src="<%= request.getContextPath() %>/<%= m.getPhotoPath() %>" 
                                 onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';"> 
                            
                            <div class="fallback-icon-container" style="display:none;">
                                <i class='bx <%= "Video".equals(m.getMaterialType()) ? "bxs-video" : "bxs-file-pdf" %> thumbnail-icon'></i>
                            </div>
                        <% } else { %>
                            <div class="fallback-icon-container">
                                <i class='bx <%= "Video".equals(m.getMaterialType()) ? "bxs-video" : "bxs-file-pdf" %> thumbnail-icon'></i>
                            </div>
                        <% } %>
                        
                        <span class="tag <%= "Video".equals(m.getMaterialType()) ? "tag-video" : "tag-pdf" %>">
                            <i class='bx <%= "Video".equals(m.getMaterialType()) ? "bx-play-circle" : "bx-file-blank" %>'></i> 
                            <%= m.getMaterialType() %>
                        </span>
                    </div>

                    <div class="card-body">
                        <div class="uploader-info-row">
                            <div class="uploader-avatar">
                                <i class='bx bxs-user'></i>
                            </div>
                            <div class="uploader-name">
                                <%= m.getUploaderName() != null ? m.getUploaderName() : "Educator" %>
                            </div>
                        </div>

                        <h3 class="card-title"><%= m.getTopic() %></h3>
                        <p class="card-desc">
                            <%= (m.getDescription() != null && !m.getDescription().isEmpty()) ? m.getDescription() : "No description provided for this specific learning material." %>
                        </p>
                        
                        <div class="card-actions">
                            <a href="<%= request.getContextPath() %>/<%= m.getFilePath() %>" target="_blank" class="btn btn-primary btn-full">
                                <span>Open Resource</span> <i class='bx bx-right-arrow-alt'></i>
                            </a>

                            <% if ("R002".equals(u.getRoleId()) && u.getUserId() == m.getUserId()) { %>
                                <button type="button" class="btn btn-icon btn-outline" title="Edit Material" 
                                        onclick="openEditModal('<%= m.getMaterialId() %>', '<%= m.getTopic().replace("'", "\\'") %>', '<%= m.getMaterialType() %>', '<%= m.getDescription() != null ? m.getDescription().replace("'", "\\'").replace("\n", "\\n").replace("\r", "") : "" %>')">
                                    <i class='bx bx-pencil'></i>
                                </button>
                            <% } %>

                            <% if ("R001".equals(u.getRoleId()) || ("R002".equals(u.getRoleId()) && u.getUserId() == m.getUserId())) { %>
                                <a href="deleteMaterial?id=<%= m.getMaterialId() %><%= isPrivate ? "&classId=" + classIdStr : "" %>" class="btn btn-icon btn-danger" title="Delete Material" onclick="return confirm('Permanently delete this material? This action cannot be undone.')">
                                    <i class='bx bx-trash'></i>
                                </a>
                            <% } %>
                        </div>
                    </div>

                </div>
            <% } %>
            
            <% if(list.isEmpty()){ %>
                <div class="empty-state">
                    <div class="icon-wrap">
                        <i class='bx bx-folder-open'></i>
                    </div>
                    <h3>No Resources Found</h3>
                    <p>It looks like there are no documents or videos matching your filters right now.</p>
                </div>
            <% } %>
        </div>
        
    </main>

    <% if ("R002".equals(u.getRoleId())) { %>   
    
    <div class="modal-overlay" id="editModal">
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class='bx bx-slider-alt'></i> Update Details</h3>
                <button type="button" class="close-btn" onclick="document.getElementById('editModal').style.display='none'"><i class='bx bx-x'></i></button>
            </div>
            
            <form action="editMaterial" method="post" enctype="multipart/form-data">
                <input type="hidden" name="materialId" id="editMaterialId">
                <% if (isPrivate) { %>
                    <input type="hidden" name="classId" value="<%= classIdStr %>">
                <% } %>
                
                <div class="form-group">
                    <label>Replace Thumbnail <span style="font-weight:400; color:var(--gray); font-size:0.8rem;">(Optional)</span></label>
                    <input type="file" name="photo" accept="image/*">
                </div>
                
                <div class="form-group">
                    <label>Resource Title</label>
                    <input type="text" name="topic" id="editTopic" required placeholder="e.g. Calculus Chapter 1">
                </div>
                
                <div class="form-group">
                    <label>Content Format</label>
                    <select name="materialType" id="editType" required>
                        <option value="PDF">PDF Document</option>
                        <option value="Video">Video Tutorial</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" id="editDesc" rows="3" placeholder="Briefly describe what this material covers..."></textarea>
                </div>

                <div class="form-group">
                    <label>Replace Document / Video <span style="font-weight:400; color:var(--gray); font-size:0.8rem;">(Optional)</span></label>
                    <input type="file" name="materialFile">
                    <small style="color: var(--gray); display: block; margin-top: 4px; font-size: 0.78rem;">
                        Leave empty if you only want to rename text attributes.
                    </small>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%; padding: 16px; font-size: 1.05rem; margin-top: 10px;">
                    <i class='bx bx-check-circle'></i> Apply Changes
                </button>
            </form>
        </div>
    </div>
    
    <div class="modal-overlay" id="uploadModal">
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class='bx bx-upload'></i> Upload New Resource</h3>
                <button type="button" class="close-btn" onclick="document.getElementById('uploadModal').style.display='none'"><i class='bx bx-x'></i></button>
            </div>
            
            <form action="uploadMaterial" method="post" enctype="multipart/form-data">
                <% if (isPrivate) { %>
                    <input type="hidden" name="classId" value="<%= classIdStr %>">
                <% } %>
                
                <div class="form-group">
                    <<label>Thumbnail / Cover Image <span style="font-weight:400; color:var(--gray); font-size:0.8rem;">(Optional)</span></label>
                    <input type="file" name="photo" accept="image/*">
                </div>
                
                <div class="form-group">
                    <label>Resource Title</label>
                    <input type="text" name="topic" required placeholder="e.g. Numerical Interpolation Basics">
                </div>
                
                <div class="form-group">
                    <label>Content Format</label>
                    <select name="materialType" required>
                        <option value="PDF">PDF Document</option>
                        <option value="Video">Video Tutorial</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" rows="3" placeholder="Add clear instructions or scope details..."></textarea>
                </div>
                
                <div class="form-group">
                    <label>Select Resource File</label>
                    <input type="file" name="materialFile" required>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%; padding: 16px; font-size: 1.05rem; margin-top: 10px;">
                    <i class='bx bx-cloud-upload'></i> Complete Upload to <%= isPrivate ? "Class Space" : "Public Library" %>
                </button>
            </form>
        </div>
    </div>
    <% } %>
 <script>
        // ==========================================
        // 1. Edit Modal Handler (Enhanced)
        // ==========================================
        const modal = document.getElementById('editModal');

        function openEditModal(id, topic, type, desc) {
            document.getElementById('editMaterialId').value = id;
            document.getElementById('editTopic').value = topic;
            document.getElementById('editType').value = type;
            document.getElementById('editDesc').value = desc;
            document.getElementById('editModal').style.display = 'flex';
        }
        
        // Close modals smoothly when clicking outside active workspace panels
        window.onclick = function(event) {
            const editModal = document.getElementById('editModal');
            const uploadModal = document.getElementById('uploadModal');
            if (editModal && event.target == editModal) { editModal.style.display = "none"; }
            if (uploadModal && event.target == uploadModal) { uploadModal.style.display = "none"; }
        }

        function closeEditModal() {
            if (modal) modal.style.display = 'none';
        }

        // Close modal conditions: Outside click OR pressing 'Escape'
        window.addEventListener('click', (event) => {
            if (event.target === modal) closeEditModal();
        });

        window.addEventListener('keydown', (event) => {
            if (event.key === 'Escape' && modal && modal.style.display === 'flex') {
                closeEditModal();
            }
        });


        // ==========================================
        // 2. Jelly Bounce Animation for Search Bar
        // ==========================================
        const searchInput = document.querySelector('.search-wrapper .form-control');
        if (searchInput) {
            searchInput.addEventListener('focus', function() {
                this.classList.add('jelly-active');
                // Debounce timeout to cleanly remove class after CSS animation finishes
                setTimeout(() => this.classList.remove('jelly-active'), 400); 
            });
        }


        // ==========================================
        // 3. 3D Card Hover Effect (With Touch Support)
        // ==========================================
        const cards = document.querySelectorAll('.material-card');
        
        cards.forEach(card => {
            const handleMove = (clientX, clientY) => {
                const rect = card.getBoundingClientRect();
                const x = clientX - rect.left; 
                const y = clientY - rect.top;  
                const centerX = rect.width / 2;
                const centerY = rect.height / 2;
                
                // Max 5deg tilt, smooth perspective
                const rotateX = ((y - centerY) / centerY) * -5; 
                const rotateY = ((x - centerX) / centerX) * 5;  
                
                card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale3d(1.02, 1.02, 1.02)`;
            };

            const handleReset = () => {
                card.style.transform = `perspective(1000px) rotateX(0deg) rotateY(0deg) scale3d(1, 1, 1)`;
            };

            // Desktop Mouse Events
            card.addEventListener('mousemove', (e) => handleMove(e.clientX, e.clientY));
            card.addEventListener('mouseleave', handleReset);

            // Mobile/Tablet Touch Events (Passive listener for scroll performance)
            card.addEventListener('touchmove', (e) => {
                if(e.touches.length === 1) {
                    handleMove(e.touches[0].clientX, e.touches[0].clientY);
                }
            }, { passive: true });
            card.addEventListener('touchend', handleReset);
        });


        // ==========================================
        // 4. Floating Math Canvas Animation (Optimized)
        // ==========================================
        const canvas = document.getElementById('mathCanvas');
        if (canvas) {
            const ctx = canvas.getContext('2d');
            let width = canvas.width = window.innerWidth;
            let height = canvas.height = window.innerHeight;
            
            const symbols = ['∫', '∑', 'π', '∞', '√', 'θ', 'Δ', 'Ω', 'μ', '≈', '+', '-', '÷', '×'];
            const particles = [];

            // Initialize particles
            for (let i = 0; i < 35; i++) {
                particles.push({
                    x: Math.random() * width,
                    y: Math.random() * height,
                    symbol: symbols[Math.floor(Math.random() * symbols.length)],
                    size: Math.random() * 20 + 10,
                    speedY: Math.random() * 0.5 + 0.1,
                    opacity: Math.random() * 0.4 + 0.1
                });
            }

            function draw() {
                ctx.clearRect(0, 0, width, height);
                
                // Font set once per loop if all particles share the family
                ctx.font = "20px 'Poppins', sans-serif"; 

                particles.forEach(p => {
                    ctx.fillStyle = `rgba(100, 116, 139, ${p.opacity})`;
                    ctx.font = `${p.size}px 'Poppins', sans-serif`;
                    ctx.fillText(p.symbol, p.x, p.y);
                    
                    p.y -= p.speedY; // Floating up
                    
                    if (p.y < -30) {
                        p.y = height + 30;
                        p.x = Math.random() * width;
                    }
                });
                requestAnimationFrame(draw);
            }
            draw();

            // Debounced Resize Observer for better performance than generic resize listener
            let resizeTimeout;
            window.addEventListener('resize', () => {
                clearTimeout(resizeTimeout);
                resizeTimeout = setTimeout(() => {
                    width = canvas.width = window.innerWidth;
                    height = canvas.height = window.innerHeight;
                }, 150); 
            });
        }
    </script>
</body>
</html>