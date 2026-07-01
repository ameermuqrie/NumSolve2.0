<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.User" %>
<%
    // Security & Session Check
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    // Added request.getContextPath() for correct redirection on deployment
    if (u == null) { response.sendRedirect(request.getContextPath() + "/login.jsp"); return; }
    
    // Set Role Class for Dynamic Theming (Safe fallback if roleId is missing)
    String roleId = (u.getRoleId() != null) ? u.getRoleId() : "R003";
    String roleClass = "role-" + roleId;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Recommendation | NumSolve</title>
    
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

        /* Default (Admin - Red Glass) */
        body.role-R001 { 
            --primary: #ef4444; --primary-hover: #dc2626; --primary-glow: rgba(239, 68, 68, 0.3);
            --bg-1: #fee2e2; --bg-2: #fecaca; --bg-3: #fca5a5;
            --nav-hover: rgba(239, 68, 68, 0.1);
        }
        /* Educator - Purple Glass */
        body.role-R002 { 
            --primary: #8b5cf6; --primary-hover: #7c3aed; --primary-glow: rgba(139, 92, 246, 0.3);
            --bg-1: #ede9fe; --bg-2: #ddd6fe; --bg-3: #c4b5fd;
            --nav-hover: rgba(139, 92, 246, 0.1);
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

        /* --- FLOATING GLASS NAV (MATCHED EXACTLY TO LOGS.JSP) --- */
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
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 900px; width: 100%; margin: 0 auto; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; 
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); padding: 30px 40px;
            border-radius: var(--radius); box-shadow: var(--shadow); border: 1px solid var(--border);
        }
        .header-area h2 { font-size: 2.2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area p { color: var(--gray); font-size: 1.1rem; margin-top: 5px; font-weight: 500;}

        /* --- PREMIUM BUTTONS --- */
        .btn {
            padding: 14px 25px; border-radius: 12px; font-weight: 700; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; z-index: 2; position: relative;
        }
        .btn i { font-size: 1.2rem; transition: var(--transition); }
        .btn:hover i { transform: translateX(3px); }

        /* VIBE FIX: Glass-Gradient Primary Button */
        .btn-primary { 
            background-color: var(--primary); /* Base color behind the glass layer */
            background-image: linear-gradient(135deg, rgba(255,255,255,0.2) 0%, rgba(255,255,255,0) 100%);
            color: var(--white); 
            box-shadow: 0 8px 25px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.4); 
            border: 1px solid rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(10px);
            overflow: hidden;
        }
        .btn-primary:hover { 
            background-color: var(--primary-hover); 
            transform: translateY(-3px); 
            box-shadow: 0 12px 30px var(--primary-glow), inset 0 1px 0 rgba(255, 255, 255, 0.6); 
        }

        .btn-secondary { background: rgba(255, 255, 255, 0.8); color: var(--dark); border: 1px solid var(--border); }
        .btn-secondary:hover { background: var(--white); transform: translateY(-3px); box-shadow: var(--shadow); }

        /* --- AI RECOMMENDER UI (GLASS CARD) --- */
        .ai-container { 
            background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(10px); 
            border-radius: var(--radius); box-shadow: var(--shadow); 
            border: 1px solid var(--border); overflow: hidden;
            transition: var(--transition);
        }
        .ai-container:hover { box-shadow: var(--shadow-hover); }
        
        .ai-header { 
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-hover) 100%); 
            color: var(--white); padding: 35px; text-align: center; 
            box-shadow: 0 5px 15px rgba(0,0,0,0.05);
        }
        .ai-header i { font-size: 3.5rem; margin-bottom: 10px; animation: float 3s ease-in-out infinite; }
        @keyframes float {
            0% { transform: translateY(0px); }
            50% { transform: translateY(-10px); }
            100% { transform: translateY(0px); }
        }
        .ai-header h2 { font-weight: 800; letter-spacing: -0.5px;}

        .ai-body { padding: 40px; }
        
        /* Tabs */
        .tabs { display: flex; border-bottom: 2px solid rgba(0,0,0,0.05); margin-bottom: 30px; gap: 10px;}
        .tab { 
            flex: 1; text-align: center; padding: 15px; cursor: pointer; 
            font-weight: 600; color: var(--gray); transition: var(--transition); 
            display: flex; align-items: center; justify-content: center; gap: 8px;
            border-radius: 12px 12px 0 0;
        }
        .tab:hover { color: var(--primary); background: rgba(255, 255, 255, 0.5); }
        .tab.active { border-bottom: 3px solid var(--primary); color: var(--primary); background: rgba(255, 255, 255, 0.8);}

        /* Text Input - VIBE FIX: Frosted Glass without harsh borders */
        .text-area-wrapper { position: relative; }
        
        .text-area-wrapper textarea { 
            width: 100%; height: 160px; padding: 22px; 
            border: 1px solid rgba(255, 255, 255, 0.6); 
            border-radius: 16px; font-size: 1.05rem; color: var(--dark);
            background: rgba(241, 245, 249, 0.4); 
            box-shadow: inset 0 4px 8px rgba(0,0,0,0.03); 
            resize: none; outline: none; transition: var(--transition); 
            line-height: 1.6;
        }
        
        .text-area-wrapper textarea::placeholder {
            color: #94a3b8; font-weight: 400;
        }

        .text-area-wrapper textarea:hover {
            background: rgba(255, 255, 255, 0.5);
        }

        .text-area-wrapper textarea:focus { 
            border-color: rgba(255, 255, 255, 0.9); 
            background: rgba(255, 255, 255, 0.8); 
            box-shadow: 0 10px 30px var(--primary-glow), 0 0 0 3px rgba(255, 255, 255, 0.5);
            transform: translateY(-2px); 
        }

        /* Image Upload */
        .upload-zone { 
            border: 2px dashed rgba(255, 255, 255, 0.8); border-radius: 16px; padding: 60px 20px; 
            text-align: center; cursor: pointer; transition: var(--transition); 
            background: rgba(241, 245, 249, 0.4); 
            box-shadow: inset 0 4px 8px rgba(0,0,0,0.03); 
        }
        
        .upload-zone:hover { 
            background: rgba(255, 255, 255, 0.8); 
            border-color: rgba(255, 255, 255, 0.9);
            border-style: solid; 
            box-shadow: 0 10px 30px var(--primary-glow), 0 0 0 3px rgba(255, 255, 255, 0.5);
            transform: translateY(-2px); 
        }
        
        .upload-zone i { font-size: 4.5rem; color: var(--primary); margin-bottom: 15px; transition: var(--transition); }
        .upload-zone:hover i { transform: scale(1.1); }

        /* Scanning Animation */
        .scanner-container { display: none; text-align: center; padding: 50px 20px; }
        .scanner-bar { 
            width: 100%; height: 6px; background: rgba(0,0,0,0.05); border-radius: 50px; 
            position: relative; overflow: hidden; margin-top: 30px; 
        }
        .scanner-bar::after { 
            content: ''; position: absolute; top: 0; left: -50%; width: 50%; height: 100%; 
            background: var(--primary); border-radius: 50px; box-shadow: 0 0 10px var(--primary);
            animation: scan 1.5s infinite ease-in-out; 
        }
        @keyframes scan { 0% { left: -50%; } 100% { left: 100%; } }

        /* Verdict Box */
        #verdictSection { 
            display: none; background: rgba(255, 255, 255, 0.9); border: 2px solid #22c55e; 
            padding: 40px; border-radius: 20px; text-align: center; margin-top: 10px; 
            animation: fadeInUp 0.6s ease forwards; opacity: 0; box-shadow: 0 15px 35px rgba(34, 197, 94, 0.1);
        }
        
        .verdict-success-btn {
            background: #10b981; color: white; font-size: 1.05rem; padding: 14px 30px; 
            border-radius: 12px; display: inline-flex; align-items: center; gap: 8px;
            text-decoration: none; font-weight: 700; transition: var(--transition); border: none; cursor: pointer;
        }
        .verdict-success-btn:hover { background: #059669; transform: translateY(-3px); box-shadow: 0 10px 20px rgba(16, 185, 129, 0.3); }

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
            
            .header-area { flex-direction: column; align-items: flex-start; padding: 20px; }
            .header-area h2 { font-size: 1.8rem; }
        }
    </style>
