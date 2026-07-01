<%-- 
    Document   : student_classes
    Created on : 2026
    Author     : NumSolve Dev
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="dao.ClassDAO, dao.UserDAO, model.Classroom, model.User, java.util.*" %>
<%
    // 1. Security Check: Ensure user is logged in AND is a Student (R003)
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    if (u == null || !"R003".equals(u.getRoleId())) { 
        response.sendRedirect(request.getContextPath() + "/login.jsp"); 
        return; 
    }

    // Set Role Class for Dynamic Theming
    String roleId = (u.getRoleId() != null) ? u.getRoleId() : "R003";
    String roleClass = "role-" + roleId;

    // 2. Fetch classes enrolled by this student securely using their exact ID
    ClassDAO classDao = new ClassDAO();
    UserDAO userDao = new UserDAO(); // Added to fetch educator names
    
    List<Classroom> enrolledClasses = classDao.getClassesByStudent(u.getUserId());
    
    // 3. Status Check from Servlet
    String status = request.getParameter("status");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Classes | NumSolve</title>
    
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
        .delay-3 { animation-delay: 0.45s; }

        /* --- FLOATING GLASS NAV --- */
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
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1200px; width: 100%; margin: 0 auto; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; 
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); padding: 30px 40px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
        }
        .header-area h2 { font-size: 2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area p { color: var(--gray); font-size: 1.05rem; margin-top: 5px; font-weight: 500;}

        .user-info { text-align: right; background: rgba(255,255,255,0.5); padding: 10px 20px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.8); }
        .user-info p { margin: 0; line-height: 1.4; }

        /* --- ACTIONS & SEARCH --- */
        .header-actions { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; gap: 15px; flex-wrap: wrap; }
        
        .search-wrapper { position: relative; width: 100%; max-width: 350px; }
        .search-wrapper i { position: absolute; left: 18px; top: 50%; transform: translateY(-50%); color: var(--gray); font-size: 1.2rem; transition: var(--transition); }
        .search-input {
            width: 100%; padding: 14px 20px 14px 45px; border: 1px solid rgba(255, 255, 255, 0.6); 
            border-radius: 30px; font-size: 0.95rem; font-weight: 500; outline: none; transition: var(--transition);
            background: rgba(241, 245, 249, 0.4); color: var(--dark); box-shadow: inset 0 4px 8px rgba(0,0,0,0.03); 
        }
        .search-input::placeholder { color: #94a3b8; }
        .search-input:hover { background: rgba(255, 255, 255, 0.5); }
        .search-input:focus { 
            border-color: rgba(255, 255, 255, 0.9); background: rgba(255, 255, 255, 0.8); 
            box-shadow: 0 10px 30px var(--primary-glow), 0 0 0 3px rgba(255, 255, 255, 0.5);
        }
        .search-input:focus + i { color: var(--primary); }

        .btn {
            padding: 12px 22px; border-radius: 30px; font-weight: 700; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px;
        }
        .btn-primary { 
            background-color: var(--primary); background-image: linear-gradient(135deg, rgba(255,255,255,0.2) 0%, rgba(255,255,255,0) 100%);
            color: var(--white); box-shadow: 0 8px 25px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.4); 
            border: 1px solid rgba(255, 255, 255, 0.2); backdrop-filter: blur(10px);
        }
        .btn-primary:hover { 
            background-color: var(--primary-hover); transform: translateY(-3px); 
            box-shadow: 0 12px 30px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.6); 
        }

        /* --- GLASS ALERTS --- */
        .alert { 
            padding: 18px 25px; border-radius: 16px; margin-bottom: 25px; font-weight: 600; 
            display: flex; align-items: center; gap: 12px; backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.5); box-shadow: var(--shadow);
        }
        .alert-success { background: rgba(220, 252, 231, 0.7); color: #166534; border-left: 5px solid #22c55e; }
        .alert-error { background: rgba(254, 226, 226, 0.7); color: #991b1b; border-left: 5px solid #ef4444; }
        .alert-warning { background: rgba(254, 243, 199, 0.7); color: #92400e; border-left: 5px solid #f59e0b; }
        .alert i { font-size: 1.4rem; }

        /* --- GRID AND GLASS CARDS --- */
        .class-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 25px; }
        
        .class-card { 
            background: rgba(255, 255, 255, 0.45); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
            border-radius: var(--radius); padding: 30px; box-shadow: var(--shadow); transition: var(--transition); 
            cursor: pointer; display: flex; flex-direction: column; position: relative; 
            border: 1px solid var(--border); border-top: 5px solid rgba(255, 255, 255, 0.6);
        }
        .class-card:hover { 
            transform: translateY(-8px); background: rgba(255, 255, 255, 0.65);
            box-shadow: var(--shadow-hover); border-color: rgba(255, 255, 255, 0.9); 
            border-top-color: var(--primary);
        }
        
        .card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px; }
        .card-title { font-size: 1.35rem; font-weight: 800; color: var(--dark); margin: 0; line-height: 1.2; letter-spacing: -0.3px;}
        .card-date { font-size: 0.85rem; color: var(--gray); display: flex; align-items: center; gap: 6px; margin-top: 8px; font-weight: 500;}
        
        .card-desc { 
            font-size: 0.95rem; color: var(--gray); margin-top: 20px; margin-bottom: 30px; 
            flex-grow: 1; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; 
            overflow: hidden; line-height: 1.6; font-weight: 500;
        }
        
        .code-badge {
            padding: 8px 14px; border-radius: 10px; font-size: 0.9rem; font-weight: 700;
            background-color: rgba(255, 255, 255, 0.7); color: var(--primary); 
            display: inline-flex; align-items: center; gap: 8px; border: 1px solid rgba(255, 255, 255, 0.9);
            box-shadow: 0 2px 5px rgba(0,0,0,0.02); cursor: default;
        }

        .card-footer { 
            display: flex; justify-content: flex-end; align-items: center; 
            padding-top: 20px; border-top: 1px solid rgba(0,0,0,0.05); 
        }
        
        .roster-link { 
            font-size: 0.95rem; font-weight: 700; color: var(--primary); text-decoration: none; 
            display: flex; align-items: center; gap: 5px; padding: 10px 20px; border-radius: 12px; 
            transition: var(--transition); background: rgba(255, 255, 255, 0.7); border: 1px solid rgba(255,255,255,0.9);
        }
        .roster-link i { transition: transform 0.3s ease; }
        .roster-link:hover { background: var(--primary); color: white; box-shadow: 0 5px 15px var(--primary-glow); border-color: transparent; }
        .roster-link:hover i { transform: translateX(4px); }

        /* --- EMPTY STATE --- */
        .empty-state { 
            text-align: center; padding: 80px 20px; background: rgba(255, 255, 255, 0.4); 
            backdrop-filter: blur(10px); border-radius: var(--radius); 
            border: 2px dashed rgba(255, 255, 255, 0.8); grid-column: 1 / -1; 
        }
        .empty-state i { font-size: 4.5rem; color: var(--primary); opacity: 0.5; margin-bottom: 20px; }

        /* --- MODAL (GLASS FORM) --- */
        .modal { 
            display: none; position: fixed; z-index: 200; left: 0; top: 0; width: 100%; height: 100%; 
            background-color: rgba(15, 23, 42, 0.4); backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px);
            align-items: center; justify-content: center;
        }
        .modal-content { 
            background: rgba(255, 255, 255, 0.85); backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,1);
            padding: 40px; border-radius: 24px; width: 90%; max-width: 450px; box-shadow: 0 25px 50px rgba(0,0,0,0.15); 
            animation: fadeInUp 0.4s cubic-bezier(0.16, 1, 0.3, 1); position: relative; text-align: center; 
        }
        .close-modal { 
            position: absolute; top: 20px; right: 25px; font-size: 1.8rem; color: var(--gray); 
            cursor: pointer; transition: var(--transition); background: rgba(255,255,255,0.5); 
            width: 35px; height: 35px; border-radius: 50%; display: flex; align-items: center; justify-content: center;
        }
        .close-modal:hover { color: #ef4444; background: rgba(254, 226, 226, 0.8); transform: rotate(90deg); }
        
        .join-icon-wrapper { 
            width: 80px; height: 80px; background: linear-gradient(135deg, rgba(255,255,255,0.8), rgba(255,255,255,0.4)); 
            border: 1px solid white; box-shadow: 0 10px 25px var(--primary-glow);
            border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px auto; 
        }
        .join-icon-wrapper i { font-size: 2.8rem; color: var(--primary); }
        
        .form-control-lg { 
            width: 100%; padding: 18px; border: 2px dashed rgba(59, 130, 246, 0.3); border-radius: 16px; 
            font-size: 1.8rem; outline: none; transition: var(--transition); text-align: center; 
            font-family: monospace; letter-spacing: 8px; font-weight: 800; color: var(--dark); 
            text-transform: uppercase; margin-bottom: 30px; background: rgba(255, 255, 255, 0.6);
            box-shadow: inset 0 4px 10px rgba(0,0,0,0.02);
        }
        .form-control-lg:focus { 
            border-color: var(--primary); background: #ffffff; 
            box-shadow: 0 0 0 4px var(--primary-glow), inset 0 2px 5px rgba(0,0,0,0.05); 
        }

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
        }

        /* Mobile Breakpoint: Stacked Layout & Adjustments */
        @media (max-width: 768px) {
            .top-nav { flex-direction: column; gap: 15px; border-radius: 25px; padding: 15px 20px; width: 92%; }
            .brand { justify-content: center; width: 100%; }
            .nav-menu { flex-direction: row; flex-wrap: wrap; justify-content: center; width: 100%; gap: 8px; }
            
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
            
            .header-area { flex-direction: column; align-items: flex-start; gap: 20px; padding: 20px;}
            .header-actions { flex-direction: column; align-items: stretch; }
            .search-wrapper { max-width: 100%; }
        }
    </style>
