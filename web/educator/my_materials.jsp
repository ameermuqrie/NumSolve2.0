<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,model.*,dao.*" %>
<%
    // 1. Security & Cache Control
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User u = (User) session.getAttribute("user");
    if (u == null || !"R002".equals(u.getRoleId())) { response.sendRedirect("../login.jsp"); return; }
    
    // Fetch base resources
    List<LearningMaterial> myList = new LearningMaterialDAO().getMaterialsByUser(u.getUserId());
    List<Classroom> educatorClasses = new ClassDAO().getClassesByEducator(u.getUserId());
    String roleClass = "role-" + u.getRoleId();

    // 2. State & Dynamic Action Router
    String action = request.getParameter("action");
    if (action == null) { action = "list"; }

    // Workspace execution context checking
    String urlClassId = request.getParameter("classId");
    boolean hasClassContext = (urlClassId != null && !urlClassId.trim().isEmpty() && !urlClassId.equals("0"));

    // Extract targeting item if in editing route
    LearningMaterial editMat = null;
    if ("edit".equals(action)) {
        String idParam = request.getParameter("id");
        if (idParam != null && !idParam.trim().isEmpty()) {
            int editId = Integer.parseInt(idParam);
            for (LearningMaterial m : myList) {
                if (m.getMaterialId() == editId) {
                    editMat = m;
                    break;
                }
            }
        }
        if (editMat == null) { action = "list"; } // Graceful fallback
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>
        <%= "create".equals(action) ? "Publish Material" : "edit".equals(action) ? "Update Configuration" : "My Materials" %> – NumSolve
    </title>
    
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

        /* Educator - Purple Glass */
        body.role-R002 { 
            --primary: #8b5cf6; --primary-hover: #7c3aed; --primary-glow: rgba(139, 92, 246, 0.3);
            --bg-1: #ede9fe; --bg-2: #ddd6fe; --bg-3: #c4b5fd;
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
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }
        .delay-3 { animation-delay: 0.3s; }
        
        .nav-wrapper { width: 100%; }

        /* --- FLOATING GLASS NAV --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 25px auto;
            background: rgba(255, 255, 255, 0.5); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
            padding: 12px 25px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: 0 15px 35px rgba(0, 0, 0, 0.05);
            border: 1px solid var(--border); z-index: 100; position: sticky; top: 25px;
        }

        .brand { 
            font-size: 1.5rem; font-weight: 800; display: flex; align-items: center; gap: 10px; 
            background: linear-gradient(135deg, var(--primary), var(--dark)); -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }
        .brand i { color: var(--primary); -webkit-text-fill-color: initial; font-size: 1.8rem; }
        
        .nav-menu { 
            list-style: none; display: flex; align-items: center; gap: 8px; 
            overflow-x: auto; scrollbar-width: none;
        }
        .nav-menu::-webkit-scrollbar { display: none; }

        .nav-link {
            display: flex; align-items: center; gap: 10px; padding: 10px; 
            border-radius: 40px; color: var(--gray); 
            font-weight: 600; font-size: 0.95rem; text-decoration: none; 
            max-width: 44px; white-space: nowrap; overflow: hidden;
            transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
        }

        .nav-link i { font-size: 1.4rem; min-width: 24px; text-align: center; }
        .nav-link span { opacity: 0; transform: translateX(-10px); transition: all 0.3s ease; }

        .nav-link:hover { background: rgba(255, 255, 255, 0.9); color: var(--primary); max-width: 160px; padding: 10px 20px; }
        .nav-link:hover span { opacity: 1; transform: translateX(0); }
        
        .nav-link.active {
            background: var(--primary); color: var(--white);
            box-shadow: 0 8px 20px var(--primary-glow); max-width: 160px; padding: 10px 20px;
        }
        .nav-link.active span { opacity: 1; transform: translateX(0); }

        .logout-item { margin-left: 10px; border-left: 1px solid var(--border); padding-left: 10px; }
        .logout-item .nav-link:hover { background: rgba(239, 68, 68, 0.1); color: #ef4444; }

        /* Sub Navigation */
        .sub-nav { display: flex; justify-content: center; gap: 15px; margin-bottom: 20px; flex-wrap: wrap; }
        .sub-nav-item { 
            padding: 10px 25px; border-radius: 30px; background: rgba(255, 255, 255, 0.5); color: var(--gray); 
            font-weight: 600; font-size: 0.95rem; text-decoration: none; display: flex; align-items: center; gap: 8px; 
            border: 1px solid var(--border); transition: var(--transition); backdrop-filter: blur(10px); 
        }
        .sub-nav-item i { font-size: 1.2rem; }
        .sub-nav-item:hover { background: rgba(255, 255, 255, 0.9); color: var(--primary); transform: translateY(-2px); }
        .sub-nav-item.active { background: var(--primary); color: white; box-shadow: 0 8px 20px var(--primary-glow); border-color: transparent; }

        /* --- MAIN CONTENT & HEADER --- */
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1200px; width: 100%; margin: 0 auto; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; 
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); padding: 30px 40px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
        }
        .header-area-content h2 { font-size: 2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area-content p { color: var(--gray); font-size: 0.95rem; margin-top: 5px; font-weight: 500; }

        .profile-link { text-decoration: none; }
        .user-badge-profile {
            display: flex; align-items: center; gap: 12px; background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(4px);
            padding: 8px 20px; border-radius: 30px; border: 1px solid var(--border); transition: var(--transition);
        }
        .user-badge-profile:hover { box-shadow: var(--shadow-hover); transform: translateY(-2px); background: rgba(255, 255, 255, 0.8); }
        .user-badge-profile .profile-name { font-weight: 600; color: var(--dark); font-size: 0.95rem; }
        .avatar {
            width: 35px; height: 35px; border-radius: 50%; background: var(--primary-glow);
            color: var(--primary); display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 1.1rem; border: 1px solid var(--white); box-shadow: var(--shadow);
        }

        /* --- ACTIONS & SEARCH (GLASS) --- */
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

        .select-wrapper { position: relative; min-width: 180px; flex: 0 1 auto; }
        .select-wrapper select {
            width: 100%; padding: 14px 40px 14px 20px; border: 1px solid rgba(255, 255, 255, 0.6);
            border-radius: 30px; font-size: 0.95rem; font-weight: 500; background: rgba(241, 245, 249, 0.4); color: var(--dark);
            outline: none; appearance: none; transition: var(--transition); box-shadow: inset 0 4px 8px rgba(0,0,0,0.03); cursor: pointer;
        }
        .select-wrapper i { position: absolute; right: 18px; top: 50%; transform: translateY(-50%); color: var(--gray); pointer-events: none; }
        .select-wrapper select:hover { background: rgba(255, 255, 255, 0.5); }
        .select-wrapper select:focus { border-color: rgba(255, 255, 255, 0.9); background: rgba(255, 255, 255, 0.8); box-shadow: 0 10px 30px var(--primary-glow), 0 0 0 3px rgba(255, 255, 255, 0.5); }

        /* --- PREMIUM BUTTONS --- */
        .btn {
            padding: 12px 22px; border-radius: 30px; font-weight: 700; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; position: relative;
        }
        .btn-create { 
            background-color: var(--primary); 
            background-image: linear-gradient(135deg, rgba(255,255,255,0.2) 0%, rgba(255,255,255,0) 100%);
            color: var(--white); box-shadow: 0 8px 25px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.4); 
            border: 1px solid rgba(255, 255, 255, 0.2); backdrop-filter: blur(10px); margin-right: auto;
        }
        .btn-create:hover { background-color: var(--primary-hover); transform: translateY(-3px); box-shadow: 0 12px 30px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.6); }

        .btn-primary { 
            background-color: var(--primary); 
            background-image: linear-gradient(135deg, rgba(255,255,255,0.2) 0%, rgba(255,255,255,0) 100%);
            color: var(--white); box-shadow: 0 8px 25px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.4); 
            border: 1px solid rgba(255, 255, 255, 0.2); backdrop-filter: blur(10px);
        }
        .btn-primary:hover { background-color: var(--primary-hover); transform: translateY(-3px); box-shadow: 0 12px 30px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.6); }
        
        .btn-full { flex: 1; border-radius: 12px; }
        .btn-icon { width: 44px; height: 44px; padding: 0; border-radius: 12px; font-size: 1.2rem; }
        
        .btn-outline { background: rgba(255,255,255,0.5); border: 1px solid var(--primary); color: var(--primary); }
        .btn-outline:hover { background: var(--primary); color: var(--white); box-shadow: 0 8px 25px var(--primary-glow); transform: translateY(-2px); border-color: transparent;}
        
        .btn-secondary { background: rgba(255,255,255,0.4); color: var(--dark); border: 1px solid var(--border); backdrop-filter: blur(4px); }
        .btn-secondary:hover { background: rgba(255,255,255,0.8); transform: translateY(-2px); }

        .btn-danger { background: rgba(255,255,255,0.5); color: #ef4444; border: 1px solid #ef4444; }
        .btn-danger:hover { background: #ef4444; color: var(--white); box-shadow: 0 8px 25px rgba(239, 68, 68, 0.3); transform: translateY(-2px); border-color: transparent;}

        /* --- MATERIAL GRID & CARDS --- */
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 25px; }

        .material-card {
            background: rgba(255, 255, 255, 0.65); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
            border-radius: var(--radius); border: 1px solid var(--border); box-shadow: var(--shadow); 
            overflow: hidden; display: flex; flex-direction: column; transition: var(--transition); position: relative;
        }
        .material-card:hover { transform: translateY(-5px); box-shadow: var(--shadow-hover); }
        
        .thumbnail { height: 180px; position: relative; background: rgba(0,0,0,0.03); display: flex; align-items: center; justify-content: center; overflow: hidden; border-bottom: 1px solid var(--border); }
        .thumbnail img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s ease; }
        .material-card:hover .thumbnail img { transform: scale(1.05); }
        .fallback-icon-container { font-size: 4.5rem; color: var(--primary); opacity: 0.4; }
        
        .type-tag { 
            position: absolute; top: 15px; right: 15px; background: rgba(255,255,255,0.85); 
            backdrop-filter: blur(4px); padding: 6px 14px; border-radius: 20px; font-size: 0.75rem; font-weight: 700; 
            color: var(--dark); display: flex; align-items: center; gap: 6px; box-shadow: 0 4px 10px rgba(0,0,0,0.05); 
            border: 1px solid rgba(255,255,255,0.9); text-transform: uppercase; z-index: 2;
        }
        .tag-video { color: #ef4444; }
        .tag-pdf { color: var(--primary); }

        .card-body { padding: 25px; display: flex; flex-direction: column; flex: 1; }

        .badge { 
            display: inline-flex; align-items: center; gap: 5px; padding: 4px 12px; border-radius: 20px; 
            font-size: 0.75rem; font-weight: 700; text-transform: uppercase; margin-bottom: 15px; width: fit-content; 
        }
        .badge-public { background: rgba(5, 150, 105, 0.1); color: #059669; border: 1px solid rgba(5, 150, 105, 0.2); }
        .badge-private { background: rgba(217, 119, 6, 0.1); color: #d97706; border: 1px solid rgba(217, 119, 6, 0.2); }

        .card-title { font-size: 1.25rem; font-weight: 700; color: var(--dark); margin-bottom: 10px; line-height: 1.3; }
        .card-desc { font-size: 0.9rem; color: var(--gray); line-height: 1.6; margin-bottom: 15px; flex: 1; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; font-weight: 500;}

        .card-meta { padding-top: 15px; border-top: 1px solid rgba(255, 255, 255, 0.6); margin-bottom: 20px; display: flex; flex-direction: column; gap: 8px; }
        .meta-item { display: flex; align-items: center; gap: 8px; font-size: 0.85rem; color: var(--gray); font-weight: 500; }
        .meta-item i { font-size: 1.1rem; color: var(--primary); }

        .card-actions { display: flex; gap: 10px; align-items: center; margin-top: auto; }

        /* --- MODERN GLASSMORPHISM FORM STYLES --- */
        .form-card {
            background: rgba(255, 255, 255, 0.65); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
            padding: 40px; border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
            width: 100%; max-width: 750px; margin: 0 auto 40px auto; transition: var(--transition);
        }
        .form-card:hover { box-shadow: var(--shadow-hover); }
        .form-group { margin-bottom: 25px; text-align: left; }
        .form-label { display: block; font-weight: 600; margin-bottom: 8px; color: var(--dark); font-size: 0.95rem; }
        
        .form-control { 
            width: 100%; padding: 14px 20px; border: 1px solid rgba(255, 255, 255, 0.6); 
            border-radius: 30px; font-size: 0.95rem; font-weight: 500; outline: none; transition: var(--transition);
            background: rgba(241, 245, 249, 0.4); color: var(--dark);
            box-shadow: inset 0 4px 8px rgba(0,0,0,0.03); 
        }
        .form-control:focus { 
            border-color: rgba(255, 255, 255, 0.9); background: rgba(255, 255, 255, 0.8); 
            box-shadow: 0 10px 30px var(--primary-glow), 0 0 0 3px rgba(255, 255, 255, 0.5);
        }
        textarea.form-control { border-radius: 20px; resize: vertical; min-height: 120px; }
        
        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        
        input[type="file"].form-control { border-radius: 30px; background: rgba(255,255,255,0.4); border: 1px dashed var(--primary); padding: 10px 20px; }
        .form-help { display: block; margin-top: 6px; font-size: 0.85rem; color: var(--gray); font-weight: 500; }
        
        .btn-group { display: flex; gap: 15px; margin-top: 35px; width: 100%; }

        /* --- EMPTY STATE --- */
        .empty-state { text-align: center; padding: 60px 20px; grid-column: 1 / -1; background: rgba(255,255,255,0.5); border-radius: var(--radius); border: 2px dashed rgba(255,255,255,0.8); backdrop-filter: blur(8px); }
        .empty-state i { font-size: 3.5rem; color: var(--primary); opacity: 0.5; margin-bottom: 15px; display: inline-block; }
        .empty-state h3 { color: var(--dark); margin-bottom: 8px; font-size: 1.4rem; font-weight: 800; }
        .empty-state p { color: var(--gray); font-weight: 500; }

        @media (max-width: 900px) {
            .nav-link.active span, .nav-link:hover span { display: none; }
            .nav-link.active, .nav-link:hover { max-width: 44px; padding: 10px; }
            .header-area { flex-direction: column; align-items: flex-start; gap: 20px; padding: 20px; }
            .filter-form { flex-direction: column; align-items: stretch; }
            .btn-create { margin-right: 0; width: 100%; }
            .search-wrapper, .select-wrapper { max-width: 100%; width: 100%; }
            .grid { grid-template-columns: 1fr; }
            .grid-2 { grid-template-columns: 1fr; gap: 0; }
        }
    </style>
</head>
<body class="<%= roleClass %>">

    <div class="nav-wrapper">
        <nav class="top-nav animated-nav">
            <div class="brand"><i class='bx bxs-cube-alt'></i> <span>NumSolve</span></div>
            <ul class="nav-menu">
                <li><a href="../dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="../solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                <li><a href="../recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                <li><a href="../computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                <li><a href="../manage_classes.jsp" class="nav-link"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
                <li><a href="${pageContext.request.contextPath}/educatorQuizzes" class="nav-link"><i class='bx bx-task'></i><span>Quizzes</span></a></li>
                <li><a href="../materials.jsp" class="nav-link active"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="../profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="../logout" class="nav-link"><i class='bx bxs-log-out-circle'></i> <span>Logout</span></a></li>
            </ul>
        </nav>

        <div class="sub-nav animated-panel delay-1">
            <a href="${pageContext.request.contextPath}/materials.jsp" class="sub-nav-item"><i class='bx bx-world'></i> Public Pool</a>
            <a href="${pageContext.request.contextPath}/educator/my_materials.jsp" class="sub-nav-item active"><i class='bx bx-folder'></i> My Materials</a>
        </div>
    </div>

    <main class="main-content">
        
        <%-- ==========================================
             VIEW STATE 1: MATERIAL MANAGEMENT ECOSYSTEM GRID
             ========================================== --%>
        <% if ("list".equals(action)) { %>
            
            <div class="header-area animated-panel delay-1">
                <div class="header-area-content">
                    <h2><i class='bx bxs-cloud-upload' style="color: var(--primary);"></i> My Uploaded Materials</h2>
                    <p>Manage, edit, or delete your personal contributions and resources.</p>
                </div>
                
                <a href="../profile.jsp" class="profile-link">
                    <div class="user-badge-profile">
                        <span class="profile-name"><%= u.getFullName() %></span>
                        <div class="avatar"><%= u.getFullName().charAt(0) %></div>
                    </div>
                </a>
            </div>

            <div class="filter-card animated-panel delay-2">
                <div class="filter-form">
                    
                    <a href="my_materials.jsp?action=create<%= hasClassContext ? "&classId=" + urlClassId : "" %>" class="btn btn-create">
                        <i class='bx bx-plus-circle'></i> Create New Material
                    </a>
                    
                    <div class="search-wrapper">
                        <input type="text" id="topicSearch" class="search-input" placeholder="Search my materials ecosystem..." onkeyup="performLiveFilter()">
                        <i class='bx bx-search'></i>
                    </div>
                    
                    <div class="select-wrapper">
                        <select id="materialTypeSelect" onchange="performLiveFilter()">
                            <option value="ALL">All Formats</option>
                            <option value="PDF">PDF Documents</option>
                            <option value="Video">Video Tutorials</option>
                        </select>
                        <i class='bx bx-chevron-down'></i>
                    </div>

                    <div class="select-wrapper">
                        <select id="visibilityFilter" onchange="performLiveFilter()">
                            <option value="ALL">All Visibility</option>
                            <option value="PUBLIC">Public Only</option>
                            <option value="PRIVATE">Private (Class Only)</option>
                        </select>
                        <i class='bx bx-chevron-down'></i>
                    </div>
                    
                </div>
            </div>

            <div class="grid animated-panel delay-3">
                <% for (LearningMaterial m : myList) { 
                    boolean isMatPrivate = (m.getClassId() != null && m.getClassId() > 0);
                    String visibilityTag = isMatPrivate ? "PRIVATE" : "PUBLIC";
                    
                    String iconClass = "bxs-file";
                    if ("Video".equals(m.getMaterialType())) iconClass = "bxs-video";
                    else if ("PDF".equals(m.getMaterialType())) iconClass = "bxs-file-pdf";
                %>
                <div class="material-card" data-topic="<%= m.getTopic() != null ? m.getTopic() : "" %>" data-format="<%= m.getMaterialType() != null ? m.getMaterialType() : "" %>" data-visibility="<%= visibilityTag %>">
                    
                    <div class="thumbnail">
                        <% if(m.getPhotoPath() != null && !m.getPhotoPath().isEmpty()) { %>
                            <img src="<%= request.getContextPath() %>/<%= m.getPhotoPath() %>" alt="Cover Image"
                                 onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';"> 
                            <div class="fallback-icon-container" style="display:none;">
                                <i class='bx <%= iconClass %> thumbnail-icon'></i>
                            </div>
                        <% } else { %>
                            <div class="fallback-icon-container">
                                <i class='bx <%= iconClass %> thumbnail-icon'></i>
                            </div>
                        <% } %>
                        
                        <span class="type-tag <%= "Video".equals(m.getMaterialType()) ? "tag-video" : "tag-pdf" %>">
                            <i class='bx <%= "Video".equals(m.getMaterialType()) ? "bx-play-circle" : "bx-file-blank" %>'></i> 
                            <%= m.getMaterialType() %>
                        </span>
                    </div>
                    
                    <div class="card-body">
                        
                        <span class="badge <%= isMatPrivate ? "badge-private" : "badge-public" %>">
                            <i class="bx <%= isMatPrivate ? "bx-lock-alt" : "bx-world" %>"></i> 
                            <%= isMatPrivate ? "Private (Class #" + m.getClassId() + ")" : "Public Material" %>
                        </span>

                        <h3 class="card-title"><%= m.getTopic() %></h3>
                        <p class="card-desc">
                            <%= (m.getDescription() != null && !m.getDescription().isEmpty()) ? m.getDescription() : "No active reference configuration log provided for this module." %>
                        </p>
                        
                        <div class="card-meta">
                            <div class="meta-item">
                                <i class='bx bx-calendar'></i>
                                <span>Uploaded: <%= m.getUploadDate() != null ? m.getUploadDate().toString() : "N/A" %></span>
                            </div>
                            <% if(m.getFileSize() > 0) { 
                                long bytes = m.getFileSize();
                                String sizeStr = bytes < 1024 ? bytes + " B" : bytes < 1048576 ? (bytes / 1024) + " KB" : String.format("%.2f MB", (double)bytes / 1048576);
                            %>
                            <div class="meta-item">
                                <i class='bx bx-hdd'></i>
                                <span>Size: <%= sizeStr %></span>
                            </div>
                            <% } %>
                        </div>
                        
                        <div class="card-actions">
                            <a href="../<%= m.getFilePath() %>" target="_blank" class="btn btn-primary btn-full">
                                <i class='bx bx-link-external'></i> Open Resource
                            </a>
                            <a href="my_materials.jsp?action=edit&id=<%= m.getMaterialId() %><%= hasClassContext ? "&classId=" + urlClassId : "" %>" class="btn btn-outline btn-icon" title="Edit Properties">
                                <i class='bx bx-pencil'></i>
                            </a>
                            
                            <a href="${pageContext.request.contextPath}/deleteMaterial?id=<%= m.getMaterialId() %>" 
                               class="btn btn-danger btn-icon" 
                               title="Purge Material From System" 
                               onclick="return confirm('Are you sure you want to delete this material? This process cannot be undone.')">
                                <i class='bx bx-trash'></i>
                            </a>
                        </div>
                    </div>
                </div>
                <% } %>
                
                <% if(myList.isEmpty()){ %>
                <div class="empty-state">
                    <i class='bx bx-folder-plus'></i>
                    <h3>No Materials Uploaded Yet</h3>
                    <p>Click the "Create New Material" asset manager button above to start your initial configuration loop.</p>
                </div>
                <% } %>
                
                <div class="empty-state" id="noResultsState" style="display: none;">
                    <i class='bx bx-search-alt'></i>
                    <h3>No Matching Metrics Found</h3>
                    <p>Refine your search parameters or drop active visibility node selections.</p>
                </div>
            </div>

        <%-- ==========================================
             VIEW STATE 2: PUBLISH/CREATE NEW MATERIAL FORM
             ========================================== --%>
        <% } else if ("create".equals(action)) { %>

            <div class="header-area animated-panel delay-1">
                <div class="header-area-content">
                    <h2><i class='bx bx-cloud-upload' style="color: var(--primary);"></i> Publish Learning Material</h2>
                    <p>Upload documentation assets or reference media blueprints directly into the node pool ecosystem.</p>
                </div>
            </div>

            <div class="form-card animated-panel delay-2">
                <form method="post" action="<%=request.getContextPath()%>/uploadMaterial" enctype="multipart/form-data">
                    
                    <div class="grid-2">
                        <div class="form-group">
                            <label class="form-label">Visibility Scope</label>
                            <select name="visibility" id="visibilityType" class="form-control" onchange="toggleTargetClassGroup()" required>
                                <option value="Private" <%= hasClassContext ? "selected" : "" %>>Private (Specific Classroom)</option>
                                <option value="Public" <%= !hasClassContext ? "selected" : "" %>>Public (Global Discovery Pool)</option>
                            </select>
                        </div>

                        <div class="form-group" id="classIdGroup">
                            <label class="form-label">Target Classroom Destination</label>
                            <select name="classId" id="classIdInput" class="form-control">
                                <option value="">-- Assign to Class Workspace --</option>
                                <% 
                                    if (educatorClasses != null && !educatorClasses.isEmpty()) {
                                        for (Classroom c : educatorClasses) { 
                                            String isSelected = (urlClassId != null && urlClassId.equals(String.valueOf(c.getClassId()))) ? "selected" : "";
                                %>
                                            <option value="<%= c.getClassId() %>" <%= isSelected %>>
                                                <%= c.getClassName() %> (Code: <%= c.getClassCode() %>)
                                            </option>
                                <% 
                                        } 
                                    } else { 
                                %>
                                        <option value="" disabled>No active classrooms detected.</option>
                                <%  } %>
                            </select>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Topic Title</label>
                        <input type="text" name="topic" class="form-control" placeholder="e.g., Introduction to Matrix Operations" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Material Format Classification</label>
                        <select name="materialType" id="typeSelect" class="form-control" required onchange="updateFileAccept()">
                            <option value="">Select Resource Type...</option>
                            <option value="PDF">PDF Document</option>
                            <option value="Video">Video Tutorial</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Description / Summary</label>
                        <textarea name="description" class="form-control" placeholder="Provide notes, focus points, or dynamic summaries regarding this resource item..." required></textarea>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Resource File Attachment</label>
                        <input type="file" name="file" id="fileInput" class="form-control" required>
                        <small id="fileHelp" class="form-help"><i class='bx bx-info-circle'></i> Please select a material type first</small>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Cover Card Thumbnail (Optional)</label>
                        <input type="file" name="photo" accept="image/*" class="form-control">
                        <small class="form-help">Upload a custom visual thumbnail descriptor card block.</small>
                    </div>

                    <div class="btn-group">
                        <a href="my_materials.jsp" class="btn btn-secondary"><i class='bx bx-arrow-back'></i> Cancel</a>
                        <button type="submit" class="btn btn-primary"><i class='bx bx-cloud-upload'></i> Upload Material</button>
                    </div>
                    
                </form>
            </div>

        <%-- ==========================================
             VIEW STATE 3: EDIT/UPDATE CONFIGURATION FORM
             ========================================== --%>
        <% } else if ("edit".equals(action) && editMat != null) { 
            boolean isCurrentPrivate = (editMat.getClassId() != null && editMat.getClassId() > 0);
        %>

            <div class="header-area animated-panel delay-1">
                <div class="header-area-content">
                    <h2><i class='bx bx-edit-alt' style="color: var(--primary);"></i> Update Learning Material Configuration</h2>
                    <p>Modify metadata mapping fields, shift target classrooms, or refresh the underlying asset file stream blobs.</p>
                </div>
            </div>

            <div class="form-card animated-panel delay-2">
                <form method="post" action="<%=request.getContextPath()%>/editMaterial" enctype="multipart/form-data">
                    <input type="hidden" name="materialId" value="<%= editMat.getMaterialId() %>">
                    
                    <input type="hidden" name="sourcePage" value="my_materials">
                    
                    <div class="grid-2">
                        <div class="form-group">
                            <label class="form-label">Visibility Scope</label>
                            <select name="visibility" id="visibilityType" class="form-control" onchange="toggleTargetClassGroup()" required>
                                <option value="Private" <%= isCurrentPrivate ? "selected" : "" %>>Private (Specific Classroom)</option>
                                <option value="Public" <%= !isCurrentPrivate ? "selected" : "" %>>Public (Global Discovery Pool)</option>
                            </select>
                        </div>

                        <div class="form-group" id="classIdGroup">
                            <label class="form-label">Target Classroom Destination</label>
                            <select name="classId" id="classIdInput" class="form-control">
                                <option value="">-- Assign to Class Workspace --</option>
                                <% 
                                    if (educatorClasses != null && !educatorClasses.isEmpty()) {
                                        for (Classroom c : educatorClasses) { 
                                            String isSelected = (editMat.getClassId() != null && editMat.getClassId().equals(c.getClassId())) ? "selected" : "";
                                %>
                                            <option value="<%= c.getClassId() %>" <%= isSelected %>>
                                                <%= c.getClassName() %> (Code: <%= c.getClassCode() %>)
                                            </option>
                                <% 
                                        } 
                                    } else { 
                                %>
                                        <option value="" disabled>No active classrooms detected.</option>
                                <%  } %>
                            </select>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Topic Title</label>
                        <input type="text" name="topic" class="form-control" value="<%= editMat.getTopic() %>" placeholder="e.g., Introduction to Matrix Operations" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Material Format Classification</label>
                        <select name="materialType" id="typeSelect" class="form-control" required onchange="updateFileAccept()">
                            <option value="PDF" <%= "PDF".equals(editMat.getMaterialType()) ? "selected" : "" %>>PDF Document</option>
                            <option value="Video" <%= "Video".equals(editMat.getMaterialType()) ? "selected" : "" %>>Video Tutorial</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Description / Summary</label>
                        <textarea name="description" class="form-control" placeholder="Provide summary points..." required><%= editMat.getDescription() %></textarea>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Resource File Attachment (Optional Replacement)</label>
                        <input type="file" name="file" id="fileInput" class="form-control">
                        <small id="fileHelp" class="form-help"><i class='bx bx-info-circle'></i> Leave completely blank to keep the current resource target intact.</small>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Cover Card Thumbnail (Optional Replacement)</label>
                        <input type="file" name="photo" accept="image/*" class="form-control">
                        <small class="form-help">Leave empty to preserve your current workspace graphic thumbnail layout mapping node.</small>
                    </div>

                    <div class="btn-group">
                        <a href="my_materials.jsp" class="btn btn-secondary"><i class='bx bx-arrow-back'></i> Cancel Changes</a>
                        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Save Configurations</button>
                    </div>
                    
                </form>
            </div>

        <% } %>
    </main>

    <script>
        // Real-time grid dashboard engine item filtering loop
        function performLiveFilter() {
            let query = document.getElementById('topicSearch').value.toLowerCase();
            let selectedFormat = document.getElementById('materialTypeSelect').value;
            let selectedVisibility = document.getElementById('visibilityFilter').value;
            let targetCards = document.getElementsByClassName('material-card');
            let displayedCount = 0;
            
            for (let i = 0; i < targetCards.length; i++) {
                let cardTopic = targetCards[i].getAttribute('data-topic').toLowerCase();
                let cardFormat = targetCards[i].getAttribute('data-format');
                let cardVisibility = targetCards[i].getAttribute('data-visibility');
                
                let matchesText = cardTopic.includes(query);
                let matchesFormat = (selectedFormat === 'ALL' || cardFormat === selectedFormat);
                let matchesVisibility = (selectedVisibility === 'ALL' || cardVisibility === selectedVisibility);
                
                if (matchesText && matchesFormat && matchesVisibility) {
                    targetCards[i].style.display = "";
                    displayedCount++;
                } else {
                    targetCards[i].style.display = "none";
                }
            }
            
            let searchPlaceholder = document.getElementById('noResultsState');
            if (searchPlaceholder) {
                searchPlaceholder.style.display = (displayedCount === 0 && targetCards.length > 0) ? "block" : "none";
            }
        }

        // Toggles configuration parameters for Class ID target visibility 
        function toggleTargetClassGroup() {
            const typeSelect = document.getElementById("visibilityType");
            const classGroup = document.getElementById("classIdGroup");
            const classInput = document.getElementById("classIdInput");

            if (!typeSelect || !classGroup || !classInput) return;

            if (typeSelect.value === "Private") {
                classGroup.style.display = "block";
                classInput.setAttribute("required", "true");
            } else {
                classGroup.style.display = "none";
                classInput.removeAttribute("required");
                classInput.value = ""; 
            }
        }

        // Monitors custom layout formatting validations dynamically
        function updateFileAccept() {
            var typeSelect = document.getElementById("typeSelect");
            var input = document.getElementById("fileInput");
            var help = document.getElementById("fileHelp");
            
            if (!typeSelect || !input || !help) return;
            
            var type = typeSelect.value;
            
            <%-- Checking state context --%>
            var isEditMode = <%= "edit".equals(action) %>;
            
            if (type === "PDF") {
                input.setAttribute("accept", ".pdf");
                help.innerHTML = "<i class='bx bxs-file-pdf' style='color:#ef4444;'></i> Allowed format: .pdf only" + (isEditMode ? " (Leave empty to retain)" : "");
            } else if (type === "Video") {
                input.setAttribute("accept", ".mp4,.mov,.avi,.mkv");
                help.innerHTML = "<i class='bx bxs-video' style='color:#3b82f6;'></i> Allowed formats: .mp4, .mov, .avi, .mkv" + (isEditMode ? " (Leave empty to retain)" : "");
            } else {
                input.removeAttribute("accept");
                help.innerHTML = isEditMode ? "<i class='bx bx-info-circle'></i> Leave completely blank to keep current resource target." : "<i class='bx bx-info-circle'></i> Please select a material type first";
            }
        }

        // Form initialization hook logic
        window.onload = function() {
            toggleTargetClassGroup();
            if(document.getElementById("typeSelect") && document.getElementById("typeSelect").value !== "") {
                updateFileAccept();
            }
        };
    </script>
</body>
</html>