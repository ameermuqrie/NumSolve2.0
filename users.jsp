<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,model.User,dao.UserDAO" %>
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
    List<User> userList = new UserDAO().getAllUsers();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Manage Users – NumSolve</title>
    
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
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
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
        .select-wrapper::after {
            content: '\eed8'; /* Fixed Unicode string for Boxicons chevron-down */
            font-family: 'boxicons' !important;
            position: absolute; right: 18px; top: 50%; transform: translateY(-50%);
            color: var(--gray); pointer-events: none; font-size: 1.1rem;
        }

        /* --- USERS TABLE CARD --- */
        .card {
            background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(10px);
            border-radius: var(--radius); overflow: hidden;
            box-shadow: var(--shadow); border: 1px solid var(--border);
            transition: var(--transition); padding: 0;
            /* Support horizontal scrolling on smaller screens natively */
            width: 100%;
        }

        .table-responsive {
            width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }

        .data-table { width: 100%; border-collapse: collapse; text-align: left; }
        .data-table th {
            padding: 18px 25px; background: rgba(255, 255, 255, 0.5); border-bottom: 2px solid var(--border);
            color: var(--dark); font-weight: 700; text-transform: uppercase; font-size: 0.85rem; letter-spacing: 0.5px;
        }
        .data-table td {
            padding: 18px 25px; border-bottom: 1px solid rgba(0,0,0,0.05); vertical-align: middle; font-weight: 500;
        }
        .data-table tbody tr { transition: var(--transition); }
        .data-table tbody tr:hover { background: rgba(255, 255, 255, 0.6); }

        /* --- ROLE TAGS & BUTTONS --- */
        .role-tag { 
            padding: 6px 14px; border-radius: 30px; font-size: 0.75rem; 
            font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; 
            display: inline-block; text-align: center; min-width: 90px;
        }
        .role-admin { background-color: rgba(239, 68, 68, 0.15); color: #ef4444; } /* Red */
        .role-educator { background-color: rgba(139, 92, 246, 0.15); color: #8b5cf6; } /* Purple */
        .role-student { background-color: rgba(16, 185, 129, 0.15); color: #10b981; } /* Green */

        .btn-delete { 
            display: inline-flex; align-items: center; justify-content: center; 
            width: 38px; height: 38px; border-radius: 10px; background: rgba(239, 68, 68, 0.1); 
            color: #ef4444; text-decoration: none; transition: var(--transition); 
            font-size: 1.2rem; margin: 0 auto;
        }
        .btn-delete:hover { background: #ef4444; color: white; transform: scale(1.05); box-shadow: 0 4px 10px var(--primary-glow);}

        .user-id { color: var(--gray); font-size: 0.9rem; font-family: monospace; }
        .user-name { font-weight: 600; color: var(--dark); }

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

        /* Ultra-mobile specific tweaks for the users page */
        @media (max-width: 480px) {
            .header-area { padding: 20px; }
            .header-area h2 { font-size: 1.6rem; }
            .header-area p { font-size: 0.95rem; }
            
            /* Stack filter inputs */
            .filter-panel { flex-direction: column; padding: 15px; gap: 10px; }
            .search-wrapper, .select-wrapper { width: 100%; min-width: 100%; }
            
            /* Keep table structured, but scrollable */
            .data-table th, .data-table td { padding: 12px 15px; font-size: 0.85rem; white-space: nowrap; }
        }
    </style>
</head>
<body>

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-shield-x'></i> NumSolve Admin</div>
        <ul class="nav-menu">
            <li><a href="${pageContext.request.contextPath}/dashboard/admin.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="${pageContext.request.contextPath}/admin/admin_materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>            
            <li><a href="${pageContext.request.contextPath}/users.jsp" class="nav-link active"><i class='bx bxs-user-account'></i> <span>Users</span></a></li>
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
                <h2><i class='bx bxs-user-account' style="color: var(--primary); font-size: 2.4rem;"></i> User Management</h2>
                <p>Monitor accounts, verify credentials, and manage system access.</p>
            </div>
            <a href="${pageContext.request.contextPath}/profile.jsp" class="profile-link">
                <div class="user-profile">
                    <div class="avatar"><%= u.getFullName().charAt(0) %></div>
                    <span><%= u.getFullName() %></span>
                </div>
            </a>
        </div>

        <div class="filter-panel animated-panel delay-2">
            <div class="search-wrapper">
                <i class='bx bx-search'></i>
                <input type="text" id="searchInput" class="filter-input" onkeyup="filterTable()" placeholder="Search by Username or Full Name...">
            </div>
            
            <div class="select-wrapper">
                <select id="roleFilter" class="filter-select" onchange="filterTable()">
                    <option value="all">All Roles</option>
                    <option value="student">Student</option>
                    <option value="educator">Educator</option>
                    <option value="admin">Admin</option>
                </select>
            </div>
        </div>

        <div class="card animated-panel delay-3">
            <div class="table-responsive">
                <table class="data-table" id="userTable">
                    <thead>
                        <tr>
                            <th width="10%">ID</th>
                            <th width="25%">Username</th>
                            <th width="35%">Full Name</th>
                            <th width="15%" style="text-align: center;">Role</th>
                            <th width="15%" style="text-align: center;">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for(User user : userList) { 
                            String roleName = "Unknown"; String roleClass = "";
                            if("R001".equals(user.getRoleId())) { roleName="Admin"; roleClass="role-admin"; }
                            else if("R002".equals(user.getRoleId())) { roleName="Educator"; roleClass="role-educator"; }
                            else if("R003".equals(user.getRoleId())) { roleName="Student"; roleClass="role-student"; }
                        %>
                        <tr>
                            <td class="user-id">#<%= user.getUserId() %></td>
                            <td class="user-name"><%= user.getUsername() %></td>
                            <td style="color: var(--gray);"><%= user.getFullName() %></td>
                            <td style="text-align: center;">
                                <span class="role-tag <%= roleClass %>"><%= roleName %></span>
                            </td>
                            <td style="text-align: center;">
                                <% if(user.getUserId() != u.getUserId()) { %>
                                    <a href="${pageContext.request.contextPath}/deleteUser?id=<%= user.getUserId() %>" class="btn-delete" title="Delete User" onclick="return confirm('Are you sure you want to permanently delete this user account?');">
                                        <i class='bx bx-trash'></i>
                                    </a>
                                <% } else { %> 
                                    <span style="color:var(--gray); font-size:0.85rem; font-weight: 600; background: rgba(0,0,0,0.05); padding: 6px 12px; border-radius: 20px;">(You)</span> 
                                <% } %>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
            <div id="noResults" style="display:none; text-align:center; padding:50px; color:var(--gray); font-weight: 500; font-size: 1.1rem;">
                <i class='bx bx-search-alt' style="font-size: 3rem; margin-bottom: 15px; display: block; opacity: 0.5;"></i>
                No users found matching your search criteria.
            </div>
        </div>
    </main>

<script>
    function filterTable() {
        var input = document.getElementById("searchInput").value.toLowerCase().trim();
        var roleFilter = document.getElementById("roleFilter").value.toLowerCase();
        var table = document.getElementById("userTable");
        var tr = table.getElementsByTagName("tr");
        var hasResults = false;

        for (var i = 1; i < tr.length; i++) {
            var tdUsername = tr[i].getElementsByTagName("td")[1];
            var tdFullname = tr[i].getElementsByTagName("td")[2];
            var tdRole = tr[i].getElementsByTagName("td")[3];

            if (tdUsername && tdFullname && tdRole) {
                var usernameVal = (tdUsername.textContent || tdUsername.innerText).toLowerCase().trim();
                var fullnameVal = (tdFullname.textContent || tdFullname.innerText).toLowerCase().trim();
                var roleVal = (tdRole.textContent || tdRole.innerText).toLowerCase().trim();

                var matchesSearch = (usernameVal.indexOf(input) > -1) || (fullnameVal.indexOf(input) > -1);
                var matchesRole = (roleFilter === "all") || (roleVal === roleFilter);

                if (matchesSearch && matchesRole) { 
                    tr[i].style.display = ""; 
                    hasResults = true; 
                } else { 
                    tr[i].style.display = "none"; 
                }
            }
        }
        
        // Toggle the table header and empty state message based on results
        var thead = table.getElementsByTagName("thead")[0];
        if (hasResults) {
            thead.style.display = "";
            document.getElementById("noResults").style.display = "none";
        } else {
            thead.style.display = "none";
            document.getElementById("noResults").style.display = "block";
        }
    }
</script>
</body>
</html>