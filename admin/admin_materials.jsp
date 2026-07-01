<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,model.*,dao.*" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User u = (User) session.getAttribute("user");
    if (u == null || !"R001".equals(u.getRoleId())) {
        // FIXED: Context path applied to Java redirect
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Now calling our new unrestricted method
    List<LearningMaterial> list = new LearningMaterialDAO().getAllMaterialsAdmin(); 
    if (list == null) {
        list = new ArrayList<>();
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Admin – Manage Materials</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css" rel="stylesheet">

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

            --blue: #3b82f6;     --blue-glow: rgba(59, 130, 246, 0.12);
            --green: #10b981;    --green-glow: rgba(16, 185, 129, 0.12);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 50%, #fecaca 100%);
            background-attachment: fixed;
            color: var(--dark); 
            /* FIXED: Viewport sizing for standard and dynamic mobile browsers */
            min-height: 100vh; 
            min-height: 100dvh;
            display: flex; 
            flex-direction: column; 
            align-items: center;
            overflow-x: hidden;
        }

        /* --- ANIMATIONS --- */
        @keyframes dropDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(30px) scale(0.98); } to { opacity: 1; transform: translateY(0) scale(1); } }
        
        .animated-nav { animation: dropDown 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .animated-panel { animation: fadeInUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.15s; }
        .delay-2 { animation-delay: 0.3s; }

        /* --- FLOATING GLASS NAV --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 25px auto;
            background: rgba(255, 255, 255, 0.5); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
            padding: 12px 25px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: 0 15px 35px rgba(239, 68, 68, 0.08);
            border: 1px solid var(--border); z-index: 100; position: sticky; top: 25px;
            flex-wrap: wrap; gap: 15px;
        }

        .brand { 
            font-size: 1.5rem; font-weight: 800; display: flex; align-items: center; gap: 10px; 
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
            background: rgba(255, 255, 255, 0.9); color: var(--primary); 
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

        /* --- MAIN CONTAINER --- */
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1400px; width: 100%; }
        
        /* --- GLASS HEADER --- */
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; 
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); padding: 30px 40px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
        }
        .header-area h2 { font-size: 2.2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area p { color: var(--gray); font-size: 1.1rem; margin-top: 5px; font-weight: 500;}

        /* --- INTERACTIVE FILTER BAR --- */
        .filter-panel {
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px);
            padding: 20px 30px; border-radius: var(--radius); margin-bottom: 30px;
            border: 1px solid var(--border); box-shadow: var(--shadow);
            display: flex; gap: 15px; flex-wrap: wrap; align-items: center;
        }
        
        .search-wrapper { position: relative; flex: 2; min-width: 280px; }
        .search-wrapper i { position: absolute; left: 18px; top: 50%; transform: translateY(-50%); color: var(--gray); font-size: 1.2rem; }
        
        .filter-input {
            width: 100%; padding: 12px 15px 12px 45px; border-radius: 30px;
            border: 1px solid var(--border); background: var(--white);
            color: var(--dark); font-weight: 500; font-size: 0.95rem; outline: none;
            transition: var(--transition);
        }
        .filter-input:focus { border-color: var(--primary); box-shadow: 0 0 0 3px var(--primary-glow); }

        .select-wrapper { position: relative; flex: 1; min-width: 160px; }
        .filter-select {
            width: 100%; padding: 12px 35px 12px 20px; border-radius: 30px;
            border: 1px solid var(--border); background: var(--white);
            color: var(--dark); font-weight: 600; font-size: 0.9rem; outline: none;
            cursor: pointer; appearance: none; -webkit-appearance: none; transition: var(--transition);
        }
        .filter-select:focus { border-color: var(--primary); }
        
        /* --- FIXED ICON ARROW RENDER HERE --- */
        .select-wrapper::after {
            content: '\eed8'; /* Fixed Unicode string for Boxicons chevron-down */
            font-family: 'boxicons' !important;
            position: absolute; right: 18px; top: 50%; transform: translateY(-50%);
            color: var(--gray); pointer-events: none; font-size: 1.1rem;
        }

        /* --- MATERIAL GRID CARDS --- */
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 30px; }

        .card {
            background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(10px); padding: 25px; border-radius: var(--radius);
            box-shadow: var(--shadow); transition: var(--transition); display: flex; flex-direction: column; align-items: flex-start; 
            position: relative; border: 1px solid var(--border); overflow: hidden;
        }
        .card:hover { transform: translateY(-8px); box-shadow: var(--shadow-hover); }

        /* Thumbnail Image Box Styling */
        .card-thumb {
            width: 100%; height: 165px; object-fit: cover; border-radius: 14px;
            margin-bottom: 15px; border: 1px solid rgba(0,0,0,0.05); background: #f1f5f9;
        }

        .icon-box {
            width: 55px; height: 55px; border-radius: 14px; display: flex; align-items: center; justify-content: center;
            font-size: 1.6rem; margin-bottom: 15px; transition: var(--transition);
            background: rgba(15, 23, 42, 0.05); color: var(--dark);
        }
        .card:hover .icon-box { transform: scale(1.05) rotate(3deg); background: var(--primary-glow); color: var(--primary); }

        .card h3 { font-size: 1.25rem; color: var(--dark); margin-bottom: 6px; font-weight: 800; line-height: 1.4; }
        .card p { color: var(--gray); font-size: 0.92rem; margin-bottom: 20px; line-height: 1.6; flex-grow: 1; font-weight: 500;}

        /* Metadata Badges */
        .badge-container { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 12px; }
        .badge {
            padding: 4px 10px; border-radius: 30px; font-size: 0.72rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.3px; display: inline-flex; align-items: center; gap: 4px;
        }
        .badge-public { background: rgba(16, 185, 129, 0.15); color: #10b981; }
        .badge-private { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
        .badge-class { background: rgba(59, 130, 246, 0.12); color: #3b82f6; text-transform: none; }
        .badge-format { background: rgba(15, 23, 42, 0.06); color: var(--dark); }

        /* --- ACTION BUTTONS --- */
        .btn-group { display: flex; gap: 12px; width: 100%; margin-top: auto; }
        .btn {
            padding: 12px 18px; border-radius: 12px; font-weight: 700; font-size: 0.9rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 6px; flex: 1;
        }
        
        .btn-open { background: var(--blue); color: var(--white); box-shadow: 0 4px 12px var(--blue-glow); }
        .btn-open:hover { background: #2563eb; transform: translateY(-2px); }

        .btn-danger { background: #fee2e2; color: #ef4444; }
        .btn-danger:hover { background: var(--primary); color: var(--white); transform: translateY(-2px); box-shadow: 0 6px 15px var(--primary-glow); }

        form { margin: 0; display: flex; flex: 1; }
        form button { width: 100%; }

        .no-results {
            grid-column: 1 / -1; background: rgba(255, 255, 255, 0.5); text-align: center;
            padding: 50px; border-radius: var(--radius); border: 1px dashed var(--gray);
            color: var(--gray); font-weight: 500; font-size: 1.1rem; display: none;
        }

        /* --- MASTER TEMPLATE RESPONSIVENESS --- */
        @media (max-width: 1024px) {
            .nav-menu .nav-link span { display: none; }
            .nav-menu .nav-link { max-width: 44px; padding: 10px; }
            .header-area { flex-direction: column; align-items: flex-start; gap: 20px; padding: 25px; }
        }
        
        @media (max-width: 768px) {
            .top-nav { flex-direction: column; justify-content: center; border-radius: 20px; top: 10px; padding: 15px; }
            .brand { width: 100%; justify-content: center; margin-bottom: 5px; }
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
            
            .filter-panel { flex-direction: column; align-items: stretch; }
            .search-wrapper, .select-wrapper { min-width: 100%; max-width: 100%; }
            
            .header-area h2 { font-size: 1.8rem; }
        }

        /* Ultra-mobile specific tweaks for the grid layout */
        @media (max-width: 480px) {
            .header-area { padding: 20px; }
            
            .filter-panel { padding: 15px; gap: 10px; }
            
            /* Overrides the 320px grid minimum to safely stretch elements on tiny phones */
            .grid { grid-template-columns: 1fr; gap: 20px; }
            .card { width: 100%; max-width: 100%; }
            .btn-group { flex-direction: column; }
        }
    </style>
</head>
<body>

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-shield-x'></i> NumSolve Admin</div>
        <ul class="nav-menu">
            <li><a href="${pageContext.request.contextPath}/dashboard/admin.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="${pageContext.request.contextPath}/admin_materials.jsp" class="nav-link active"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
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
                <h2><i class='bx bx-library' style="color: var(--primary); font-size: 2.4rem;"></i> Platform Repository</h2>
                <p>Global architectural management across unrestricted public and private academic components.</p>
            </div>
        </div>

        <div class="filter-panel animated-panel delay-1">
            <div class="search-wrapper">
                <i class='bx bx-search'></i>
                <input type="text" id="materialSearch" class="filter-input" placeholder="Search by topic, description, or uploader...">
            </div>
            
            <div class="select-wrapper">
                <select id="visibilityFilter" class="filter-select">
                    <option value="all">All Access Levels</option>
                    <option value="public">🌐 Public Bank</option>
                    <option value="private">🔒 Private (Classes)</option>
                </select>
            </div>

            <div class="select-wrapper">
                <select id="classFilter" class="filter-select">
                    <option value="all">All Classes</option>
                </select>
            </div>

            <div class="select-wrapper">
                <select id="typeFilter" class="filter-select">
                    <option value="all">All Formats</option>
                    <option value="pdf">PDF Document</option>
                    <option value="doc">Word Doc</option>
                    <option value="link">External Link</option>
                    <option value="video">Video Tutorial</option>
                </select>
            </div>
        </div>

        <div class="grid animated-panel delay-2" id="materialsGrid">
            <% 
                if(list.isEmpty()){ 
            %>
                <div class="no-results" style="display: block;">No materials currently deployed inside the repository database.</div>
            <% 
                } else { 
                    for (LearningMaterial m : list) {
                        boolean isPublic = (m.getClassId() == null || m.getClassId() == 0);
                        String formatType = m.getMaterialType() != null ? m.getMaterialType().toLowerCase() : "unknown";
                        String className = m.getClassName() != null ? m.getClassName() : "";
            %>
            <div class="card" 
                 data-topic="<%= m.getTopic() != null ? m.getTopic().toLowerCase() : "" %>" 
                 data-desc="<%= m.getDescription() != null ? m.getDescription().toLowerCase() : "" %>"
                 data-uploader="<%= m.getUploaderName() != null ? m.getUploaderName().toLowerCase() : "" %>"
                 data-visibility="<%= isPublic ? "public" : "private" %>" 
                 data-class="<%= className.toLowerCase().trim() %>"
                 data-type="<%= formatType %>">
                
                <% if (m.getPhotoPath() != null && !m.getPhotoPath().trim().isEmpty()) { %>
                    <img src="${pageContext.request.contextPath}/<%= m.getPhotoPath() %>" class="card-thumb" alt="Cover Image">
                <% } else { %>
                    <div class="icon-box">
                        <i class='bx <%= formatType.contains("video") ? "bx-video" : formatType.contains("link") ? "bx-link" : "bx-file-blank" %>'></i>
                    </div>
                <% } %>

                <div class="badge-container">
                    <span class="badge badge-<%= isPublic ? "public" : "private" %>">
                        <%= isPublic ? "🌐 Public" : "🔒 Private" %>
                    </span>
                    <% if(!isPublic && !className.isEmpty()) { %>
                        <span class="badge badge-class"><i class='bx bxs-graduation'></i> <%= className %></span>
                    <% } %>
                    <span class="badge badge-format"><%= m.getMaterialType() %></span>
                </div>

                <h3><%= m.getTopic() %></h3>
                <p><%= m.getDescription() %></p>

                <div class="btn-group">
                    <a href="${pageContext.request.contextPath}/<%= m.getFilePath() %>" target="_blank" class="btn btn-open">
                        <i class='bx bx-link-external'></i> View
                    </a>

                    <form method="post" action="${pageContext.request.contextPath}/deleteMaterial" onsubmit="return confirm('Are you sure you want to completely drop this resource item?');">
                        <input type="hidden" name="id" value="<%= m.getMaterialId() %>">
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
            <div class="no-results" id="searchFeedback">No materials match your specified filtering criteria.</div>
        </div>
    </main>

    <script>
        document.addEventListener("DOMContentLoaded", function () {
            const searchInput = document.getElementById("materialSearch");
            const visibilityFilter = document.getElementById("visibilityFilter");
            const classFilter = document.getElementById("classFilter");
            const typeFilter = document.getElementById("typeFilter");
            const cards = document.querySelectorAll("#materialsGrid .card");
            const feedback = document.getElementById("searchFeedback");

            // Dynamically populate Class Filter from present card attributes to minimize extra backend queries
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

            function filterMaterials() {
                const searchValue = searchInput.value.toLowerCase().trim();
                const visibilityValue = visibilityFilter.value;
                const classValue = classFilter.value;
                const typeValue = typeFilter.value;
                let visibleCount = 0;

                cards.forEach(card => {
                    const topic = card.getAttribute("data-topic");
                    const desc = card.getAttribute("data-desc");
                    const uploader = card.getAttribute("data-uploader");
                    const visibility = card.getAttribute("data-visibility");
                    const cardClass = card.getAttribute("data-class");
                    const type = card.getAttribute("data-type");

                    const matchesSearch = topic.includes(searchValue) || desc.includes(searchValue) || uploader.includes(searchValue);
                    const matchesVisibility = (visibilityValue === "all") || (visibility === visibilityValue);
                    const matchesClass = (classValue === "all") || (cardClass === classValue);
                    const matchesType = (typeValue === "all") || (type.includes(typeValue));

                    if (matchesSearch && matchesVisibility && matchesClass && matchesType) {
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

            searchInput.addEventListener("input", filterMaterials);
            visibilityFilter.addEventListener("change", filterMaterials);
            classFilter.addEventListener("change", filterMaterials);
            typeFilter.addEventListener("change", filterMaterials);
        });
    </script>
</body>
</html>