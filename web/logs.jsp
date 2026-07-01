<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, java.util.*, java.io.*" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User u = (User) session.getAttribute("user");
    // Security Check
    if (u == null || !"R001".equals(u.getRoleId())) { response.sendRedirect(request.getContextPath() + "/login.jsp"); return; }

    // --- NEW FILE-BASED LOGGING LOGIC ---
    List<String[]> activities = new ArrayList<>();
    String logFilePath = application.getRealPath("/WEB-INF/system_logs.txt");
    File logFile = new File(logFilePath);

    if (logFile.exists()) {
        try (BufferedReader reader = new BufferedReader(new FileReader(logFile))) {
            String line;
            while ((line = reader.readLine()) != null) {
                // Split the line based on the delimiter we set in LogManager (||)
                String[] columns = line.split("\\|\\|");
                if (columns.length >= 4) {
                    // LogManager Format: [0]=Timestamp, [1]=Username, [2]=Role, [3]=Details
                    // We map it to what your JSP expects: [0]=Username, [1]=Details, [2]=Timestamp, [3]=Role
                    activities.add(new String[]{ columns[1], columns[3], columns[0], columns[2] });
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        // Reverse the list so the newest activities appear at the top
        Collections.reverse(activities);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Logs – NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES (Admin Red Theme) --- */
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

        /* --- MAIN CONTENT & HEADER --- */
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1400px; width: 100%; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; 
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); padding: 30px 40px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
        }
        .header-area h2 { font-size: 2.2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area p { color: var(--gray); font-size: 1.1rem; margin-top: 5px; font-weight: 500;}

        .user-profile {
            display: flex; align-items: center; gap: 14px; background: var(--white);
            padding: 8px 20px 8px 8px; border-radius: 50px; box-shadow: 0 8px 20px rgba(0,0,0,0.04);
            border: 1px solid var(--border); transition: var(--transition);
        }
        .user-profile:hover { box-shadow: var(--shadow-hover); transform: translateY(-3px); border-color: var(--primary); }
        .user-profile span { font-weight: 700; color: var(--dark); font-size: 0.95rem; }
        
        .avatar {
            width: 45px; height: 45px; border-radius: 50%; background: var(--primary); color: var(--white); 
            display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 1.2rem; 
            overflow: hidden; box-shadow: 0 4px 10px var(--primary-glow);
        }
        .profile-link { text-decoration: none; }

        /* --- INTERACTIVE MULTI-FILTER BAR --- */
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

        .select-wrapper { position: relative; flex: 1; min-width: 140px; }
        .filter-select {
            width: 100%; padding: 12px 35px 12px 20px; border-radius: 30px;
            border: 1px solid var(--border); background: var(--white);
            color: var(--dark); font-weight: 600; font-size: 0.9rem; outline: none;
            cursor: pointer; appearance: none; -webkit-appearance: none; transition: var(--transition);
        }
        .filter-select:focus { border-color: var(--primary); }
        .select-wrapper::after {
            content: '\eed8';
            font-family: 'boxicons' !important;
            position: absolute; right: 18px; top: 50%; transform: translateY(-50%);
            color: var(--gray); pointer-events: none; font-size: 1.1rem;
        }

        .date-input-field {
            padding: 11px 20px; border-radius: 30px; border: 1px solid var(--border);
            background: var(--white); color: var(--dark); font-weight: 600; font-size: 0.9rem;
            outline: none; transition: var(--transition); width: 100%;
        }
        .date-input-field:focus { border-color: var(--primary); }

        /* --- LOGS TABLE --- */
        .card {
            background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(10px);
            border-radius: var(--radius); overflow: hidden;
            box-shadow: var(--shadow); border: 1px solid var(--border);
            transition: var(--transition); padding: 0;
        }

        .table-responsive { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        .data-table { width: 100%; border-collapse: collapse; text-align: left; min-width: 800px; }
        .data-table th {
            padding: 18px 25px; background: rgba(255, 255, 255, 0.5); border-bottom: 2px solid var(--border);
            color: var(--dark); font-weight: 700; text-transform: uppercase; font-size: 0.85rem; letter-spacing: 0.5px;
        }
        .data-table td {
            padding: 18px 25px; border-bottom: 1px solid rgba(0,0,0,0.05); vertical-align: middle; font-weight: 500;
        }
        .data-table tbody tr { transition: var(--transition); }
        .data-table tbody tr:hover { background: rgba(255, 255, 255, 0.6); }

        /* --- LOG USER AND BADGES --- */
        .log-user { display: flex; align-items: center; gap: 15px; }
        .log-avatar {
            width: 38px; height: 38px; border-radius: 10px; background: rgba(239, 68, 68, 0.1);
            color: var(--primary); display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 1.1rem; box-shadow: 0 4px 10px rgba(239, 68, 68, 0.05);
            flex-shrink: 0;
        }
        .log-name { font-weight: 600; color: var(--dark); }
        .log-activity { color: #334155; font-size: 0.95rem; font-weight: 500; }
        .log-date { color: var(--gray); font-size: 0.9rem; font-family: monospace; font-weight: 600; white-space: nowrap; }

        /* --- CONTEXTUAL ACTIVITY STATUS BADGES --- */
        .action-badge {
            padding: 5px 12px; border-radius: 30px; font-size: 0.75rem; 
            font-weight: 700; text-transform: uppercase; letter-spacing: 0.3px; 
            display: inline-flex; align-items: center; gap: 5px; white-space: nowrap;
        }
        .act-login { background-color: rgba(14, 165, 233, 0.15); color: #0284c7; }        /* Sky Blue */
        .act-register { background-color: rgba(16, 185, 129, 0.15); color: #10b981; }      /* Green */
        .act-material { background-color: rgba(245, 158, 11, 0.15); color: #d97706; }      /* Amber */
        .act-class { background-color: rgba(6, 182, 212, 0.15); color: #0891b2; }        /* Cyan */
        .act-quiz { background-color: rgba(139, 92, 246, 0.15); color: #8b5cf6; }          /* Purple */
        .act-generic { background-color: rgba(100, 116, 139, 0.15); color: #475569; }      /* Slate Gray */

        /* --- RESPONSIVENESS --- */
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
            .date-input-field { width: 100%; }
            
            .header-area h2 { font-size: 1.8rem; }
        }
    </style>
</head>
<body>

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-shield-x'></i> NumSolve Admin</div>
        <ul class="nav-menu">
            <li><a href="<%= request.getContextPath() %>/dashboard/admin.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="<%= request.getContextPath() %>/admin/admin_materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="<%= request.getContextPath() %>/users.jsp" class="nav-link"><i class='bx bxs-user-account'></i> <span>Users</span></a></li>
            <li><a href="<%= request.getContextPath() %>/logs.jsp" class="nav-link active"><i class='bx bxs-server'></i> <span>Logs</span></a></li>
            <li><a href="<%= request.getContextPath() %>/reports.jsp" class="nav-link"><i class='bx bxs-chart'></i> <span>Reports</span></a></li>
            <li><a href="<%= request.getContextPath() %>/admin_quizzes.jsp" class="nav-link"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
            <li><a href="<%= request.getContextPath() %>/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="<%= request.getContextPath() %>/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
        </ul>
    </nav>

    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <div>
                <h2><i class='bx bxs-server' style="color: var(--primary); font-size: 2.4rem;"></i> Live Operations Logs</h2>
                <p>Track multi-system events, authorization checkpoints, and resource modifications.</p>
            </div>
            <a href="<%= request.getContextPath() %>/profile.jsp" class="profile-link">
                <div class="user-profile">
                    <div class="avatar"><%= u.getFullName().charAt(0) %></div>
                    <span><%= u.getFullName() %></span>
                </div>
            </a>
        </div>

        <div class="filter-panel animated-panel delay-2">
            <div class="search-wrapper">
                <i class='bx bx-search'></i>
                <input type="text" id="searchInput" class="filter-input" placeholder="Search by details, username, or log entry contents..." onkeyup="filterTable()">
            </div>
            
            <div class="select-wrapper">
                <select id="roleFilter" class="filter-select" onchange="filterTable()">
                    <option value="all">All Account Roles</option>
                    <option value="Student">Students Only</option>
                    <option value="Educator">Educators Only</option>
                </select>
            </div>

            <div class="select-wrapper">
                <select id="actionTypeFilter" class="filter-select" onchange="filterTable()">
                    <option value="all">All Action Types</option>
                    <option value="login">Logins</option>
                    <option value="registration">Registrations</option>
                    <option value="material">Study Materials</option>
                    <option value="class">Class Management</option>
                    <option value="quiz">Quizzes & Tests</option>
                    <option value="generic">Other Logs</option>
                </select>
            </div>

            <div class="select-wrapper">
                <select id="timeframeType" class="filter-select" onchange="updateDateInput()">
                    <option value="date">By Date</option>
                    <option value="month">By Month</option>
                    <option value="year">By Year</option>
                </select>
            </div>

            <div style="flex: 1; min-width: 150px;">
                <input type="date" id="dateFilter" class="date-input-field" onchange="filterTable()" onkeyup="filterTable()">
            </div>
        </div>

        <div class="card animated-panel delay-3">
            <div class="table-responsive">
                <table class="data-table" id="logsTable">
                    <thead>
                        <tr>
                            <th width="22%">Operator Account</th>
                            <th width="15%">Event Category</th>
                            <th width="45%">Activity Details</th>
                            <th width="18%">Timestamp</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (activities.isEmpty()) { %>
                            <tr>
                                <td colspan="4" style="text-align:center; color:var(--gray); padding: 50px;">
                                    <i class='bx bx-info-circle' style="font-size: 3rem; margin-bottom: 15px; display: block; opacity: 0.5;"></i>
                                    No system records or activity updates found inside the environment logs.
                                </td>
                            </tr>
                        <% } else { 
                            for(String[] log : activities) { 
                                // Using log[3] because we mapped the Role perfectly from the text file array
                                String roleType = log[3]; 
                                
                                // Contextual pattern analysis for comprehensive audit trail mapping
                                String lowerActivity = log[1].toLowerCase();
                                String actionCategory = "generic";
                                String badgeClass = "act-generic";
                                String displayType = "System Audit";
                                
                                if(lowerActivity.contains("login") || lowerActivity.contains("logged in")) {
                                    actionCategory = "login"; badgeClass = "act-login"; displayType = "User Login";
                                } else if(lowerActivity.contains("register") || lowerActivity.contains("signup") || lowerActivity.contains("created a new account")) {
                                    actionCategory = "registration"; badgeClass = "act-register"; displayType = "New Account";
                                } else if(lowerActivity.contains("material") || lowerActivity.contains("document") || lowerActivity.contains("pdf")) {
                                    actionCategory = "material"; badgeClass = "act-material"; displayType = "Material Content";
                                } else if(lowerActivity.contains("class") || lowerActivity.contains("course") || lowerActivity.contains("enroll")) {
                                    actionCategory = "class"; badgeClass = "act-class"; displayType = "Class Management";
                                } else if(lowerActivity.contains("quiz") || lowerActivity.contains("question") || lowerActivity.contains("test")) {
                                    actionCategory = "quiz"; badgeClass = "act-quiz"; displayType = "Quiz System";
                                }
                        %>
                            <tr data-role="<%= roleType %>" data-action="<%= actionCategory %>">
                                <td>
                                    <div class="log-user">
                                        <div class="log-avatar"><%= log[0].charAt(0) %></div>
                                        <span class="log-name"><%= log[0] %></span>
                                    </div>
                                </td>
                                <td>
                                    <span class="action-badge <%= badgeClass %>"><%= displayType %></span>
                                </td>
                                <td class="log-activity"><%= log[1] %></td>
                                <td class="log-date"><%= log[2] %></td>
                            </tr>
                        <%  } 
                           } %>
                    </tbody>
                </table>
            </div>
            <div id="noResults" style="display:none; text-align:center; padding:50px; color:var(--gray); font-weight: 500; font-size: 1.1rem;">
                <i class='bx bx-search-alt' style="font-size: 3rem; margin-bottom: 15px; display: block; opacity: 0.5;"></i>
                No historical system logs found matching your combined filter rules.
            </div>
        </div>
    </main>

<script>
    // 1. TIMEFRAME TYPE COMPILER SWITCHER
    function updateDateInput() {
        var type = document.getElementById("timeframeType").value;
        var input = document.getElementById("dateFilter");
        
        input.value = ""; 
        
        if (type === "date") {
            input.type = "date";
        } else if (type === "month") {
            input.type = "month";
        } else if (type === "year") {
            input.type = "number";
            input.placeholder = "YYYY";
            input.min = "2020";
            input.max = "2100";
        }
        filterTable();
    }

    // 2. CONCURRENT MULTI-LAYER TABLE INTERPRETER FILTER
    function filterTable() {
        var searchInput = document.getElementById("searchInput").value.toUpperCase().trim();
        var roleSelect = document.getElementById("roleFilter").value;
        var actionSelect = document.getElementById("actionTypeFilter").value;
        
        var dateVal = document.getElementById("dateFilter").value;
        var dateType = document.getElementById("timeframeType").value;

        var table = document.getElementById("logsTable");
        var tr = table.getElementsByTagName("tr");
        var hasResults = false;

        for (var i = 1; i < tr.length; i++) {
            var tdUser = tr[i].getElementsByTagName("td")[0];
            var tdActivity = tr[i].getElementsByTagName("td")[2];
            var tdDate = tr[i].getElementsByTagName("td")[3];
            
            var rowRole = tr[i].getAttribute("data-role");
            var rowAction = tr[i].getAttribute("data-action");

            if (tdUser && tdActivity && tdDate) {
                var txtUser = tdUser.textContent || tdUser.innerText;
                var txtActivity = tdActivity.textContent || tdActivity.innerText;
                var txtDate = tdDate.textContent || tdDate.innerText;

                // LAYER 1: Full-Text Global Search Filter
                var matchSearch = (txtUser.toUpperCase().indexOf(searchInput) > -1) || 
                                  (txtActivity.toUpperCase().indexOf(searchInput) > -1);

                // LAYER 2: User Access Profile Filter
                var matchRole = (roleSelect === "all") || (rowRole === roleSelect);

                // LAYER 3: Application Event Category Filter
                var matchAction = (actionSelect === "all") || (rowAction === actionSelect);

                // LAYER 4: Granular Calendar Date Frame Matcher
                var matchDate = true;
                if (dateVal) {
                    if (dateType === "date") {
                        matchDate = txtDate.indexOf(dateVal) > -1;
                    } else if (dateType === "month") {
                        matchDate = txtDate.startsWith(dateVal);
                    } else if (dateType === "year") {
                        matchDate = txtDate.startsWith(dateVal);
                    }
                }

                // Execute rendering if row matches all filters simultaneously
                if (matchSearch && matchRole && matchAction && matchDate) {
                    tr[i].style.display = "";
                    hasResults = true;
                } else {
                    tr[i].style.display = "none";
                }
            }
        }

        // Toggle state and heading configurations based on return states
        var thead = table.getElementsByTagName("thead")[0];
        if (hasResults) {
            if(thead) thead.style.display = "";
            document.getElementById("noResults").style.display = "none";
        } else {
            if(thead) thead.style.display = "none";
            document.getElementById("noResults").style.display = "block";
        }
    }
</script>
</body>
</html>