</head>

<body class="<%= roleClass %>">

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            <li><a href="${pageContext.request.contextPath}/dashboard/student.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
            <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
            <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
            <li><a href="${pageContext.request.contextPath}/student_classes.jsp" class="nav-link active"><i class='bx bxs-group'></i> <span>Classes</span></a></li>
            <li><a href="${pageContext.request.contextPath}/student_quizzes.jsp" class="nav-link"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
            <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
        </ul>
    </nav>

    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <div>
                <h2><i class='bx bxs-group' style="color: var(--primary);"></i> My Classes</h2>
                <p>Join classrooms and connect with your educators.</p>
            </div>
            <div class="user-info">
                <p style="font-weight: 700; color: var(--dark); font-size: 1.1rem;"><%= u.getFullName() %></p>
                <p style="font-size: 0.9rem; color: var(--gray); font-weight: 500;">Student ID: <%= u.getUserId() %></p>
            </div>
        </div>

        <%-- Alerts from Servlet --%>
        <% if ("joined".equals(status)) { %>
            <div class="alert alert-success animated-panel delay-1">
                <i class='bx bxs-check-circle'></i> Successfully enrolled in the class!
            </div>
        <% } else if ("already_enrolled".equals(status)) { %>
            <div class="alert alert-warning animated-panel delay-1">
                <i class='bx bxs-error'></i> You are already enrolled in this class.
            </div>
        <% } else if ("invalid_code".equals(status)) { %>
            <div class="alert alert-error animated-panel delay-1">
                <i class='bx bxs-error-circle'></i> Invalid Class Code. Please check the code and try again.
            </div>
        <% } %>

        <div class="header-actions animated-panel delay-2">
            <div class="search-wrapper">
                <input type="text" id="searchInput" class="search-input" placeholder="Search my classes..." onkeyup="filterClasses()">
                <i class='bx bx-search'></i>
            </div>
            <button class="btn btn-primary" onclick="openModal()">
                <i class='bx bx-user-plus'></i> Join a Class
            </button>
        </div>

        <div class="class-grid animated-panel delay-3" id="classGrid">
            
            <% if (enrolledClasses == null || enrolledClasses.isEmpty()) { %>
                <div class="empty-state">
                    <i class='bx bxs-group'></i>
                    <h3 style="color: var(--dark); margin-bottom: 5px; font-weight: 800;">No Classes Joined</h3>
                    <p style="color: var(--gray); font-weight: 500;">Click "Join a Class" and enter the 6-digit code from your educator.</p>
                </div>
            <% } else { 
                for(Classroom c : enrolledClasses) { 
                    // Use UserDAO to fetch the educator's real name based on their ID
                    User educator = userDao.getUserById(c.getUserId());
                    String educatorName = (educator != null) ? educator.getFullName() : "Unknown Educator";
            %>
                <div class="class-card" onclick="window.location.href='${pageContext.request.contextPath}/ClassDashboardServlet?classId=<%= c.getClassId() %>'">
                    
                    <div class="card-header">
                        <div>
                            <h3 class="card-title"><%= c.getClassName() %></h3>
                            <div class="card-date"><i class='bx bx-calendar'></i> Joined: <%= c.getCreatedDate() %></div>
                        </div>
                    </div>
                    
                    <div style="margin-top: 10px;">
                        <div class="code-badge" title="Educator Name">
                            <i class='bx bxs-user-badge'></i> <%= educatorName %>
                        </div>
                    </div>

                    <div class="card-desc">
                        <%= c.getClassDescription() != null ? c.getClassDescription() : "No description provided." %>
                    </div>

                    <div class="card-footer">
                        <a href="${pageContext.request.contextPath}/ClassDashboardServlet?classId=<%= c.getClassId() %>" class="roster-link" onclick="event.stopPropagation();">
                            Enter Class <i class='bx bx-right-arrow-alt'></i>
                        </a>
                    </div>

                </div>
            <%  } 
               } %>
        </div>

    </main>

    <div id="joinModal" class="modal">
        <div class="modal-content">
            <span class="close-modal" onclick="closeModal()"><i class='bx bx-x'></i></span>
            <div class="join-icon-wrapper">
                <i class='bx bx-dialpad'></i>
            </div>
            <h3 style="margin-bottom: 8px; color: var(--dark); font-weight: 800; font-size: 1.6rem;">Join Class</h3>
            <p style="color: var(--gray); font-size: 0.95rem; margin-bottom: 30px; font-weight: 500;">Ask your educator for the class code, then enter it here.</p>
            
            <form action="${pageContext.request.contextPath}/JoinClassServlet" method="POST">
                <input type="text" id="classCode" name="classCode" class="form-control-lg" required maxlength="6" placeholder="XXXXXX" autocomplete="off">
                <button type="submit" class="btn btn-primary" style="width: 100%; padding: 16px; font-size: 1.1rem; border-radius: 16px;">
                    <i class='bx bx-link'></i> Enroll Now
                </button>
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
    var modal = document.getElementById("joinModal");
    function openModal() { 
        modal.style.display = "flex"; 
        setTimeout(() => document.getElementById("classCode").focus(), 100);
    }
    function closeModal() { modal.style.display = "none"; }
    window.onclick = function(event) {
        if (event.target === modal) { modal.style.display = "none"; }
    };
</script>
</body>
</html>