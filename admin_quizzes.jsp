<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,model.*,dao.*" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User u = (User) session.getAttribute("user");
    if (u == null || !"R001".equals(u.getRoleId())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Fetch all quizzes across the platform
    List<Quiz> list = new QuizDAO().getAllQuizzesForAdmin(); 
    if (list == null) {
        list = new ArrayList<>();
    }
    
    // Lookups for educator and class names
    UserDAO userLookup = new UserDAO();
    ClassDAO classLookup = new ClassDAO();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin – Manage Quizzes</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css" rel="stylesheet">

    <style>
        /* --- GLOBAL VARIABLES --- */
        :root {
            --primary: #ef4444;         
            --primary-hover: #dc2626;
            --primary-glow: rgba(239, 68, 68, 0.3);
            --dark: #0f172a;
            --white: #ffffff;
            --gray: #64748b;
            --light-gray: #f8fafc;
            --border: rgba(255, 255, 255, 0.4);
            --shadow: 0 10px 30px rgba(0,0,0,0.05);
            --shadow-hover: 0 20px 40px rgba(0,0,0,0.1);
            --transition: all 0.3s ease;
            --radius: 16px;

            --blue: #3b82f6;     --blue-glow: rgba(59, 130, 246, 0.12);
            --green: #10b981;    --green-glow: rgba(16, 185, 129, 0.12);
            --purple: #8b5cf6;   --purple-glow: rgba(139, 92, 246, 0.12);
        }

        * { 
            margin: 0; 
            padding: 0; 
            box-sizing: border-box; 
            font-family: 'Poppins', sans-serif; 
        }
        
        body { 
            background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 50%, #fecaca 100%);
            background-attachment: fixed;
            color: var(--dark); 
            min-height: 100vh; 
            display: flex; 
            flex-direction: column; 
            align-items: center;
        }

        /* --- ANIMATIONS --- */
        @keyframes dropDown { from { opacity: 0; transform: translateY(-20px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
        
        .animated-nav { animation: dropDown 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .animated-panel { animation: fadeInUp 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }

        /* --- FLOATING GLASS NAV --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 20px auto;
            background: rgba(255, 255, 255, 0.5); 
            backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
            padding: 12px 25px; 
            display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; 
            box-shadow: 0 10px 25px rgba(239, 68, 68, 0.08);
            border: 1px solid var(--border); 
            z-index: 100; position: sticky; top: 20px;
            gap: 20px;
        }

        .brand { 
            font-size: 1.4rem; font-weight: 800; display: flex; align-items: center; gap: 8px; flex-shrink: 0;
            background: linear-gradient(135deg, #ef4444, #f97316); 
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }
        .brand i { color: var(--primary); -webkit-text-fill-color: initial; font-size: 1.6rem; }
        
        .nav-menu { 
            list-style: none; display: flex; align-items: center; gap: 6px; 
            overflow-x: auto; scrollbar-width: none; padding-bottom: 2px;
        }
        .nav-menu::-webkit-scrollbar { display: none; }

        .nav-link {
            display: flex; align-items: center; gap: 10px; padding: 10px; 
            border-radius: 30px; color: var(--gray); 
            font-weight: 600; font-size: 0.95rem; text-decoration: none; 
            max-width: 44px; 
            white-space: nowrap; overflow: hidden;
            transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
        }

        .nav-link i { font-size: 1.3rem; min-width: 20px; text-align: center; }
        .nav-link span { opacity: 0; transform: translateX(-15px); transition: all 0.3s ease; }

        .nav-link:hover { background: rgba(255, 255, 255, 0.9); color: var(--primary); max-width: 160px; padding: 10px 20px; }
        .nav-link:hover span { opacity: 1; transform: translateX(0); }
        
        .nav-link.active {
            background: var(--primary); color: var(--white);
            box-shadow: 0 6px 15px var(--primary-glow); max-width: 160px; padding: 10px 20px;
        }
        .nav-link.active span { opacity: 1; transform: translateX(0); }

        .logout-item { margin-left: 10px; border-left: 1px solid var(--border); padding-left: 10px; }
        .logout-item .nav-link:hover { background: rgba(239, 68, 68, 0.1); color: #ef4444; }

        /* --- MAIN CONTAINER --- */
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1400px; width: 100%; }
        
        /* --- GLASS HEADER --- */
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; 
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); padding: 30px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
        }
        .header-area h2 { font-size: 2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area p { color: var(--gray); font-size: 1rem; margin-top: 8px; font-weight: 500;}

        /* --- INTERACTIVE FILTER BAR --- */
        .filter-panel {
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px);
            padding: 20px; border-radius: var(--radius); margin-bottom: 30px;
            border: 1px solid var(--border); box-shadow: var(--shadow);
            display: flex; gap: 15px; flex-wrap: wrap; align-items: center;
        }
        
        .search-wrapper { position: relative; flex: 2; min-width: 250px; }
        .search-wrapper i { position: absolute; left: 16px; top: 50%; transform: translateY(-50%); color: var(--gray); font-size: 1.2rem; }
        
        .filter-input, .filter-select {
            width: 100%; padding: 12px 15px; border-radius: 30px;
            border: 1px solid rgba(0,0,0,0.1); background: var(--white);
            color: var(--dark); font-weight: 500; font-size: 0.95rem; outline: none;
            transition: var(--transition);
        }
        .filter-input { padding-left: 45px; }
        .filter-input:focus, .filter-select:focus { border-color: var(--primary); box-shadow: 0 0 0 3px var(--primary-glow); }

        .select-wrapper { position: relative; flex: 1; min-width: 180px; }
        .filter-select { padding-right: 35px; cursor: pointer; appearance: none; -webkit-appearance: none; font-weight: 600; }
        
        .select-wrapper::after {
            content: '\eed8'; 
            font-family: 'boxicons' !important;
            position: absolute; right: 16px; top: 50%; transform: translateY(-50%);
            color: var(--gray); pointer-events: none; font-size: 1.2rem;
        }

        /* --- QUIZ GRID CARDS --- */
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 25px; }

        .card {
            background: rgba(255, 255, 255, 0.8); backdrop-filter: blur(10px); padding: 20px; 
            border-radius: var(--radius); box-shadow: var(--shadow); transition: var(--transition); 
            display: flex; flex-direction: column; align-items: flex-start; 
            border: 1px solid var(--border); overflow: hidden; position: relative;
        }
        .card:hover { transform: translateY(-5px); box-shadow: var(--shadow-hover); border-color: rgba(239, 68, 68, 0.2); }

        .card-thumb {
            width: 100%; height: 160px; object-fit: cover; border-radius: 12px;
            margin-bottom: 15px; border: 1px solid rgba(0,0,0,0.05); background: var(--light-gray);
        }

        .icon-box {
            width: 50px; height: 50px; border-radius: 12px; display: flex; align-items: center; justify-content: center;
            font-size: 1.5rem; margin-bottom: 15px; transition: var(--transition);
            background: rgba(15, 23, 42, 0.05); color: var(--dark);
        }
        .card:hover .icon-box { transform: scale(1.05) rotate(-5deg); background: var(--purple-glow); color: var(--purple); }

        .card h3 { font-size: 1.2rem; color: var(--dark); margin-bottom: 8px; font-weight: 700; line-height: 1.3; }
        .card p { color: var(--gray); font-size: 0.9rem; margin-bottom: 20px; line-height: 1.5; flex-grow: 1; font-weight: 500;}

        /* Metadata Badges */
        .badge-container { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 15px; }
        .badge {
            padding: 5px 12px; border-radius: 30px; font-size: 0.75rem; font-weight: 700;
            letter-spacing: 0.3px; display: inline-flex; align-items: center; gap: 5px;
        }
        .badge-public { background: rgba(16, 185, 129, 0.15); color: #10b981; }
        .badge-private { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
        .badge-class { background: rgba(59, 130, 246, 0.15); color: #3b82f6; }
        .badge-educator { background: rgba(139, 92, 246, 0.15); color: #8b5cf6; }

        /* --- ACTION BUTTONS --- */
        .btn-group { display: flex; gap: 10px; width: 100%; margin-top: auto; }
        .btn {
            padding: 10px 15px; border-radius: 10px; font-weight: 600; font-size: 0.9rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 6px; flex: 1;
        }
        
        .btn-open { background: var(--blue); color: var(--white); box-shadow: 0 4px 10px var(--blue-glow); }
        .btn-open:hover { background: #2563eb; transform: translateY(-2px); }

        .btn-danger { background: #fee2e2; color: #ef4444; }
        .btn-danger:hover { background: var(--primary); color: var(--white); transform: translateY(-2px); box-shadow: 0 4px 10px var(--primary-glow); }

        form { margin: 0; display: flex; flex: 1; }
        form button { width: 100%; }

        .no-results {
            grid-column: 1 / -1; background: rgba(255, 255, 255, 0.7); text-align: center;
            padding: 40px; border-radius: var(--radius); border: 1px dashed var(--gray);
            color: var(--gray); font-weight: 500; font-size: 1.05rem; display: none;
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
            .brand span { display: none; }
        }

        /* Mobile Breakpoint: Stacked Layout & Adjustments */
        @media (max-width: 768px) {
            .top-nav { flex-direction: column; gap: 15px; width: 92%; border-radius: 25px; padding: 15px; }
            .brand { justify-content: center; width: 100%; }
            .brand span { display: block; } /* Show brand name when centered on mobile */
            .nav-menu { width: 100%; justify-content: center; flex-wrap: wrap; }
            
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
            
            .header-area { flex-direction: column; align-items: flex-start; padding: 20px; }
            .filter-panel { flex-direction: column; padding: 15px; }
            .search-wrapper, .select-wrapper { width: 100%; flex: none; }
            .grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-shield-x'></i> <span>NumSolve</span></div>
        <ul class="nav-menu">
            <li><a href="<%= request.getContextPath() %>/dashboard/admin.jsp" class="nav-link" title="Dashboard"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="<%= request.getContextPath() %>/admin/admin_materials.jsp" class="nav-link" title="Materials"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="<%= request.getContextPath() %>/users.jsp" class="nav-link" title="Users"><i class='bx bxs-user-account'></i> <span>Users</span></a></li>
            <li><a href="<%= request.getContextPath() %>/logs.jsp" class="nav-link" title="Logs"><i class='bx bxs-server'></i> <span>Logs</span></a></li>
            <li><a href="<%= request.getContextPath() %>/reports.jsp" class="nav-link" title="Reports"><i class='bx bxs-chart'></i> <span>Reports</span></a></li>
            <li><a href="<%= request.getContextPath() %>/admin_quizzes.jsp" class="nav-link active" title="Quizzes"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
            <li><a href="<%= request.getContextPath() %>/profile.jsp" class="nav-link" title="Profile"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="<%= request.getContextPath() %>/logout" class="nav-link" title="Logout"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
        </ul>
    </nav>
    
    <main class="main-content">
        <div class="header-area animated-panel delay-1">
            <div>
                <h2><i class='bx bx-task' style="color: var(--primary);"></i> Platform Quizzes</h2>
                <p>Global architectural management across unrestricted public assessments and private class exams.</p>
            </div>
        </div>

        <div class="filter-panel animated-panel delay-1">
            <div class="search-wrapper">
                <i class='bx bx-search'></i>
                <input type="text" id="quizSearch" class="filter-input" placeholder="Search by title, description, or educator...">
            </div>
            
            <div class="select-wrapper">
                <select id="visibilityFilter" class="filter-select">
                    <option value="all">All Access Levels</option>
                    <option value="public">🌐 Public Quizzes</option>
                    <option value="private">🔒 Private (Class) Quizzes</option>
                </select>
            </div>

            <div class="select-wrapper">
                <select id="classFilter" class="filter-select">
                    <option value="all">All Classes</option>
                </select>
            </div>
        </div>

        <div class="grid animated-panel delay-2" id="quizzesGrid">
            <% 
                if(list.isEmpty()){ 
            %>
                <div class="no-results" style="display: block;">
                    <i class='bx bx-folder-open' style="font-size: 3rem; color: var(--gray); margin-bottom: 10px; display: block;"></i>
                    No quizzes currently deployed inside the database.
                </div>
            <% 
                } else { 
                    for (Quiz q : list) {
                        // Determine Visibility
                        boolean isPublic = false;
                        if (q.getVisibility() != null) {
                            isPublic = "Visible".equalsIgnoreCase(q.getVisibility()) || "Public".equalsIgnoreCase(q.getVisibility());
                        } else if (q.getQuizType() != null) {
                            isPublic = "Public".equalsIgnoreCase(q.getQuizType());
                        }
                        
                        // Look up Class Name
                        String className = "";
                        if (q.getClassId() != null && q.getClassId() > 0) {
                            Classroom c = classLookup.getClassById(q.getClassId());
                            if(c != null && c.getClassName() != null) {
                                className = c.getClassName();
                            }
                        }

                        // Look up Educator Name
                        String creatorName = "Unknown";
                        User creator = userLookup.getUserById(q.getUserId());
                        if (creator != null && creator.getFullName() != null) {
                            creatorName = creator.getFullName();
                        }
            %>
            <div class="card" 
                 data-title="<%= q.getQuizTitle() != null ? q.getQuizTitle().toLowerCase() : "" %>" 
                 data-desc="<%= q.getQuizDescription() != null ? q.getQuizDescription().toLowerCase() : "" %>"
                 data-creator="<%= creatorName.toLowerCase() %>"
                 data-visibility="<%= isPublic ? "public" : "private" %>" 
                 data-class="<%= className.toLowerCase().trim() %>">
                
                <%-- Safe Absolute Photo Pathing --%>
                <% if (q.getPhotoPath() != null && !q.getPhotoPath().trim().isEmpty()) { %>
                    <img src="<%= request.getContextPath() %>/<%= q.getPhotoPath() %>" class="card-thumb" alt="Quiz Cover">
                <% } else { %>
                    <div class="icon-box">
                        <i class='bx bx-brain'></i>
                    </div>
                <% } %>

                <div class="badge-container">
                    <span class="badge badge-<%= isPublic ? "public" : "private" %>">
                        <%= isPublic ? "🌐 Public" : "🔒 Private" %>
                    </span>
                    <% if(!isPublic && !className.isEmpty()) { %>
                        <span class="badge badge-class"><i class='bx bxs-graduation'></i> <%= className %></span>
                    <% } %>
                    <span class="badge badge-educator"><i class='bx bxs-user'></i> <%= creatorName %></span>
                </div>

                <h3><%= q.getQuizTitle() != null ? q.getQuizTitle() : "Untitled Quiz" %></h3>
                <p><%= q.getQuizDescription() != null ? q.getQuizDescription() : "No description provided." %></p>

                <div class="btn-group">
                    <a href="<%= request.getContextPath() %>/viewQuiz?id=<%= q.getQuizId() %>" class="btn btn-open">
                        <i class='bx bx-link-external'></i> View
                    </a>

                    <form method="post" action="<%= request.getContextPath() %>/deleteQuiz" onsubmit="return confirm('Are you sure you want to completely drop this quiz assessment?');">
                        <input type="hidden" name="id" value="<%= q.getQuizId() %>">
                        <button type="submit" class="btn btn-danger">
                            <i class='bx bx-trash'></i> Delete
                        </button>
                    </form>
                </div>
            </div>
            <% 
                    }
                } 
            %>
            <div class="no-results" id="searchFeedback">
                <i class='bx bx-search-alt' style="font-size: 3rem; color: var(--gray); margin-bottom: 10px; display: block;"></i>
                No quizzes match your specified filtering criteria.
            </div>
        </div>
    </main>

    <script>
        document.addEventListener("DOMContentLoaded", function () {
            const searchInput = document.getElementById("quizSearch");
            const visibilityFilter = document.getElementById("visibilityFilter");
            const classFilter = document.getElementById("classFilter");
            const cards = document.querySelectorAll("#quizzesGrid .card");
            const feedback = document.getElementById("searchFeedback");

            // Dynamically populate Class Filter from present card attributes
            const uniqueClasses = new Set();
            cards.forEach(card => {
                const cls = card.getAttribute("data-class");
                if (cls && cls.trim() !== "") {
                    uniqueClasses.add(cls);
                }
            });
            
            uniqueClasses.forEach(className => {
                const opt = document.createElement("option");
                opt.value = className;
                opt.textContent = className.toUpperCase();
                classFilter.appendChild(opt);
            });

            function filterQuizzes() {
                const searchValue = searchInput.value.toLowerCase().trim();
                const visibilityValue = visibilityFilter.value;
                const classValue = classFilter.value;
                let visibleCount = 0;

                cards.forEach(card => {
                    const title = card.getAttribute("data-title");
                    const desc = card.getAttribute("data-desc");
                    const creator = card.getAttribute("data-creator");
                    const visibility = card.getAttribute("data-visibility");
                    const cardClass = card.getAttribute("data-class");

                    const matchesSearch = title.includes(searchValue) || desc.includes(searchValue) || creator.includes(searchValue);
                    const matchesVisibility = (visibilityValue === "all") || (visibility === visibilityValue);
                    const matchesClass = (classValue === "all") || (cardClass === classValue);

                    if (matchesSearch && matchesVisibility && matchesClass) {
                        card.style.display = "flex";
                        visibleCount++;
                    } else {
                        card.style.display = "none";
                    }
                });

                if (visibleCount === 0 && cards.length > 0) {
                    feedback.style.display = "block";
                } else {
                    feedback.style.display = "none";
                }
            }

            searchInput.addEventListener("input", filterQuizzes);
            visibilityFilter.addEventListener("change", filterQuizzes);
            classFilter.addEventListener("change", filterQuizzes);
        });
    </script>
</body>
</html>