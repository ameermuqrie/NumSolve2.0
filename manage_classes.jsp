<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="dao.ClassDAO, model.Classroom, model.User, java.util.*" %>
<%
    // 1. Security Check: Ensure user is logged in AND is strictly an Educator (R002)
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    if (u == null || !"R002".equals(u.getRoleId())) { 
        response.sendRedirect(request.getContextPath() + "/login.jsp"); 
        return; 
    }
    
    // Set Role Class for Dynamic Theming
    String roleClass = "role-R002";

    // 2. Fetch data using our ClassDAO
    ClassDAO classDao = new ClassDAO();
    List<Classroom> classList = classDao.getClassesByEducator(u.getUserId());
    
    // 3. Status Check from Servlet
    String status = request.getParameter("status");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Classes | NumSolve Educator</title>
    
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
            
            /* Preserved specific variables for Class Cards & Page Elements */
            --glass-bg: rgba(255, 255, 255, 0.75);
            --glass-border: rgba(255, 255, 255, 0.6);
            --shadow-sm: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
            --shadow-md: 0 10px 25px -5px rgba(0, 0, 0, 0.05);
            --shadow-lg: 0 20px 25px -5px rgba(0, 0, 0, 0.05);
            --radius-lg: 24px;
            --radius-md: 16px;
            --text-main: #334155;
            --text-muted: #64748b;
            --danger: #ef4444;
            --danger-bg: #fef2f2;
            --success: #10b981;
            --success-bg: #ecfdf5;
        }

        /* Educator - Purple Glass */
        body.role-R002 { 
            --primary: #8b5cf6; 
            --primary-hover: #7c3aed; 
            --primary-glow: rgba(139, 92, 246, 0.3);
            --bg-1: #ede9fe; 
            --bg-2: #ddd6fe; 
            --bg-3: #c4b5fd;
            --nav-hover: rgba(139, 92, 246, 0.1);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(135deg, var(--bg-1) 0%, var(--bg-2) 50%, var(--bg-3) 100%);
            background-attachment: fixed;
            color: var(--text-main); 
            min-height: 100vh; 
            display: flex; 
            flex-direction: column; 
            align-items: center;
            overflow-x: hidden;
        }

        /* --- ENTRANCE ANIMATIONS --- */
        @keyframes dropDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(30px) scale(0.98); } to { opacity: 1; transform: translateY(0) scale(1); } }
        
        .animated-nav { animation: dropDown 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .animated-panel { animation: fadeInUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.15s; }
        .delay-2 { animation-delay: 0.3s; }

        /* --- FLOATING GLASS NAV (MATCHED) --- */
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

        /* --- MAIN CONTENT & HERO SECTION --- */
        .main-content { padding: 10px 24px 48px 24px; flex: 1; max-width: 1400px; width: 100%; }
        
        .hero-section { 
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-hover) 100%); 
            padding: 40px 48px; border-radius: var(--radius-lg); box-shadow: var(--shadow-md); 
            margin-bottom: 30px; display: flex; justify-content: space-between; align-items: center; 
            flex-wrap: wrap; gap: 24px; position: relative; overflow: hidden;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .hero-section::after {
            content: ''; position: absolute; top: -50%; right: -10%; width: 300px; height: 300px;
            background: rgba(255, 255, 255, 0.15); border-radius: 50%; filter: blur(40px); pointer-events: none;
        }

        .hero-title { position: relative; z-index: 2; color: var(--white); }
        .hero-title h2 { font-size: 2.2rem; font-weight: 700; margin-bottom: 8px; letter-spacing: -0.5px; display: flex; align-items: center; gap: 12px; }
        .hero-title p { color: rgba(255, 255, 255, 0.9); font-size: 1.05rem; max-width: 600px; font-weight: 400; }
        
        .educator-badge { 
            background: rgba(255, 255, 255, 0.2); backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px);
            padding: 16px 24px; border-radius: 20px; font-size: 0.95rem; color: var(--white); 
            text-align: right; border: 1px solid rgba(255, 255, 255, 0.3); 
            box-shadow: var(--shadow-sm); position: relative; z-index: 2;
        }
        .educator-badge strong { display: block; font-size: 1.1rem; margin-bottom: 4px; }

        /* --- ACTIONS & SEARCH --- */
        .header-actions { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; gap: 15px; flex-wrap: wrap; }
        .search-wrapper { position: relative; width: 100%; max-width: 350px; }
        .search-wrapper i { position: absolute; left: 18px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 1.2rem; }
        .search-input {
            width: 100%; padding: 14px 20px 14px 50px; border: 1px solid var(--glass-border);
            border-radius: 30px; font-size: 0.95rem; outline: none; transition: var(--transition); 
            background: var(--glass-bg); backdrop-filter: blur(10px); box-shadow: var(--shadow-sm); color: var(--text-main);
        }
        .search-input:focus { border-color: var(--primary); box-shadow: 0 0 0 4px var(--primary-glow); }
        
        .btn {
            padding: 14px 24px; border-radius: 30px; font-weight: 600; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px;
        }
        .btn-primary { background: var(--primary); color: var(--white); box-shadow: var(--shadow-sm); }
        .btn-primary:hover { background: var(--primary-hover); transform: translateY(-3px); box-shadow: var(--shadow-hover); }

        /* --- GRID AND CARDS --- */
        .class-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 24px; }
        
        .class-card { 
            background: var(--glass-bg); backdrop-filter: blur(20px); padding: 32px 24px; 
            border-radius: var(--radius-lg); box-shadow: var(--shadow-sm); transition: var(--transition); cursor: pointer; 
            display: flex; flex-direction: column; position: relative;
            border: 1px solid var(--glass-border); border-top: 5px solid var(--primary);
            z-index: 1; text-align: left;
        }
        .class-card:hover { transform: translateY(-6px); box-shadow: var(--shadow-hover); border-color: rgba(255, 255, 255, 0.9); border-top-color: var(--primary-hover); }
        
        .card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px; }
        .card-title { font-size: 1.3rem; font-weight: 700; color: var(--dark); margin: 0; line-height: 1.3; }
        .card-date { font-size: 0.85rem; color: var(--text-muted); display: flex; align-items: center; gap: 5px; margin-top: 8px; }
        
        .card-desc { 
            font-size: 0.95rem; color: var(--text-muted); margin-top: 16px; margin-bottom: 28px; 
            flex-grow: 1; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; line-height: 1.6;
        }
        
        .code-badge {
            padding: 8px 16px; border-radius: 12px; font-size: 0.95rem; font-weight: 700; font-family: monospace; letter-spacing: 1.5px;
            background-color: var(--white); color: var(--primary); display: inline-flex; align-items: center; gap: 12px; 
            border: 1px dashed var(--primary); box-shadow: inset 0 2px 4px rgba(0,0,0,0.02);
        }
        .copy-btn { cursor: pointer; color: var(--primary); transition: var(--transition); background: none; border: none; font-size: 1.2rem; display: flex; align-items: center;}
        .copy-btn:hover { color: var(--dark); transform: scale(1.15); }

        .card-footer { display: flex; justify-content: space-between; align-items: center; padding-top: 20px; border-top: 1px solid var(--glass-border); }
        .roster-link { font-size: 0.95rem; font-weight: 600; color: var(--primary); text-decoration: none; display: flex; align-items: center; gap: 6px; padding: 8px 16px; border-radius: 12px; transition: var(--transition); background: rgba(255, 255, 255, 0.5); }
        .roster-link:hover { background: var(--white); transform: translateX(4px); }
        
        .action-group { display: flex; gap: 8px; }
        .action-btn-sm { width: 38px; height: 38px; border-radius: 12px; display: inline-flex; align-items: center; justify-content: center; font-size: 1.2rem; transition: var(--transition); border: none; cursor: pointer; box-shadow: var(--shadow-sm); }
        .btn-edit { background: var(--white); color: var(--text-main); }
        .btn-edit:hover { background: var(--text-main); color: var(--white); }
        .btn-del { background: var(--danger-bg); color: var(--danger); }
        .btn-del:hover { background: var(--danger); color: var(--white); }

        /* --- ALERTS --- */
        .alert { padding: 16px 24px; border-radius: 16px; margin-bottom: 24px; font-weight: 500; display: flex; align-items: center; gap: 12px; box-shadow: var(--shadow-sm); backdrop-filter: blur(10px); border: 1px solid; }
        .alert-success { background: rgba(236, 253, 245, 0.9); color: #065f46; border-color: #a7f3d0; }
        .alert-error { background: rgba(254, 242, 242, 0.9); color: #991b1b; border-color: #fecaca; }

        .empty-state { text-align: center; padding: 60px 24px; background: var(--glass-bg); border-radius: var(--radius-lg); border: 2px dashed var(--glass-border); grid-column: 1 / -1; backdrop-filter: blur(10px); }
        .empty-state i { font-size: 4rem; color: var(--text-muted); opacity: 0.5; margin-bottom: 16px; }

        /* --- MODALS --- */
        .modal { display: none; position: fixed; z-index: 200; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(30, 41, 59, 0.6); backdrop-filter: blur(8px); align-items: center; justify-content: center; }
        .modal-content { background: var(--glass-bg); backdrop-filter: blur(25px); padding: 40px; border-radius: var(--radius-lg); width: 90%; max-width: 500px; box-shadow: var(--shadow-lg); border: 1px solid var(--glass-border); animation: fadeUp 0.3s ease; position: relative; }
        .close-modal { position: absolute; top: 20px; right: 24px; font-size: 1.8rem; color: var(--text-muted); cursor: pointer; transition: var(--transition); }
        .close-modal:hover { color: var(--danger); transform: rotate(90deg); }
        .form-group { margin-bottom: 24px; }
        .form-group label { display: block; font-weight: 600; margin-bottom: 8px; color: var(--dark); font-size: 0.95rem; }
        .form-control { width: 100%; padding: 14px; border: 1px solid var(--glass-border); border-radius: 12px; font-size: 0.95rem; outline: none; transition: var(--transition); background: var(--white); box-shadow: inset 0 2px 4px rgba(0,0,0,0.02); }
        .form-control:focus { border-color: var(--primary); box-shadow: 0 0 0 4px var(--primary-glow); }

        /* --- RESPONSIVE MEDIA QUERIES --- */
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
            
            .hero-section { padding: 32px 24px; flex-direction: column; align-items: flex-start; gap: 16px; }
            .educator-badge { text-align: left; width: 100%; }
            .hero-title h2 { font-size: 1.8rem; }
            
            .header-actions { flex-direction: column; align-items: stretch; gap: 12px; }
            .search-wrapper { max-width: 100%; }
            .btn { width: 100%; }
        }
    </style>
</head>

<body class="<%= roleClass %>">

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            <li><a href="${pageContext.request.contextPath}/dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
            <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
            <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
            <li><a href="${pageContext.request.contextPath}/manage_classes.jsp" class="nav-link active"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
            <li><a href="${pageContext.request.contextPath}/educatorQuizzes" class="nav-link"><i class='bx bx-task'></i><span>Quizzes</span></a></li>
            <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
        </ul>
    </nav>

    <main class="main-content">
        
        <div class="hero-section animated-panel delay-1">
            <div class="hero-title">
                <h2><i class='bx bxs-school'></i> Manage Classes</h2>
                <p>Create classrooms, share join codes, and manage your students.</p>
            </div>
            
            <div class="hero-actions">
                <div class="educator-badge">
                    <strong><%= u.getFullName() %></strong>
                    <i class='bx bxs-user-badge'></i> Educator ID: <%= u.getUserId() %>
                </div>
            </div>
        </div>

        <%-- Alerts from Servlet --%>
        <% if ("success".equals(status)) { %>
            <div class="alert alert-success animated-panel delay-1">
                <i class='bx bxs-check-circle' style="font-size: 1.4rem;"></i> Classroom successfully created! Share the code with your students.
            </div>
        <% } else if ("error".equals(status)) { %>
            <div class="alert alert-error animated-panel delay-1">
                <i class='bx bxs-error-circle' style="font-size: 1.4rem;"></i> Failed to complete action. Please try again.
            </div>
        <% } else if ("deleted".equals(status)) { %>
            <div class="alert alert-success animated-panel delay-1">
                <i class='bx bx-trash' style="font-size: 1.4rem;"></i> Classroom successfully deleted.
            </div>
        <% } else if ("edit_success".equals(status)) { %>
            <div class="alert alert-success animated-panel delay-1">
                <i class='bx bx-check-double' style="font-size: 1.4rem;"></i> Classroom details updated successfully.
            </div>
        <% } %>

        <div class="header-actions animated-panel delay-1">
            <div class="search-wrapper">
                <i class='bx bx-search'></i>
                <input type="text" id="searchInput" class="search-input" placeholder="Search classes by name..." onkeyup="filterClasses()">
            </div>
            <button class="btn btn-primary" onclick="openCreateModal()">
                <i class='bx bx-plus-circle'></i> Create New Class
            </button>
        </div>

        <div class="class-grid animated-panel delay-2" id="classGrid">
            
            <% if (classList == null || classList.isEmpty()) { %>
                <div class="empty-state">
                    <i class='bx bxs-school'></i>
                    <h3 style="color: var(--dark); margin-bottom: 8px; font-weight: 700; font-size: 1.5rem;">No Classes Yet</h3>
                    <p style="color: var(--text-muted);">Click "Create New Class" to start building your virtual classroom.</p>
                </div>
            <% } else { 
                for(Classroom c : classList) { 
                    // Escape quotes for javascript injection
                    String safeName = c.getClassName().replace("'", "\\'");
                    String safeDesc = c.getClassDescription() != null ? c.getClassDescription().replace("'", "\\'") : "";
            %>
                <div class="class-card" onclick="window.location.href='${pageContext.request.contextPath}/class_dashboard.jsp?id=<%= c.getClassId() %>'">
                    
                    <div class="card-header">
                        <div>
                            <h3 class="card-title"><%= c.getClassName() %></h3>
                            <div class="card-date"><i class='bx bx-calendar'></i> Created: <%= c.getCreatedDate() %></div>
                        </div>
                    </div>
                    
                    <div style="margin-top: 12px;">
                        <div class="code-badge" title="Share this code with students" onclick="event.stopPropagation();">
                            <%= c.getClassCode() %>
                            <button class="copy-btn" onclick="copyCode('<%= c.getClassCode() %>')" title="Copy Code">
                                <i class='bx bx-copy'></i>
                            </button>
                        </div>
                    </div>

                    <div class="card-desc">
                        <%= c.getClassDescription() != null ? c.getClassDescription() : "No description provided." %>
                    </div>

                    <div class="card-footer">
                        <a href="${pageContext.request.contextPath}/class_dashboard.jsp?id=<%= c.getClassId() %>&tab=roster" class="roster-link" onclick="event.stopPropagation();">
                            <i class='bx bxs-user-detail'></i> View Class
                        </a>
                        
                        <div class="action-group">
                            <button class="action-btn-sm btn-edit" title="Edit Class Settings" 
                                    onclick="event.stopPropagation(); openEditModal('<%= c.getClassId() %>', '<%= safeName %>', '<%= safeDesc %>');">
                                <i class='bx bx-cog'></i>
                            </button>
                            
                            <form action="${pageContext.request.contextPath}/deleteClass" method="post" style="margin: 0;" onsubmit="return confirm('Are you sure? This will delete the class and remove all students.');">
                                <input type="hidden" name="classId" value="<%= c.getClassId() %>">
                                <button type="submit" class="action-btn-sm btn-del" title="Delete Class" onclick="event.stopPropagation();">
                                    <i class='bx bx-trash'></i>
                                </button>
                            </form>
                        </div>
                    </div>

                </div>
            <%  } 
               } %>
        </div>

    </main>

    <div id="createModal" class="modal">
        <div class="modal-content">
            <span class="close-modal" onclick="closeCreateModal()">&times;</span>
            <h3 style="margin-bottom: 24px; color: var(--dark); display: flex; align-items: center; justify-content: center; gap: 8px; font-weight: 700;">
                <i class='bx bx-plus-circle' style="color: var(--primary); font-size: 1.8rem;"></i> Create New Class
            </h3>
            
            <form action="${pageContext.request.contextPath}/CreateClassServlet" method="POST" style="text-align: left;">
                <div class="form-group">
                    <label for="className">Class Name <span style="color: var(--danger);">*</span></label>
                    <input type="text" name="className" class="form-control" required placeholder="e.g. Numerical Methods 101">
                </div>
                <div class="form-group">
                    <label for="classDescription">Description / Note</label>
                    <textarea name="classDescription" class="form-control" rows="3" placeholder="e.g. Section 2, Monday 8 AM"></textarea>
                </div>
                <div style="display: flex; justify-content: flex-end; gap: 12px; margin-top: 30px;">
                    <button type="button" class="btn" style="background: rgba(255,255,255,0.8); color: var(--text-main); border: 1px solid var(--glass-border);" onclick="closeCreateModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class='bx bx-check'></i> Create</button>
                </div>
            </form>
        </div>
    </div>

    <div id="editModal" class="modal">
        <div class="modal-content">
            <span class="close-modal" onclick="closeEditModal()">&times;</span>
            <h3 style="margin-bottom: 24px; color: var(--dark); display: flex; align-items: center; justify-content: center; gap: 8px; font-weight: 700;">
                <i class='bx bx-cog' style="color: var(--primary); font-size: 1.8rem;"></i> Edit Class Settings
            </h3>
            
            <form action="${pageContext.request.contextPath}/EditClassServlet" method="POST" style="text-align: left;">
                <input type="hidden" name="classId" id="editClassId">
                
                <div class="form-group">
                    <label for="editClassName">Class Name <span style="color: var(--danger);">*</span></label>
                    <input type="text" id="editClassName" name="className" class="form-control" required>
                </div>
                <div class="form-group">
                    <label for="editClassDescription">Description / Note</label>
                    <textarea id="editClassDescription" name="classDescription" class="form-control" rows="3"></textarea>
                </div>
                <div style="display: flex; justify-content: flex-end; gap: 12px; margin-top: 30px;">
                    <button type="button" class="btn" style="background: rgba(255,255,255,0.8); color: var(--text-main); border: 1px solid var(--glass-border);" onclick="closeEditModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Save Changes</button>
                </div>
            </form>
        </div>
    </div>

<script>
    // --- Grid Search Filter ---
    function filterClasses() {
        var input = document.getElementById("searchInput");
        var filter = input.value.toUpperCase();
        var grid = document.getElementById("classGrid");
        var cards = grid.getElementsByClassName("class-card");

        for (var i = 0; i < cards.length; i++) {
            var titleElement = cards[i].querySelector(".card-title");
            if (titleElement) {
                var txtValue = titleElement.textContent || titleElement.innerText;
                if (txtValue.toUpperCase().indexOf(filter) > -1) {
                    cards[i].style.display = ""; 
                } else {
                    cards[i].style.display = "none"; 
                }
            }        
        }
    }

    // --- Modal Controls ---
    var createMod = document.getElementById("createModal");
    var editMod = document.getElementById("editModal");
    
    function openCreateModal() { createMod.style.display = "flex"; }
    function closeCreateModal() { createMod.style.display = "none"; }
    
    // Inject values into edit modal before opening
    function openEditModal(id, name, desc) {
        document.getElementById("editClassId").value = id;
        document.getElementById("editClassName").value = name;
        document.getElementById("editClassDescription").value = desc;
        editMod.style.display = "flex";
    }
    function closeEditModal() { editMod.style.display = "none"; }
    
    // Close modals when clicking outside
    window.onclick = function(event) {
        if (event.target == createMod) createMod.style.display = "none";
        if (event.target == editMod) editMod.style.display = "none";
    }

    // --- Copy to Clipboard ---
    function copyCode(code) {
        navigator.clipboard.writeText(code).then(function() {
            alert("Class Code copied: " + code);
        }, function(err) {
            console.error('Could not copy text: ', err);
        });
    }
</script>
</body>
</html>