<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="dao.*, dao.DBConnection, java.util.*, java.util.Calendar, java.sql.*, model.User" %>
<%
    // Prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Security Check
    User u = (User) session.getAttribute("user");
    if (u == null || !"R001".equals(u.getRoleId())) { 
        // FIXED: Context path applied to Java redirect
        response.sendRedirect(request.getContextPath() + "/login.jsp"); 
        return; 
    }
    
    AdminDAO adminDao = new AdminDAO();
    UserDAO userDao = new UserDAO();
    int currentYear = Calendar.getInstance().get(Calendar.YEAR);

    // --- 1. ORIGINAL USER COUNTS ---
    int countAdmins = adminDao.getCount("R001");
    int countEducators = adminDao.getCount("R002");
    int countStudents = adminDao.getCount("R003");
    int countMaterials = adminDao.getMaterialCount();
    int totalUsers = countAdmins + countEducators + countStudents;

    // --- 2. ORIGINAL GRAPH DATA ---
    int[] studentData = userDao.getMonthlyRegistrations("R003", currentYear);
    int[] educatorData = userDao.getMonthlyRegistrations("R002", currentYear);
    int[] materialData = adminDao.getMonthlyMaterials(currentYear);
    
    // --- 3. MATERIAL TYPES MAP ---
    Map<String, Integer> typeMap = adminDao.getMaterialTypeCounts();
    StringBuilder typeLabels = new StringBuilder("[");
    StringBuilder typeCounts = new StringBuilder("[");
    if(typeMap != null) {
        for (Map.Entry<String, Integer> entry : typeMap.entrySet()) {
            typeLabels.append("'").append(entry.getKey()).append("',");
            typeCounts.append(entry.getValue()).append(",");
        }
    }
    typeLabels.append("]"); typeCounts.append("]");

    // --- 4. METRICS (Classes, Quizzes, Public/Private Tracking, and Monthly Growth) ---
    int totalClasses = 0;
    int totalQuizzes = 0, publicQuizzes = 0, privateQuizzes = 0;
    int publicMaterials = 0, privateMaterials = 0;
    
    // Arrays for Line Charts
    int[] classGrowthData = new int[12];
    int[] quizGrowthData = new int[12];

    // Arrays for Educator Breakdown (Pie Charts)
    StringBuilder classEduLabels = new StringBuilder("["); StringBuilder classEduData = new StringBuilder("[");
    StringBuilder quizEduLabels = new StringBuilder("["); StringBuilder quizEduData = new StringBuilder("[");
    StringBuilder matEduLabels = new StringBuilder("["); StringBuilder matEduData = new StringBuilder("[");

    try (Connection conn = DBConnection.getConnection()) {
        
        // --- CLASSES ---
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM class"); ResultSet rs = ps.executeQuery()) {
            if(rs.next()) totalClasses = rs.getInt(1);
        }
        try (PreparedStatement ps = conn.prepareStatement("SELECT MONTH(created_date), COUNT(*) FROM class WHERE YEAR(created_date) = ? GROUP BY MONTH(created_date)")) {
            ps.setInt(1, currentYear);
            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next()) { classGrowthData[rs.getInt(1) - 1] = rs.getInt(2); }
            }
        } catch(Exception e) { /* Ignore */ }
        
        // Classes by Educator
        try (PreparedStatement ps = conn.prepareStatement("SELECT u.full_name, COUNT(c.class_id) FROM class c JOIN users u ON c.user_id = u.user_id GROUP BY u.user_id"); ResultSet rs = ps.executeQuery()) {
            while(rs.next()) {
                classEduLabels.append("'").append(rs.getString(1).replace("'", "\\'")).append("',");
                classEduData.append(rs.getInt(2)).append(",");
            }
        } catch(Exception e) {}
        
        
        // --- QUIZZES ---
        try (PreparedStatement ps = conn.prepareStatement("SELECT visibility, COUNT(*) FROM quiz GROUP BY visibility"); ResultSet rs = ps.executeQuery()) {
            while(rs.next()) {
                String vis = rs.getString(1);
                int count = rs.getInt(2);
                totalQuizzes += count;
                if("Visible".equalsIgnoreCase(vis) || "Public".equalsIgnoreCase(vis)) publicQuizzes += count;
                else privateQuizzes += count;
            }
        } catch(Exception e) { /* Fallback */ }
        try (PreparedStatement ps = conn.prepareStatement("SELECT MONTH(created_date), COUNT(*) FROM quiz WHERE YEAR(created_date) = ? GROUP BY MONTH(created_date)")) {
            ps.setInt(1, currentYear);
            try (ResultSet rs = ps.executeQuery()) {
                while(rs.next()) { quizGrowthData[rs.getInt(1) - 1] = rs.getInt(2); }
            }
        } catch(Exception e) { /* Ignore */ }

        // Quizzes by Educator
        try (PreparedStatement ps = conn.prepareStatement("SELECT u.full_name, COUNT(q.quiz_id) FROM quiz q JOIN users u ON q.user_id = u.user_id GROUP BY u.user_id"); ResultSet rs = ps.executeQuery()) {
            while(rs.next()) {
                quizEduLabels.append("'").append(rs.getString(1).replace("'", "\\'")).append("',");
                quizEduData.append(rs.getInt(2)).append(",");
            }
        } catch(Exception e) {}


        // --- MATERIALS ---
        try (PreparedStatement ps = conn.prepareStatement("SELECT CASE WHEN class_id IS NULL THEN 'Public' ELSE 'Private' END as vis, COUNT(*) FROM learning_material GROUP BY CASE WHEN class_id IS NULL THEN 'Public' ELSE 'Private' END"); ResultSet rs = ps.executeQuery()) {
            while(rs.next()) {
                String vis = rs.getString(1);
                int count = rs.getInt(2);
                if("Public".equalsIgnoreCase(vis)) publicMaterials += count;
                else privateMaterials += count;
            }
        } catch(Exception e) { /* Fallback */ }

        // Materials by Educator
        try (PreparedStatement ps = conn.prepareStatement("SELECT u.full_name, COUNT(m.material_id) FROM learning_material m JOIN users u ON m.user_id = u.user_id GROUP BY u.user_id"); ResultSet rs = ps.executeQuery()) {
            while(rs.next()) {
                matEduLabels.append("'").append(rs.getString(1).replace("'", "\\'")).append("',");
                matEduData.append(rs.getInt(2)).append(",");
            }
        } catch(Exception e) {}

    } catch (Exception e) {
        e.printStackTrace();
    }

    // Finalize Arrays
    classEduLabels.append("]"); classEduData.append("]");
    quizEduLabels.append("]"); quizEduData.append("]");
    matEduLabels.append("]"); matEduData.append("]");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Report Analysis – NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
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
        .delay-3 { animation-delay: 0.45s; }

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

        /* --- GLASS STAT CARDS --- */
        .stats-grid {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); 
            gap: 20px; margin-bottom: 25px;
        }
        .stat-card { 
            background: rgba(255, 255, 255, 0.65); backdrop-filter: blur(10px);
            padding: 25px; border-radius: var(--radius); box-shadow: var(--shadow); 
            text-align: left; cursor: pointer; transition: var(--transition); 
            border: 2px solid transparent; position: relative; overflow: hidden;
            display: flex; flex-direction: column; justify-content: center;
        }
        .stat-card:hover { transform: translateY(-5px); box-shadow: var(--shadow-hover); }
        .stat-card.active { border-color: var(--primary); background: rgba(255, 255, 255, 0.9); box-shadow: 0 10px 30px var(--primary-glow); }
        
        .stat-number { font-size: 2.5rem; font-weight: 800; color: var(--dark); margin-bottom: 5px; line-height: 1; z-index: 2; position: relative;}
        .stat-label { color: var(--gray); font-size: 0.9rem; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; z-index: 2; position: relative;}
        
        .stat-subtext { margin-top: 10px; font-size: 0.85rem; font-weight: 600; color: var(--gray); display: flex; gap: 10px; z-index: 2; position: relative;}
        .badge-pub { color: #10b981; background: rgba(16, 185, 129, 0.15); padding: 4px 10px; border-radius: 20px; }
        .badge-priv { color: #ef4444; background: rgba(239, 68, 68, 0.15); padding: 4px 10px; border-radius: 20px; }
        .badge-info { color: #3b82f6; background: rgba(59, 130, 246, 0.15); padding: 4px 10px; border-radius: 20px; }
        .badge-edu { color: #8b5cf6; background: rgba(139, 92, 246, 0.15); padding: 4px 10px; border-radius: 20px; }

        .stat-icon {
            position: absolute; right: -15px; bottom: -20px; font-size: 7rem;
            color: rgba(0,0,0,0.03); transform: rotate(-15deg); z-index: 1; transition: var(--transition);
        }
        .stat-card.active .stat-icon { color: var(--primary-glow); transform: rotate(0deg) scale(1.1); }

        /* --- CHART SECTION --- */
        .chart-card { 
            background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(10px); 
            padding: 30px; border-radius: var(--radius); box-shadow: var(--shadow); 
            border: 1px solid var(--border); display: flex; flex-direction: column; height: 550px;
        }
        .chart-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .chart-title { font-size: 1.3rem; font-weight: 800; color: var(--dark); display: flex; align-items: center; gap: 10px; }
        
        .chart-controls { display: flex; gap: 10px; flex-wrap: wrap; justify-content: flex-end;}
        .chart-controls button { 
            padding: 8px 18px; font-size: 0.85rem; border: 1px solid var(--border); 
            background: var(--white); cursor: pointer; border-radius: 30px; 
            transition: var(--transition); color: var(--dark); font-weight: 600;
        }
        .chart-controls button:hover, .chart-controls button.active { 
            background: var(--primary); color: var(--white); border-color: var(--primary); 
            box-shadow: 0 4px 15px var(--primary-glow);
        }
        
        .chart-container { flex: 1; position: relative; width: 100%; }

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
            
            /* Report Specific Adjustments */
            .stats-grid { grid-template-columns: repeat(2, 1fr); }
            .chart-card { height: 450px; padding: 20px; }
            .chart-header { flex-direction: column; align-items: flex-start; gap: 15px; }
            .chart-controls { justify-content: flex-start; }
        }

        /* FIXED: Fine-tuned ultra-mobile overlap and layout styling */
        @media (max-width: 480px) {
            .header-area { padding: 20px; }
            .header-area h2 { font-size: 1.6rem; }
            .header-area p { font-size: 0.95rem; }
            
            /* Stack stat cards vertically on very small screens to avoid squishing */
            .stats-grid { grid-template-columns: 1fr; }
            
            .chart-card { height: 400px; padding: 15px; }
            .chart-controls { width: 100%; display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
            .chart-controls button { width: 100%; justify-content: center; }
        }
    </style>
</head>
<body>

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-shield-x'></i> NumSolve Admin</div>
        <ul class="nav-menu">
            <li><a href="${pageContext.request.contextPath}/dashboard/admin.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="${pageContext.request.contextPath}/admin_materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="${pageContext.request.contextPath}/users.jsp" class="nav-link"><i class='bx bxs-user-account'></i> <span>Users</span></a></li>
            <li><a href="${pageContext.request.contextPath}/logs.jsp" class="nav-link"><i class='bx bxs-server'></i> <span>Logs</span></a></li>
            <li><a href="${pageContext.request.contextPath}/reports.jsp" class="nav-link active"><i class='bx bxs-chart'></i> <span>Reports</span></a></li>
            <li><a href="${pageContext.request.contextPath}/admin_quizzes.jsp" class="nav-link"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
            <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
        </ul>
    </nav>

    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <div>
                <h2><i class='bx bxs-chart' style="color: var(--primary); font-size: 2.4rem;"></i> Interactive System Analytics</h2>
                <p>Review comprehensive statistics across classes, quiz parameters, and publication states.</p>
            </div>
            <a href="${pageContext.request.contextPath}/profile.jsp" class="profile-link">
                <div class="user-profile">
                    <div class="avatar"><%= u.getFullName().charAt(0) %></div>
                    <span><%= u.getFullName() %></span>
                </div>
            </a>
        </div>
        
        <div class="stats-grid animated-panel delay-2">
            <div class="stat-card active" id="card-users" onclick="switchMainChart('users')">
                <i class='bx bxs-group stat-icon'></i>
                <div class="stat-number"><%= totalUsers %></div>
                <div class="stat-label">System Users</div>
                <div class="stat-subtext">
                    <span class="badge-info"><i class='bx bxs-graduation'></i> <%= countStudents %> Stu</span>
                    <span class="badge-edu"><i class='bx bxs-chalkboard'></i> <%= countEducators %> Edu</span>
                </div>
            </div>

            <div class="stat-card" id="card-classes" onclick="switchMainChart('classes')">
                <i class='bx bxs-graduation stat-icon'></i>
                <div class="stat-number"><%= totalClasses %></div>
                <div class="stat-label">Active Classes</div>
                <div class="stat-subtext">
                    <span class="badge-edu"><i class='bx bx-check-shield'></i> Monitored</span>
                </div>
            </div>

            <div class="stat-card" id="card-quizzes" onclick="switchMainChart('quizzes')">
                <i class='bx bxs-file-blank stat-icon'></i>
                <div class="stat-number"><%= totalQuizzes %></div>
                <div class="stat-label">Quizzes Deployed</div>
                <div class="stat-subtext">
                    <span class="badge-pub"><i class='bx bxs-lock-open-alt'></i> <%= publicQuizzes %> Pub</span>
                    <span class="badge-priv"><i class='bx bxs-lock-alt'></i> <%= privateQuizzes %> Priv</span>
                </div>
            </div>

            <div class="stat-card" id="card-materials" onclick="switchMainChart('materials')">
                <i class='bx bxs-book-open stat-icon'></i>
                <div class="stat-number"><%= countMaterials %></div>
                <div class="stat-label">Study Materials</div>
                <div class="stat-subtext">
                    <span class="badge-pub"><i class='bx bxs-lock-open-alt'></i> <%= publicMaterials %> Pub</span>
                    <span class="badge-priv"><i class='bx bxs-lock-alt'></i> <%= privateMaterials %> Priv</span>
                </div>
            </div>
        </div>

        <div class="chart-card animated-panel delay-3">
            <div class="chart-header">
                <h3 class="chart-title" id="chartTitle">
                    <i class='bx bx-bar-chart-square'></i> Analysis Overview
                </h3>
                
                <div id="chartControls" class="chart-controls">
                    </div>
            </div>

            <div class="chart-container">
                <canvas id="mainChart"></canvas>
            </div>
        </div>
    </main>
    <script>
        const ctx = document.getElementById('mainChart').getContext('2d');
        let myChart = null;

        // --- BASIC DATA MAPS ---
        const pieData = [<%= countAdmins %>, <%= countEducators %>, <%= countStudents %>];
        const studentData = <%= Arrays.toString(studentData) %>;
        const educatorData = <%= Arrays.toString(educatorData) %>;
        const materialData = <%= Arrays.toString(materialData) %>;
        const matTypeLabels = <%= typeLabels.toString() %>;
        const matTypeData = <%= typeCounts.toString() %>;
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

        // --- VISIBILITY DATA MAPS ---
        const quizPieData = [<%= publicQuizzes %>, <%= privateQuizzes %>];
        const matVisPieData = [<%= publicMaterials %>, <%= privateMaterials %>];

        // --- LINE GRAPH GROWTH MAPS ---
        const quizGrowthData = <%= Arrays.toString(quizGrowthData) %>;
        const classGrowthData = <%= Arrays.toString(classGrowthData) %>;

        // --- EDUCATOR BREAKDOWN DATA MAPS ---
        const classEduLabels = <%= classEduLabels.toString() %>;
        const classEduData = <%= classEduData.toString() %>;

        const quizEduLabels = <%= quizEduLabels.toString() %>;
        const quizEduData = <%= quizEduData.toString() %>;

        const matEduLabels = <%= matEduLabels.toString() %>;
        const matEduData = <%= matEduData.toString() %>;

        // Premium UI Palette Colors
        const colorAdmin = '#ef4444';    // Red
        const colorEducator = '#8b5cf6'; // Purple
        const colorStudent = '#3b82f6';  // Blue
        const colorMaterial = '#f59e0b'; // Amber
        const colorQuiz = '#0891b2';     // Cyan

        // Generous array of beautiful colors for multiple educators
        const dynamicColors = ['#ef4444', '#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#06b6d4', '#ec4899', '#f97316', '#14b8a6', '#6366f1'];

        // Helper to get font size based on screen width
        const getFontSize = () => window.innerWidth < 480 ? 11 : 14;

        function switchMainChart(category, subType = 'default') {
            // Reset active states for stat cards
            document.querySelectorAll('.stat-card').forEach(el => el.classList.remove('active'));
            if(document.getElementById('card-' + category)) {
                document.getElementById('card-' + category).classList.add('active');
            }

            const controlsDiv = document.getElementById('chartControls');
            controlsDiv.innerHTML = ''; // Clear existing buttons

            if(myChart) myChart.destroy();

            const commonDoughnutOptions = { 
                responsive: true, 
                maintainAspectRatio: false, 
                plugins: { 
                    legend: { position: 'bottom', labels: { font: { family: 'Poppins', size: getFontSize() }, padding: 15 } } 
                },
                layout: { padding: 10 }
            };

            if (category === 'users') {
                controlsDiv.innerHTML = 
                    '<button class="' + (subType === 'default' ? 'active' : '') + '" onclick="switchMainChart(\'users\', \'default\')">Role Distribution</button>' +
                    '<button class="' + (subType === 'students' ? 'active' : '') + '" onclick="switchMainChart(\'users\', \'students\')">Student Growth</button>' +
                    '<button class="' + (subType === 'educators' ? 'active' : '') + '" onclick="switchMainChart(\'users\', \'educators\')">Educator Growth</button>';

                if (subType === 'default') {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bxs-pie-chart-alt-2'></i> User Role Distribution";
                    myChart = new Chart(ctx, {
                        type: 'doughnut',
                        data: { 
                            labels: ['Admins', 'Educators', 'Students'], 
                            datasets: [{ 
                                data: pieData, 
                                backgroundColor: [colorAdmin, colorEducator, colorStudent],
                                borderWidth: 0, hoverOffset: 8
                            }] 
                        },
                        options: commonDoughnutOptions
                    });
                } else if (subType === 'students') {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bx-line-chart'></i> Student Registration Growth (<%= currentYear %>)";
                    renderLine(studentData, colorStudent, 'New Students');
                } else if (subType === 'educators') {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bx-line-chart'></i> Educator Registration Growth (<%= currentYear %>)";
                    renderLine(educatorData, colorEducator, 'New Educators');
                }

            } else if (category === 'classes') {
                controlsDiv.innerHTML = 
                    '<button class="' + (subType === 'default' ? 'active' : '') + '" onclick="switchMainChart(\'classes\', \'default\')">Class Creation Growth</button>' +
                    '<button class="' + (subType === 'edu_pie' ? 'active' : '') + '" onclick="switchMainChart(\'classes\', \'edu_pie\')">By Educator</button>';

                if (subType === 'edu_pie') {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bxs-pie-chart-alt-2'></i> Classes Created per Educator";
                    myChart = new Chart(ctx, {
                        type: 'doughnut',
                        data: { 
                            labels: classEduLabels, 
                            datasets: [{ 
                                data: classEduData, 
                                backgroundColor: dynamicColors,
                                borderWidth: 0, hoverOffset: 8
                            }] 
                        },
                        options: commonDoughnutOptions
                    });
                } else {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bx-line-chart'></i> Active Classes Growth (<%= currentYear %>)";
                    renderLine(classGrowthData, colorQuiz, 'New Classes'); 
                }

            } else if (category === 'quizzes') {
                controlsDiv.innerHTML = 
                    '<button class="' + (subType === 'default' ? 'active' : '') + '" onclick="switchMainChart(\'quizzes\', \'default\')">Deployment Trend</button>' +
                    '<button class="' + (subType === 'pie' ? 'active' : '') + '" onclick="switchMainChart(\'quizzes\', \'pie\')">Visibility Breakdown</button>' +
                    '<button class="' + (subType === 'edu_pie' ? 'active' : '') + '" onclick="switchMainChart(\'quizzes\', \'edu_pie\')">By Educator</button>';

                if (subType === 'pie') {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bxs-pie-chart-alt-2'></i> Quiz Visibility (Public vs. Private)";
                    myChart = new Chart(ctx, {
                        type: 'doughnut',
                        data: { 
                            labels: ['Public Quizzes', 'Private Quizzes'], 
                            datasets: [{ 
                                data: quizPieData, 
                                backgroundColor: ['#10b981', '#ef4444'], // Green vs Red
                                borderWidth: 0, hoverOffset: 8
                            }] 
                        },
                        options: commonDoughnutOptions
                    });
                } else if (subType === 'edu_pie') {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bxs-pie-chart-alt-2'></i> Quizzes Created per Educator";
                    myChart = new Chart(ctx, {
                        type: 'doughnut',
                        data: { 
                            labels: quizEduLabels, 
                            datasets: [{ 
                                data: quizEduData, 
                                backgroundColor: dynamicColors,
                                borderWidth: 0, hoverOffset: 8
                            }] 
                        },
                        options: commonDoughnutOptions
                    });
                } else {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bx-line-chart'></i> Quiz Deployment Growth (<%= currentYear %>)";
                    renderLine(quizGrowthData, colorQuiz, 'New Quizzes'); 
                }

            } else if (category === 'materials') {
                controlsDiv.innerHTML = 
                    '<button class="' + (subType === 'default' ? 'active' : '') + '" onclick="switchMainChart(\'materials\', \'default\')">Upload Trend</button>' +
                    '<button class="' + (subType === 'pie' ? 'active' : '') + '" onclick="switchMainChart(\'materials\', \'pie\')">Format Breakdown</button>' +
                    '<button class="' + (subType === 'visibility' ? 'active' : '') + '" onclick="switchMainChart(\'materials\', \'visibility\')">Visibility Breakdown</button>' +
                    '<button class="' + (subType === 'edu_pie' ? 'active' : '') + '" onclick="switchMainChart(\'materials\', \'edu_pie\')">By Educator</button>';

                if (subType === 'pie') {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bxs-pie-chart-alt-2'></i> Material Type Breakdown";
                    myChart = new Chart(ctx, {
                        type: 'doughnut',
                        data: { 
                            labels: matTypeLabels, 
                            datasets: [{ 
                                data: matTypeData, 
                                backgroundColor: [colorAdmin, '#10b981', colorStudent, colorMaterial, colorEducator],
                                borderWidth: 0, hoverOffset: 8
                            }] 
                        },
                        options: commonDoughnutOptions
                    });
                } else if (subType === 'visibility') {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bxs-pie-chart-alt-2'></i> Material Visibility (Public vs. Private)";
                    myChart = new Chart(ctx, {
                        type: 'doughnut',
                        data: { 
                            labels: ['Public (Bank)', 'Private (Class)'], 
                            datasets: [{ 
                                data: matVisPieData, 
                                backgroundColor: ['#10b981', '#ef4444'], // Green vs Red
                                borderWidth: 0, hoverOffset: 8
                            }] 
                        },
                        options: commonDoughnutOptions
                    });
                } else if (subType === 'edu_pie') {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bxs-pie-chart-alt-2'></i> Materials Uploaded per Educator";
                    myChart = new Chart(ctx, {
                        type: 'doughnut',
                        data: { 
                            labels: matEduLabels, 
                            datasets: [{ 
                                data: matEduData, 
                                backgroundColor: dynamicColors,
                                borderWidth: 0, hoverOffset: 8
                            }] 
                        },
                        options: commonDoughnutOptions
                    });
                } else {
                    document.getElementById('chartTitle').innerHTML = "<i class='bx bx-line-chart'></i> Material Upload Growth (<%= currentYear %>)";
                    renderLine(materialData, colorMaterial, 'Materials Uploaded');
                }
            }
        }

        function renderLine(data, color, label) {
            myChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: months,
                    datasets: [{ 
                        label: label, 
                        data: data, 
                        borderColor: color, 
                        backgroundColor: color + '22', 
                        borderWidth: 3, pointBackgroundColor: color,
                        pointBorderWidth: 2, pointRadius: window.innerWidth < 480 ? 3 : 5, 
                        pointHoverRadius: 8,
                        fill: true, tension: 0.4 
                    }]
                },
                options: { 
                    responsive: true,
                    maintainAspectRatio: false, 
                    plugins: { 
                        legend: { display: false }, 
                        tooltip: { titleFont: { family: 'Poppins' }, bodyFont: { family: 'Poppins', size: getFontSize() }, padding: 10 } 
                    },
                    layout: { padding: { top: 10, right: 10, bottom: 10, left: 0 } },
                    scales: { 
                        y: { beginAtZero: true, grid: { color: 'rgba(0,0,0,0.05)', drawBorder: false }, ticks: { font: { family: 'Poppins', size: getFontSize() }, padding: 10 } },
                        x: { grid: { display: false, drawBorder: false }, ticks: { font: { family: 'Poppins', size: getFontSize() } } }
                    } 
                }
            });
        }

        // Initialize first chart on page load
        switchMainChart('users');

        // Add event listener to redraw charts cleanly if user flips their phone orientation
        window.addEventListener('resize', () => {
            const activeBtn = document.querySelector('.chart-controls button.active');
            if(activeBtn) {
                activeBtn.click(); // Re-trigger the active chart render to adapt sizes
            }
        });
    </script>
</body>
</html>
