<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.User" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%
    // Security & Session Check
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User u = (User) session.getAttribute("user");
    if (u == null || !"R002".equals(u.getRoleId())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    // Explicitly set Educator role class for consistent theming
    String roleClass = "role-R002"; 
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NumSolve | ${not empty param.classId ? 'Class Private Missions' : 'Public Missions'}</title>
    
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
            --radius: 24px; /* Kept your original 24px for cards */
            
            /* Original Page Specific Variables preserved for cards/filters */
            --bg-glass: rgba(255, 255, 255, 0.7);
            --border-glass: rgba(255, 255, 255, 0.6);
            --text-dark: #2D3748;
            --text-muted: #718096;
            --danger: #ef4444;
            --blue: #3b82f6;
            --blue-hover: #2563eb;
        }

        /* Educator - Purple Glass (Matching recommendation.jsp) */
        body.role-R002 { 
            --primary: #8b5cf6; 
            --primary-hover: #7c3aed; 
            --primary-glow: rgba(139, 92, 246, 0.3);
            --bg-1: #ede9fe; 
            --bg-2: #ddd6fe; 
            --bg-3: #c4b5fd;
            --nav-hover: rgba(139, 92, 246, 0.1);
            
            /* Fallback overrides for original elements */
            --primary-purple: var(--primary);
            --gradient-purple: linear-gradient(135deg, var(--primary) 0%, var(--primary-hover) 100%);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(135deg, var(--bg-1) 0%, var(--bg-2) 50%, var(--bg-3) 100%);
            background-attachment: fixed;
            color: var(--text-dark); 
            min-height: 100vh; 
            display: flex; 
            flex-direction: column; 
            align-items: center;
        }

        /* --- ENTRANCE ANIMATIONS --- */
        @keyframes dropDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(30px) scale(0.98); } to { opacity: 1; transform: translateY(0) scale(1); } }
        
        .animated-nav { animation: dropDown 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        
        .animate-if-no-modal {
            <c:if test="${!showModal && empty param.action}">
                animation: fadeInUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0;
            </c:if>
            <c:if test="${showModal || not empty param.action}">
                opacity: 1; 
            </c:if>
        }
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
        .logout-item .nav-link:hover { background: var(--nav-hover); color: var(--danger); }

        .back-btn { 
            color: var(--primary); text-decoration: none; display: flex; align-items: center; gap: 8px; 
            font-weight: 700; background: rgba(255,255,255,0.6); padding: 10px 20px; border-radius: 30px; 
            transition: var(--transition); font-size: 0.9rem; border: 1px solid var(--border);
            box-shadow: 0 4px 15px rgba(0,0,0,0.03);
        }
        .back-btn:hover { transform: translateY(-2px); box-shadow: 0 8px 20px var(--primary-glow); background: var(--white); }

        /* --- RESPONSIVE MEDIA QUERIES FOR NAV --- */
        @media (max-width: 1024px) {
            .nav-link span { display: none !important; }
            .nav-link:hover, .nav-link.active { max-width: 44px; padding: 10px; justify-content: center; }
            .nav-link i { margin: 0; }
        }

        @media (max-width: 768px) {
            .top-nav { flex-direction: column; gap: 15px; border-radius: 25px; padding: 15px 20px; width: 92%; }
            .brand { justify-content: center; width: 100%; }
            .nav-menu { flex-direction: row; flex-wrap: wrap; justify-content: center; width: 100%; gap: 8px; }
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
            
            /* Content specific responsive fixes */
            .filter-form { flex-direction: column; align-items: stretch; }
            .search-input { min-width: 100%; }
            .btn-create-filter { text-align: center; justify-content: center; }
        }

        /* --- CONSOLIDATED NAVIGATION PILLS --- */
        .view-toggle-container {
            display: flex; justify-content: center; gap: 15px; margin: 20px auto 30px auto;
            width: 100%; max-width: 1400px; padding: 0 20px;
        }

        .tab-pill {
            display: inline-flex; align-items: center; gap: 8px; padding: 10px 24px;
            border-radius: 30px; font-weight: 600; text-decoration: none;
            transition: var(--transition); font-size: 0.95rem; border: 1px solid transparent;
        }

        .tab-pill.active { background: var(--gradient-purple); color: var(--white); box-shadow: 0 8px 20px var(--primary-glow); }
        .tab-pill.inactive { background: rgba(255, 255, 255, 0.6); color: var(--text-muted); border-color: var(--border-glass); }
        .tab-pill.inactive:hover { background: rgba(255, 255, 255, 0.9); color: var(--primary); }

        /* --- MAIN CONTENT --- */
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1400px; width: 100%; }
        
        .header-area { margin-bottom: 25px; padding: 0 20px; }
        .header-area h2 { font-size: 2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px; }

        /* --- FILTERS GLASS CONTAINER CARD --- */
        .filter-card {
            background: var(--bg-glass); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
            padding: 24px 35px; border-radius: var(--radius); 
            box-shadow: var(--shadow); 
            margin-bottom: 35px; border: 1px solid var(--border-glass);
        }
        .filter-form { display: flex; gap: 15px; align-items: center; flex-wrap: wrap; width: 100%; }
        
        .form-control { 
            padding: 12px 20px; border: 1.5px solid #E2E8F0; 
            border-radius: 30px; font-size: 0.95rem; font-weight: 500; outline: none;
            transition: var(--transition); background: rgba(255, 255, 255, 0.7); color: var(--text-dark);
        }
        .form-control:focus { background: var(--white); border-color: var(--primary); box-shadow: 0 0 0 3px var(--primary-glow); }
        
        .search-input { flex: 1; min-width: 250px; }

        select.form-control {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%234A5568'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'/%3E%3C/svg%3E");
            background-repeat: no-repeat; background-position: right 20px center; background-size: 16px; padding-right: 45px;
        }

        .btn-create-filter {
            background: var(--gradient-purple); color: var(--white); padding: 12px 28px; border-radius: 30px; text-decoration: none;
            font-weight: 700; font-size: 0.95rem; box-shadow: 0 8px 15px var(--primary-glow); transition: var(--transition); 
            display: inline-flex; align-items: center; gap: 8px; border: none; cursor: pointer;
        }
        .btn-create-filter:hover { transform: translateY(-2px); box-shadow: 0 12px 25px var(--primary-glow); }

        /* --- SYSTEM NOTIFICATIONS --- */
        .alert { padding: 18px 25px; border-radius: 16px; margin-bottom: 25px; font-weight: 600; display: flex; align-items: center; gap: 12px; box-shadow: var(--shadow); border: 1px solid transparent; }
        .alert-success { background: rgba(16, 185, 129, 0.15); color: #065f46; border-color: rgba(16, 185, 129, 0.3); }
        .alert-error { background: rgba(239, 68, 68, 0.15); color: #991b1b; border-color: rgba(239, 68, 68, 0.3); }

        /* --- PREMIUM CONSOLIDATED QUIZ CARDS SYSTEM --- */
        .quiz-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 30px; }

        .quiz-card {
            background: var(--bg-glass); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
            border-radius: var(--radius); padding: 0;
            box-shadow: var(--shadow); position: relative; overflow: hidden;
            transition: var(--transition); display: flex; flex-direction: column;
            border: 1px solid var(--border-glass);
        }
        .quiz-card:hover { transform: translateY(-8px); box-shadow: var(--shadow-hover); border-color: rgba(139, 92, 246, 0.4); }

        .quiz-image { width: 100%; height: 190px; position: relative; background: #e2e8f0; overflow: hidden; }
        .quiz-image img { width: 100%; height: 100%; object-fit: cover; transition: all 0.4s ease; }
        .quiz-card:hover .quiz-image img { transform: scale(1.06); }
        .quiz-image::after { content: ''; position: absolute; inset: 0; background: linear-gradient(to top, rgba(15, 23, 42, 0.35), transparent); }

        .quiz-badge {
            position: absolute; top: 15px; right: 15px; padding: 6px 16px; border-radius: 40px; font-size: 0.75rem;
            font-weight: 800; text-transform: uppercase; z-index: 2; box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            display: inline-flex; align-items: center; gap: 5px;
        }
        .badge-public { background: #ecfdf5; color: #15803d; border: 1px solid #a7f3d0; } 
        .badge-private { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; }

        .quiz-content { padding: 25px; display: flex; flex-direction: column; flex-grow: 1; }
        .quiz-title { font-size: 1.25rem; font-weight: 700; color: var(--text-dark); margin-bottom: 8px; line-height: 1.4; }
        .quiz-desc { color: var(--text-muted); font-size: 0.9rem; margin-bottom: 20px; line-height: 1.6; flex-grow: 1; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; font-weight: 500; }

        .quiz-stats {
            display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; background: rgba(255, 255, 255, 0.5);
            padding: 12px; border-radius: 14px; margin-bottom: 20px; font-size: 0.85rem; font-weight: 700; border: 1px solid var(--border-glass); text-align: center;
        }
        .quiz-stats div { display: flex; flex-direction: column; align-items: center; color: var(--text-dark); gap: 4px; }
        .quiz-stats i { color: var(--primary); font-size: 1.25rem; }

        /* CARD ACTION CONTAINER ALIGNMENTS */
        .card-actions { display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border-glass); padding-top: 18px; flex-wrap: wrap; gap: 10px; }
        .primary-actions { display: flex; gap: 10px; flex: 1; }
        .secondary-actions { display: flex; gap: 8px; }

        .btn-action { padding: 10px 18px; border-radius: 12px; text-decoration: none; font-size: 0.9rem; font-weight: 700; transition: var(--transition); display: inline-flex; align-items: center; justify-content: center; gap: 6px; border: none; cursor: pointer; }
        
        .btn-play { background: var(--blue); color: var(--white); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2); flex: 1; }
        .btn-play:hover { background: var(--blue-hover); transform: translateY(-2px); box-shadow: 0 6px 15px rgba(59, 130, 246, 0.35); }
        
        .btn-grades { background: var(--gradient-purple); color: var(--white); box-shadow: 0 4px 12px var(--primary-glow); flex: 1; }
        .btn-grades:hover { transform: translateY(-2px); box-shadow: 0 6px 15px var(--primary-glow); }
        
        .btn-icon { width: 42px; height: 42px; padding: 0; font-size: 1.2rem; border-radius: 12px; border: 1px solid var(--border-glass); }
        
        /* -- NEW VIEW BUTTON -- */
        .btn-view { background: rgba(59, 130, 246, 0.1); color: var(--blue); border-color: rgba(59, 130, 246, 0.2); }
        .btn-view:hover { background: var(--blue); color: var(--white); border-color: var(--blue); transform: translateY(-2px); box-shadow: 0 6px 12px rgba(59, 130, 246, 0.2); }

        .btn-edit { background: rgba(255, 255, 255, 0.8); color: var(--text-dark); }
        .btn-edit:hover { background: var(--white); color: var(--primary); border-color: var(--primary); transform: translateY(-2px); }
        
        .btn-delete { background: rgba(239, 68, 68, 0.08); color: var(--danger); border-color: rgba(239, 68, 68, 0.15); }
        .btn-delete:hover { background: var(--danger); color: var(--white); border-color: var(--danger); transform: translateY(-2px); box-shadow: 0 6px 12px rgba(239, 68, 68, 0.2); }

        /* --- EMPTY STATE PLATFORMS --- */
        .empty-state { text-align: center; padding: 60px 40px; color: var(--text-muted); background: var(--bg-glass); backdrop-filter: blur(10px); border-radius: var(--radius); border: 2px dashed var(--border-glass); }
        .empty-state i { font-size: 4rem; color: var(--primary-glow); margin-bottom: 15px; }
        .empty-state h3 { color: var(--text-dark); margin-bottom: 8px; font-size: 1.4rem; font-weight: 800; }
        .empty-state p { font-weight: 500; font-size: 0.95rem; }
        
        /* --- HIGH-BLUR GLASS MODAL OVERLAYS --- */
        .modal-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.25); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); display: flex; align-items: center; justify-content: center; z-index: 1000; padding: 20px; }
        .modal-container { background: rgba(255, 255, 255, 0.92); border-radius: var(--radius); width: 100%; max-width: 700px; box-shadow: 0 25px 50px -12px var(--primary-glow); overflow: hidden; border: 1px solid var(--border-glass); animation: fadeInUp 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
        .modal-header { padding: 25px 35px; background: var(--gradient-purple); color: var(--white); display: flex; justify-content: space-between; align-items: center; }
        .modal-header h3 { font-size: 1.35rem; font-weight: 700; display: flex; align-items: center; gap: 10px; }
        .modal-close { background: transparent; border: none; color: white; font-size: 2rem; cursor: pointer; display: flex; align-items: center; opacity: 0.8; transition: var(--transition); }
        .modal-close:hover { opacity: 1; transform: scale(1.1); }
        .modal-body { padding: 35px; max-height: 480px; overflow-y: auto; }
        
        .grades-table { width: 100%; border-collapse: separate; border-spacing: 0; }
        .grades-table th { background: rgba(15, 23, 42, 0.03); padding: 14px 16px; font-size: 0.8rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 2px solid var(--border-glass); color: var(--text-muted); text-align: left; }
        .grades-table td { padding: 16px; font-size: 0.95rem; font-weight: 500; border-bottom: 1px solid rgba(15, 23, 42, 0.04); }
    </style>
</head>
<body class="<%= roleClass %>">

    <c:set var="isClassView" value="${not empty param.classId}" />
    <c:set var="viewParam" value="${param.view == 'personal' ? '&view=personal' : ''}" />

    <c:choose>
        <c:when test="${isClassView}">
            <nav class="top-nav animated-nav">
                <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
                <a href="${pageContext.request.contextPath}/class_dashboard.jsp?classId=${param.classId}" class="back-btn">
                    <i class='bx bx-left-arrow-alt'></i> Workspace Hub
                </a>
            </nav>
        </c:when>
        <c:otherwise>
            <nav class="top-nav animated-nav">
                <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
                
                <ul class="nav-menu">
                    <li><a href="${pageContext.request.contextPath}/dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/manage_classes.jsp" class="nav-link"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/educatorQuizzes" class="nav-link active"><i class='bx bx-task'></i> <span>Quizzes</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                    <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
                </ul>
            </nav>
        </c:otherwise>
    </c:choose>

    <c:if test="${!isClassView}">
        <div class="view-toggle-container animate-if-no-modal delay-1">
            <a href="${pageContext.request.contextPath}/educatorQuizzes?view=public" 
               class="tab-pill ${empty param.view || param.view == 'public' ? 'active' : 'inactive'}">
               <i class='bx bx-world'></i> Public Missions Pool
            </a>
            
            <a href="${pageContext.request.contextPath}/educatorQuizzes?view=personal" 
               class="tab-pill ${param.view == 'personal' ? 'active' : 'inactive'}">
               <i class='bx bx-folder'></i> My Personal Missions
            </a>
        </div>
    </c:if>

    <main class="main-content">
        
        <c:if test="${not empty param.msg}">
            <div class="alert alert-success animate-if-no-modal"><i class='bx bxs-check-circle'></i> ${param.msg}</div>
        </c:if>
        <c:if test="${not empty param.error}">
            <div class="alert alert-error animate-if-no-modal"><i class='bx bxs-error-circle'></i> ${param.error}</div>
        </c:if>

        <div class="header-area animate-if-no-modal delay-1">
            <c:choose>
                <c:when test="${isClassView}">
                    <h2><i class='bx bx-lock-alt' style="color: var(--primary-purple);"></i> Class Private Missions</h2>
                </c:when>
                <c:otherwise>
                    <c:choose>
                        <c:when test="${param.view == 'personal'}">
                            <h2><i class='bx bx-folder' style="color: var(--primary-purple);"></i> Manage Personal Missions</h2>
                        </c:when>
                        <c:otherwise>
                            <h2><i class='bx bx-world' style="color: var(--primary-purple);"></i> Manage Public Missions</h2>
                        </c:otherwise>
                    </c:choose>
                </c:otherwise>
            </c:choose>
        </div>

        <div class="filter-card animate-if-no-modal delay-1">
            <div class="filter-form">
                <c:choose>
                    <c:when test="${isClassView}">
                        <a href="${pageContext.request.contextPath}/CreateQuiz.jsp?classId=${param.classId}&type=Private" class="btn-create-filter" style="margin-right: auto;">
                            <i class='bx bx-plus-circle'></i> Create Class Mission
                        </a>
                    </c:when>
                    <c:when test="${param.view == 'personal'}">
                        <a href="${pageContext.request.contextPath}/CreateQuiz.jsp?type=Public&view=personal" class="btn-create-filter" style="margin-right: auto;">
                            <i class='bx bx-plus-circle'></i> Create Mission
                        </a>
                    </c:when>
                </c:choose>

                <input type="text" id="quizSearch" class="form-control search-input" placeholder="Search missions by title..." onkeyup="performLiveFilter()" <c:if test="${!isClassView && (empty param.view || param.view == 'public')}">style="margin-left: auto;"</c:if>>
                
                <select id="typeFilter" class="form-control" onchange="performLiveFilter()" style="width: 180px;">
                    <option value="ALL">All Types</option>
                    <option value="PUBLIC">Public Pool</option>
                    <option value="PRIVATE">Private Pool</option>
                </select>
            </div>
        </div>

        <div class="quiz-grid animate-if-no-modal delay-2" id="quizGrid">
            <c:set var="matchCount" value="0" />
            <c:forEach var="quiz" items="${quizList}">
                <c:set var="qType" value="${fn:trim(fn:toUpperCase(quiz.quizType))}" />
                <c:set var="showRow" value="false" />
                
                <c:if test="${isClassView && qType == 'PRIVATE' && quiz.classId == param.classId}">
                    <c:set var="showRow" value="true" />
                </c:if>
                <c:if test="${!isClassView && param.view == 'personal'}">
                    <c:set var="showRow" value="true" />
                </c:if>
                <c:if test="${!isClassView && (empty param.view || param.view == 'public') && qType == 'PUBLIC'}">
                    <c:set var="showRow" value="true" />
                </c:if>
                
                <c:if test="${showRow}">
                    <c:set var="matchCount" value="${matchCount + 1}" />
                    
                    <div class="quiz-card quiz-item" data-title="${fn:escapeXml(quiz.quizTitle)}" data-type="${qType}">
                        
                        <div class="quiz-image">
                            <c:choose>
                                <c:when test="${not empty quiz.photoPath}">
                                    <img src="${pageContext.request.contextPath}/${quiz.photoPath}" alt="Quiz Cover">
                                </c:when>
                                <c:otherwise>
                                    <img src="https://images.unsplash.com/photo-1509228468518-180dd4864904?q=80&w=800&auto=format&fit=crop" alt="Default Cover">
                                </c:otherwise>
                            </c:choose>
                            <span class="quiz-badge ${qType == 'PUBLIC' ? 'badge-public' : 'badge-private'}">
                                <i class="bx ${qType == 'PUBLIC' ? 'bx-world' : 'bx-lock-alt'}"></i> ${quiz.quizType}
                            </span>
                        </div>

                        <div class="quiz-content">
                            <h3 class="quiz-title">${quiz.quizTitle}</h3>
                            <p class="quiz-desc" title="${quiz.quizDescription}">${quiz.quizDescription}</p>
                            
                            <div class="quiz-stats">
                                <div><i class='bx bx-timer'></i> <span>${quiz.timeLimit}m</span></div>
                                <div><i class='bx bx-star'></i> <span>${quiz.totalMarks}pts</span></div>
                                <div><i class='bx bx-list-ol'></i> <span>${quiz.questionCount}Q</span></div>
                            </div>
                            
                            <div class="card-actions">
                                <div class="primary-actions">
                                    <a href="${pageContext.request.contextPath}/PlayQuizServlet?quizId=${quiz.quizId}${isClassView ? '&classId='.concat(param.classId) : ''}${viewParam}" class="btn-action btn-play">
                                        <i class='bx bx-play-circle'></i> Play
                                    </a>
                                    
                                    <c:if test="${quiz.userId == sessionScope.user.userId}">
                                        <a href="${pageContext.request.contextPath}/educatorQuizzes?action=viewGrades&quizId=${quiz.quizId}${isClassView ? '&classId='.concat(param.classId) : ''}${viewParam}" class="btn-action btn-grades">
                                            <i class='bx bx-bar-chart-alt-2'></i> Grades
                                        </a>
                                    </c:if>
                                </div>

                                <c:if test="${quiz.userId == sessionScope.user.userId}">
                                    <div class="secondary-actions">
                                        <a href="${pageContext.request.contextPath}/ViewQuizServlet?id=${quiz.quizId}${isClassView ? '&classId='.concat(param.classId) : ''}${viewParam}" class="btn-action btn-icon btn-view" title="View Details">
                                            <i class='bx bx-show'></i>
                                        </a>
                                        
                                        <a href="${pageContext.request.contextPath}/EditQuizServlet?id=${quiz.quizId}${isClassView ? '&classId='.concat(param.classId) : ''}${viewParam}" class="btn-action btn-icon btn-edit" title="Edit">
                                            <i class='bx bx-edit-alt'></i>
                                        </a>
                                        
                                        <a href="${pageContext.request.contextPath}/DeleteQuizServlet?id=${quiz.quizId}${isClassView ? '&classId='.concat(param.classId) : ''}${viewParam}" class="btn-action btn-icon btn-delete" onclick="return confirm('Are you sure you want to delete this mission? This cannot be undone!');" title="Delete">
                                            <i class='bx bx-trash'></i>
                                        </a>
                                    </div>
                                </c:if>
                            </div>

                        </div>
                    </div>
                </c:if>
            </c:forEach>
            
            <div id="noResultsMsg" style="display: none; grid-column: 1 / -1;">
                <div class="empty-state">
                    <i class='bx bx-search-alt'></i>
                    <h3>No matching missions found</h3>
                    <p>Refine your search query or change format settings.</p>
                </div>
            </div>
            
            <c:if test="${matchCount == 0}">
                <div class="empty-state" style="grid-column: 1 / -1;">
                    <i class='bx bx-ghost'></i>
                    <c:choose>
                        <c:when test="${isClassView}">
                            <h3>No private missions found for this class!</h3>
                            <p>Click "Create Class Mission" to deploy a quiz specifically for these students.</p>
                        </c:when>
                        <c:when test="${param.view == 'personal'}">
                            <h3>No personal missions yet!</h3>
                            <p>You haven't created any Public or Private missions. Click "Create" to get started.</p>
                        </c:when>
                        <c:otherwise>
                            <h3>No public missions found!</h3>
                            <p>Share your knowledge pool by building your first public mission.</p>
                        </c:otherwise>
                    </c:choose>
                </div>
            </c:if>
        </div>
    </main>

    <c:if test="${param.action == 'viewGrades' || showModal}">
        <div class="modal-overlay" id="gradesModal">
            <div class="modal-container">
                <div class="modal-header">
                    <h3><i class='bx bx-trophy'></i> Performance Matrix & Results</h3>
                    <button class="modal-close" onclick="closeGradesModal()">&times;</button>
                </div>
                <div class="modal-body">
                    <table class="grades-table">
                        <thead>
                            <tr>
                                <th>Student Identity</th>
                                <th>Submission Date</th>
                                <th>Score Summary</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:choose>
                                <c:when test="${not empty gradeList}">
                                    <c:forEach var="grade" items="${gradeList}">
                                        <tr>
                                            <td style="font-weight: 700; color: var(--text-dark);">${grade.studentName}</td>
                                            <td style="color: var(--text-muted); font-weight: 600;">${grade.submitDate}</td>
                                            <td><strong style="color: var(--primary-purple); font-weight: 800;">${grade.score}</strong> / ${grade.totalPossible} pts</td>
                                        </tr>
                                    </c:forEach>
                                </c:when>
                                <c:otherwise>
                                    <tr>
                                        <td colspan="3" style="text-align: center; color: var(--text-muted); padding: 50px 10px;">
                                            <i class='bx bx-info-circle' style="font-size: 2.5rem; margin-bottom: 12px; color: rgba(124, 92, 255, 0.3);"></i>
                                            <p style="font-weight: 600;">No submission logs found for this assignment target yet.</p>
                                        </td>
                                    </tr>
                                </c:otherwise>
                            </c:choose>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </c:if>  
            
   <script>
        function performLiveFilter() {
            const searchInput = document.getElementById('quizSearch');
            const typeFilter = document.getElementById('typeFilter');
            const noResults = document.getElementById('noResultsMsg');
            const items = document.querySelectorAll('.quiz-item');

            // Safety check to ensure elements exist before proceeding
            if (!searchInput || !typeFilter) return;

            const searchQuery = searchInput.value.toLowerCase().trim();
            const filterType = typeFilter.value;
            let visibleCount = 0; // Renamed from transparentVisibleCount for better clarity

            items.forEach(item => {
                // Added fallbacks ('') in case the data attributes are missing on an element
                const title = (item.getAttribute('data-title') || '').toLowerCase();
                const type = item.getAttribute('data-type') || '';

                const matchesSearch = title.includes(searchQuery);
                const matchesType = (filterType === 'ALL') || (type === filterType);

                if (matchesSearch && matchesType) {
                    item.style.display = 'flex';
                    visibleCount++;
                } else {
                    item.style.display = 'none';
                }
            });

            if (noResults) {
                noResults.style.display = (visibleCount === 0 && items.length > 0) ? 'block' : 'none';
            }
        }

        function closeGradesModal() {
            const currentUrl = new URL(window.location.href);
            currentUrl.searchParams.delete('action');
            currentUrl.searchParams.delete('quizId');

            // UPDATED: Using history.replaceState updates the URL without forcing a full page refresh
            window.history.replaceState({}, '', currentUrl.toString());

            // Note: If you need to hide the modal in the UI via JavaScript, add that here:
            // document.getElementById('your-modal-id').style.display = 'none';
        }
    </script>
</body>
</html>