</head>
<body class="<%= roleClass %>">

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            
            <%-- Admin (R001) Links --%>
            <% if ("R001".equals(roleId)) { %>
                <li><a href="${pageContext.request.contextPath}/dashboard/admin.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="${pageContext.request.contextPath}/users.jsp" class="nav-link"><i class='bx bxs-user-account'></i> <span>Users</span></a></li>
                <li><a href="${pageContext.request.contextPath}/logs.jsp" class="nav-link"><i class='bx bxs-server'></i> <span>Logs</span></a></li>
                <li><a href="${pageContext.request.contextPath}/reports.jsp" class="nav-link"><i class='bx bxs-chart'></i> <span>Reports</span></a></li>
                <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>

            <%-- Educator (R002) Links --%>
            <% } else if ("R002".equals(roleId)) { %>
                <li><a href="${pageContext.request.contextPath}/dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link active"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                <li><a href="${pageContext.request.contextPath}/manage_classes.jsp" class="nav-link"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
                <li><a href="${pageContext.request.contextPath}/educatorQuizzes" class="nav-link"><i class='bx bx-task'></i><span>Quizzes</span></a></li>
                <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
                
            <%-- Student (R003) Links --%>
            <% } else { %>
                <li><a href="${pageContext.request.contextPath}/dashboard/student.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link active"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                <li><a href="${pageContext.request.contextPath}/student_classes.jsp" class="nav-link"><i class='bx bxs-group'></i> <span>Classes</span></a></li>            
                <li><a href="${pageContext.request.contextPath}/StudentDashboardServlet" class="nav-link"><i class='bx bxs-edit'></i> <span>Quizzes</span></a></li>
                <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
            <% } %>
            
        </ul>
    </nav>

    <main class="main-content">
        <div class="header-area animated-panel delay-1">
            <div>
                <h2><i class='bx bxs-bulb' style="color: var(--primary);"></i> AI Method Recommender</h2>
                <p>Describe your problem or upload an image of your question</p>
            </div>
            <a href="${pageContext.request.contextPath}/computations.jsp" class="btn btn-secondary"><i class='bx bx-list-ul'></i> View All Records</a>
        </div>

        <div class="ai-container animated-panel delay-2">
            <div class="ai-header">
                <i class='bx bx-brain'></i>
                <h2 style="font-size: 1.8rem; margin-bottom: 5px;">NumSolve AI Advisor</h2>
                <p style="opacity: 0.9; font-weight: 300;">Let our intelligent engine analyze your problem</p>
            </div>

            <div class="ai-body">
                <div class="tabs" id="inputTabs">
                    <div class="tab active" id="tabText" onclick="switchTab('text')"><i class='bx bx-text'></i> Type Question</div>
                  
                </div>

                <div id="sectionText" class="text-area-wrapper">
                    <textarea id="userQuestion" placeholder="e.g., I need to find the area under the curve y = x^2 from 0 to 5 using parabolic arcs..."></textarea>
                    <button class="btn btn-primary" style="width: 100%; margin-top: 20px; padding: 18px; font-size: 1.1rem;" onclick="analyzeText()">
                        <i class='bx bx-analyse'></i> Analyze Text
                    </button>
                </div>

                <div id="sectionImage" style="display: none;">
                    <div class="upload-zone" onclick="document.getElementById('fileInput').click()">
                        <i class='bx bx-cloud-upload'></i>
                        <h3 style="color: var(--dark); margin-bottom: 5px; font-weight: 700;">Click to upload or drag & drop</h3>
                        <p style="color: var(--gray); font-weight: 500;">PNG, JPG, or PDF up to 5MB</p>
                        <input type="file" id="fileInput" style="display: none;" accept="image/*" onchange="analyzeImage(this)">
                    </div>
                </div>

                <div id="scanner" class="scanner-container">
                    <i class='bx bx-loader-alt bx-spin' style="font-size: 4.5rem; color: var(--primary);"></i>
                    <h3 style="margin-top: 25px; color: var(--dark); font-weight: 800;">Analyzing Mathematical Context...</h3>
                    <p style="color: var(--gray); font-size: 1rem; margin-top: 8px; font-weight: 500;">Sending data to secure backend AI engine...</p>
                    <div class="scanner-bar"></div>
                </div>

                <div id="verdictSection">
                    <div style="display: inline-flex; align-items: center; justify-content: center; width: 70px; height: 70px; background: #dcfce7; color: #10b981; border-radius: 50%; font-size: 2.5rem; margin-bottom: 20px; box-shadow: 0 10px 20px rgba(16, 185, 129, 0.2);">
                        <i class='bx bx-check'></i>
                    </div>
                    <p style="color: #166534; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; font-size: 0.95rem;">Recommended Method</p>
                    <h2 id="verdictTitle" style="color: #047857; font-size: 2.5rem; margin: 10px 0 20px 0; font-weight: 800; letter-spacing: -1px;">Method Name</h2>
                    
                    <div style="background: rgba(220, 252, 231, 0.5); padding: 20px; border-radius: 12px; margin-bottom: 30px; border: 1px solid #bbf7d0;">
                        <p id="verdictReason" style="color: #166534; font-size: 1.1rem; margin: 0; line-height: 1.7; font-weight: 500;"></p>
                    </div>

                    <div style="display: flex; gap: 15px; justify-content: center;">
                        <button onclick="resetRecommender()" class="btn btn-secondary" style="border-color: #bbf7d0; background: white; color: #166534; font-weight: 700;">
                            <i class='bx bx-refresh'></i> Try Another
                        </button>
                        <a href="#" id="computeLink" class="verdict-success-btn">
                            Use this Method <i class='bx bx-right-arrow-alt'></i>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </main>

<script>
    function switchTab(type) {
        document.getElementById('tabText').classList.remove('active');
        document.getElementById('tabImage').classList.remove('active');
        document.getElementById('sectionText').style.display = 'none';
        document.getElementById('sectionImage').style.display = 'none';
        
        hideVerdict();
        document.getElementById('inputTabs').style.display = 'flex';

        if(type === 'text') {
            document.getElementById('tabText').classList.add('active');
            document.getElementById('sectionText').style.display = 'block';
        } else {
            document.getElementById('tabImage').classList.add('active');
            document.getElementById('sectionImage').style.display = 'block';
        }
    }

    function hideVerdict() {
        document.getElementById('verdictSection').style.display = 'none';
        document.getElementById('scanner').style.display = 'none';
    }

    function resetRecommender() {
        hideVerdict();
        document.getElementById('userQuestion').value = "";
        document.getElementById('fileInput').value = "";
        
        if(document.getElementById('tabText').classList.contains('active')) {
            document.getElementById('sectionText').style.display = 'block';
        } else {
            document.getElementById('sectionImage').style.display = 'block';
        }
        document.getElementById('inputTabs').style.display = 'flex';
    }

    function analyzeText() {
        const text = document.getElementById('userQuestion').value;
        if(text.trim() === "") {
            alert("Please type a question first!"); 
            return;
        }

        // Hide input panel, show scanning animation
        document.getElementById('inputTabs').style.display = 'none';
        document.getElementById('sectionText').style.display = 'none';
        document.getElementById('scanner').style.display = 'block';

        // Securely call the backend Java Servlet API bridge
        fetch('${pageContext.request.contextPath}/aiRecommend', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: 'question=' + encodeURIComponent(text)
        })
        .then(response => {
            if (!response.ok) throw new Error('Network response was not ok');
            return response.text(); 
        })
        .then(rawText => {
            console.log("Raw AI Response:", rawText); // Prints to your F12 console for debugging

            // BULLETPROOF EXTRACTION: Find exactly where the JSON starts and ends
            let startIndex = rawText.indexOf('{');
            let endIndex = rawText.lastIndexOf('}');
            
            if (startIndex !== -1 && endIndex !== -1) {
                // Slice out ONLY the JSON part
                let cleanJsonString = rawText.substring(startIndex, endIndex + 1);
                
                // Parse it securely
                let data = JSON.parse(cleanJsonString);
                
                // Display the gorgeous UI
                showVerdict(data.methodId, data.methodName, data.reason);
            } else {
                throw new Error("No JSON format detected in the AI response.");
            }
        })
        .catch(error => {
            console.error('Error during analysis:', error);
            showVerdict(
                "M001", 
                "Bisection Method (Safe Fallback)", 
                "An error occurred while parsing the AI's response. Defaulting to Bisection as our safest bracketing algorithm."
            );
        });
    }

    function analyzeImage(input) {
        if (input.files && input.files[0]) {
            document.getElementById('inputTabs').style.display = 'none';
            document.getElementById('sectionImage').style.display = 'none';
            document.getElementById('scanner').style.display = 'block';
            document.querySelector('#scanner h3').innerText = "Running Mathematical OCR Engine...";

            // Mock Image Analysis - Eventually, you can send FormData with the image to your servlet
            setTimeout(() => {
                showVerdict("M012", "First Derivative Approximation", "Image analysis complete. We detected a discrete grid space requiring rate-of-change mapping.");
                document.querySelector('#scanner h3').innerText = "Analyzing Mathematical Context...";
            }, 2500);
        }
    }

    function showVerdict(methodId, methodName, reason) {
        document.getElementById('scanner').style.display = 'none';
        document.getElementById('verdictTitle').innerText = methodName;
        document.getElementById('verdictReason').innerText = reason;
        
        // Added the dynamic context path here as well for proper JavaScript routing
        let linkPath = "${pageContext.request.contextPath}/solver.jsp?method=" + methodId;
        if (methodName.toLowerCase().includes("derivative") || methodId === "M012") {
             // Example appending a scheme default if required by your solver.jsp
             linkPath += "&scheme=central"; 
        }
        
        document.getElementById('computeLink').href = linkPath;
        document.getElementById('verdictSection').style.display = 'block';
    }
</script>
</body>
</html>