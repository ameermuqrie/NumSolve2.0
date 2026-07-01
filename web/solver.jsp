<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.User" %>
<%
    // 1. Fetch the User object from the session (Matches AuthServlet)
    User currentUser = (User) session.getAttribute("user");
    
    // 2. Safely extract the roleId (defaults to Student / R003 if null)
    String roleId = "R003"; 
    if (currentUser != null && currentUser.getRoleId() != null) {
        roleId = currentUser.getRoleId();
    } else {
        // CURSOR FIX: Absolute redirect path to prevent session drop
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // 3. Set the default variables (Student / R003)
    String themeClass = "theme-student";
    String dashboardLink = request.getContextPath() + "/dashboard/student.jsp"; 

    // 4. Override variables if it is an Educator (R002) or Admin (R001)
    if ("R002".equals(roleId)) {
        themeClass = "theme-educator";
        dashboardLink = request.getContextPath() + "/dashboard/educator.jsp";
    } else if ("R001".equals(roleId)) {
        themeClass = "theme-admin";
        dashboardLink = request.getContextPath() + "/dashboard/admin.jsp";
    }

    // --- Auto-Load Logic ---
    String loadedId = request.getParameter("id"); 
    String loadedMethod = (String) session.getAttribute("loadMethodId");
    String loadedInputs = (String) session.getAttribute("loadInputData");
    
    if (loadedMethod == null) loadedMethod = request.getParameter("methodId");
    if (loadedInputs == null) loadedInputs = request.getParameter("inputData");

    if (session.getAttribute("loadMethodId") != null) {
        session.removeAttribute("loadMethodId");
        session.removeAttribute("loadInputData");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NumSolve Workspace</title>
    
    <script src="https://cdn.plot.ly/plotly-2.24.1.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/mathjs/11.8.0/math.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
    <link href="https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    
    <style>
        /* --- GLOBAL VARIABLES --- */
        :root {
            --primary: #3b82f6; 
            --primary-hover: #2563eb;
            --primary-glow: rgba(59, 130, 246, 0.3);
            
            --dark: #0f172a;
            --white: #ffffff;
            --gray: #64748b;
            --border: rgba(255, 255, 255, 0.4);
            --shadow: 0 10px 30px rgba(0,0,0,0.05);
            --shadow-hover: 0 20px 40px rgba(0,0,0,0.1);
            --transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
            --radius: 20px;
        }

        body.theme-educator {
            --primary: #8b5cf6;          
            --primary-hover: #7c3aed;
            --primary-glow: rgba(139, 92, 246, 0.3);
        }

        body.theme-admin {
            --primary: #ef4444;          
            --primary-hover: #dc2626;
            --primary-glow: rgba(239, 68, 68, 0.3);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 50%, #93c5fd 100%);
            background-attachment: fixed;
            color: var(--dark); 
            min-height: 100vh; 
            display: flex; 
            flex-direction: column; 
            align-items: center;
        }

        body.theme-educator { background: linear-gradient(135deg, #ede9fe 0%, #ddd6fe 50%, #c4b5fd 100%); }
        body.theme-admin { background: linear-gradient(135deg, #fee2e2 0%, #fecaca 50%, #fca5a5 100%); }

        /* --- ENTRANCE ANIMATIONS --- */
        @keyframes dropDown { from { opacity: 0; transform: translateY(-30px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeInUp { from { opacity: 0; transform: translateY(20px) scale(0.98); } to { opacity: 1; transform: translateY(0) scale(1); } }
        
        .animated-nav { animation: dropDown 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .animated-panel { animation: fadeInUp 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }

        /* --- FLOATING NAV (GLASSMORPHISM BASE) --- */
        .top-nav {
            width: 95%; max-width: 1500px; margin: 25px auto;
            background: rgba(255, 255, 255, 0.5); 
            backdrop-filter: blur(16px); 
            -webkit-backdrop-filter: blur(16px);
            padding: 12px 25px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: 0 15px 35px var(--primary-glow);
            border: 1px solid var(--border); z-index: 100; position: sticky; top: 25px;
            transition: var(--transition);
        }

        .brand { font-size: 1.5rem; font-weight: 800; display: flex; align-items: center; gap: 10px; color: var(--primary); }
        .brand i { font-size: 1.8rem; }
        
        .nav-menu { list-style: none; display: flex; align-items: center; gap: 8px; overflow-x: auto; scrollbar-width: none; }
        .nav-menu::-webkit-scrollbar { display: none; }

        .nav-link {
            display: flex; align-items: center; gap: 10px; padding: 10px; border-radius: 40px; color: var(--gray); 
            font-weight: 600; font-size: 0.95rem; text-decoration: none; max-width: 44px; white-space: nowrap; overflow: hidden;
            transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
        }

        .nav-link i { font-size: 1.4rem; min-width: 24px; text-align: center; }
        .nav-link span { opacity: 0; transform: translateX(-10px); transition: all 0.3s ease; }
        .nav-link:hover { background: rgba(255, 255, 255, 0.9); color: var(--primary); max-width: 160px; padding: 10px 20px; }
        .nav-link:hover span { opacity: 1; transform: translateX(0); }
        .nav-link.active { background: var(--primary); color: var(--white); box-shadow: 0 8px 20px var(--primary-glow); max-width: 160px; padding: 10px 20px; }
        .nav-link.active span { opacity: 1; transform: translateX(0); }

        .logout-item { margin-left: 10px; border-left: 1px solid var(--border); padding-left: 10px; }
        .logout-item .nav-link:hover { background: rgba(239, 68, 68, 0.1); color: #ef4444; }

        /* --- WORKSPACE GRID --- */
        .workspace {
            width: 95%; max-width: 1500px; margin: 0 auto;
            display: grid; grid-template-columns: 380px 1fr; gap: 30px; align-items: start; padding-bottom: 40px;
        }

        .card {
            background: rgba(255, 255, 255, 0.7); backdrop-filter: blur(10px); padding: 30px; border-radius: var(--radius);
            box-shadow: var(--shadow); transition: var(--transition); display: flex; flex-direction: column; 
            position: relative; border: 1px solid var(--border); overflow: hidden;
        }
        
        .card-title {
            font-size: 1.4rem; color: var(--dark); margin-bottom: 25px; font-weight: 800; z-index: 2; position: relative;
            display: flex; align-items: center; gap: 10px; width: 100%; border-bottom: 2px solid rgba(255,255,255,0.4); padding-bottom: 15px;
        }
        .card-title i { color: var(--primary); font-size: 1.8rem; }

        /* --- FORMS & INPUTS --- */
        .input-group { width: 100%; }
        .input-row { margin-bottom: 18px; width: 100%; z-index: 2; position: relative; }
        .input-row label, .method-selector > label { 
            display: block; font-weight: 600; font-size: 0.85rem; color: var(--dark); margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px; 
        }
        
        select, input[type="text"], input[type="number"] { 
            width: 100%; padding: 12px 16px; border-radius: 12px; border: 1px solid var(--border); 
            background: rgba(255, 255, 255, 0.6); font-size: 0.95rem; color: var(--dark); transition: var(--transition); 
        }
        select:focus, input:focus { outline: none; border-color: var(--primary); background: var(--white); box-shadow: 0 0 0 4px var(--primary-glow); }

        .btn {
            padding: 14px 25px; border-radius: 12px; font-weight: 700; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; width: 100%; z-index: 2; position: relative;
        }
        .btn i { font-size: 1.2rem; transition: var(--transition); }
        .btn:hover i { transform: translateX(5px); }
        .btn-primary { background: var(--primary); color: var(--white); box-shadow: 0 8px 15px var(--primary-glow); }
        .btn-primary:hover { background: var(--primary-hover); transform: translateY(-3px); box-shadow: 0 12px 20px var(--primary-glow); }

        .sidebar-actions { margin-top: 25px; display: flex; flex-direction: column; gap: 12px; width: 100%; }

        /* --- LAYERED TAB SYSTEM --- */
        .main-panels { display: flex; flex-direction: column; gap: 20px; width: 100%; }
        
        .tab-container {
            display: flex; gap: 12px; width: 100%; background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px);
            padding: 10px; border-radius: 16px; border: 1px solid var(--border); box-shadow: var(--shadow); z-index: 2; position: relative;
        }

        .tab-btn {
            flex: 1; padding: 14px 20px; border-radius: 12px; border: none; background: transparent;
            font-weight: 700; font-size: 1rem; color: var(--gray); cursor: pointer; transition: var(--transition);
            display: flex; align-items: center; justify-content: center; gap: 8px;
        }
        .tab-btn.active { background: var(--white); color: var(--primary); box-shadow: 0 4px 15px var(--primary-glow); }
        .tab-btn:hover:not(.active) { background: rgba(255, 255, 255, 0.8); color: var(--dark); }

        .tab-pane { display: none; width: 100%; animation: fadeInUp 0.4s ease forwards; }
        .tab-pane.active-pane { display: flex; flex-direction: column; }

        /* --- VISUALIZATION OUTPUT AREA --- */
        #graph {
            width: 100%; min-height: 450px; background: rgba(255,255,255,0.4); border: 2px dashed rgba(255,255,255,0.6); 
            border-radius: 16px; z-index: 2; position: relative;
        }

        /* --- DETAILS & TABLE SCROLLING --- */
        .details-box {
            background: var(--white); padding: 30px; border-radius: 16px; border: 1px solid rgba(0,0,0,0.05); 
            width: 100%; z-index: 2; position: relative; box-shadow: 0 10px 30px rgba(0,0,0,0.02);
        }
        
        .table-responsive { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; margin-top: 20px; }
        .data-table { width: 100%; border-collapse: collapse; min-width: 600px; font-size: 0.95rem; }
        .data-table th { background: transparent; color: var(--dark); padding: 15px; border-bottom: 2px solid rgba(0,0,0,0.1); font-weight: 800; text-align: center; text-transform: uppercase; font-size: 0.8rem; letter-spacing: 0.5px; }
        .data-table td { padding: 15px; border-bottom: 1px solid rgba(0,0,0,0.05); color: var(--gray); font-weight: 500; text-align: center; }
        .data-table tr:hover td { background: rgba(248, 250, 252, 0.8); color: var(--dark); }

        .math-box { 
            background-color: var(--white); border-left: 4px solid var(--primary); padding: 20px; border-radius: 12px; 
            font-family: monospace; font-size: 1.05rem; margin-bottom: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.02);
            color: var(--dark); line-height: 1.6; border: 1px solid rgba(0,0,0,0.03);
        }
        
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 25px; width: 100%; }
        .summary-card { background: var(--white); padding: 25px 20px; border-radius: 16px; text-align: center; border: 1px solid rgba(0,0,0,0.03); box-shadow: 0 4px 15px rgba(0,0,0,0.02); }
        .summary-card span { display: block; font-size: 0.8rem; color: var(--gray); margin-bottom: 10px; text-transform: uppercase; font-weight: 700; letter-spacing: 0.5px;}
        .summary-card strong { font-size: 1.8rem; color: var(--primary); font-weight: 800;}

        #resultArea:not(.hidden) + #emptyDetailsState { display: none !important; }

        .action-toolbar { display: flex; gap: 12px; justify-content: flex-end; margin-bottom: 10px; z-index: 2; position: relative;}
        .action-btn { background-color: rgba(255,255,255,0.7); color: var(--dark); border: 1px solid var(--border); padding: 10px 16px; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: var(--transition); }
        .action-btn:hover { background-color: var(--white); transform: translateY(-2px); box-shadow: var(--shadow); }

        .hidden { display: none !important; }

        /* --- RESPONSIVE BREAKPOINTS --- */
        @media (max-width: 1024px) {
            .nav-link span { display: none !important; }
            .nav-link:hover, .nav-link.active { max-width: 44px; padding: 10px; justify-content: center; }
            .nav-link i { margin: 0; }
            
            .workspace { grid-template-columns: 1fr; }
        }

        @media (max-width: 768px) {
            .top-nav { flex-direction: column; align-items: center; border-radius: 25px; gap: 15px; padding: 15px 20px; }
            .brand { justify-content: center; width: 100%; }
            .nav-menu { flex-direction: row; flex-wrap: wrap; justify-content: center; width: 100%; gap: 8px; }
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
        }
    </style>
</head>

<body onload="initPage()" class="<%= themeClass %>">

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            <li><a href="<%= dashboardLink %>" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="<%= request.getContextPath() %>/solver.jsp" class="nav-link active"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
            <li><a href="<%= request.getContextPath() %>/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
            <li><a href="<%= request.getContextPath() %>/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
            
            <% if ("R002".equals(roleId) || "R001".equals(roleId)) { %>
                <li><a href="<%= request.getContextPath() %>/manage_classes.jsp" class="nav-link"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
                <li><a href="<%= request.getContextPath() %>/educatorQuizzes" class="nav-link"><i class='bx bx-task'></i><span>Quizzes</span></a></li>
            <% } else { %>
                <li><a href="<%= request.getContextPath() %>/student_classes.jsp" class="nav-link"><i class='bx bxs-group'></i> <span>Classes</span></a></li>            
                <li><a href="<%= request.getContextPath() %>/StudentDashboardServlet" class="nav-link"><i class='bx bxs-edit'></i> <span>Quiz</span></a></li>
            <% } %>
            
            <li><a href="<%= request.getContextPath() %>/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="<%= request.getContextPath() %>/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="<%= request.getContextPath() %>/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
        </ul>
    </nav>

    <div class="workspace">
        
        <div class="card animated-panel delay-1">
            <div class="card-title"><i class='bx bx-math'></i> Parameter Inputs</div>
            
            <div class="method-selector" style="width: 100%;">
                <label for="methodSelect">Numerical Method</label>
                <select id="methodSelect" onchange="changeMethod()">
                    <optgroup label="Roots of Equations">
                        <option value="M001">Bisection Method</option>
                        <option value="M002">Newton-Raphson Method</option>
                        <option value="M003">Secant Method</option>
                        <option value="M010">False Position Method</option>
                    </optgroup>
                    <optgroup label="Interpolation">
                        <option value="M004">Linear Spline Interpolation</option>
                        <option value="M011">Lagrange Interpolation</option>
                    </optgroup>
                    <optgroup label="Numerical Integration">
                        <option value="M005">Trapezoidal Rule</option>
                        <option value="M006">Midpoint Rule</option>
                        <option value="M007">Simpson's 1/3 Rule</option>
                    </optgroup>
                    <optgroup label="Numerical Differentiation">
                        <option value="M012">First Derivative Approximation</option>
                    </optgroup>
                    <optgroup label="Ordinary Differential Equations">
                        <option value="M008">Euler's Method</option>
                    </optgroup>
                </select>

                <div id="inputs-M001" class="input-group hidden">
                    <div class="input-row"><label>Function f(x):</label><input type="text" id="eq-M001" value="x^2 - 4"></div>
                    <div class="input-row"><label>Lower Guess (a):</label><input type="number" id="a-M001" value="0" step="any"></div>
                    <div class="input-row"><label>Upper Guess (b):</label><input type="number" id="b-M001" value="3" step="any"></div>
                    <div class="input-row"><label>Tolerance:</label><input type="number" id="tol-M001" value="0.001" step="any"></div>
                </div>

                <div id="inputs-M010" class="input-group hidden">
                    <div class="input-row"><label>Function f(x):</label><input type="text" id="eq-M010" value="x^3 - x - 2"></div>
                    <div class="input-row"><label>Lower Guess (a):</label><input type="number" id="a-M010" value="1" step="any"></div>
                    <div class="input-row"><label>Upper Guess (b):</label><input type="number" id="b-M010" value="2" step="any"></div>
                    <div class="input-row"><label>Tolerance:</label><input type="number" id="tol-M010" value="0.0001" step="any"></div>
                </div>

                <div id="inputs-M002" class="input-group hidden">
                    <div class="input-row"><label>Function f(x):</label><input type="text" id="eq-M002" value="x^3 - 2*x - 5"></div>
                    <div class="input-row"><label>Initial Guess (x0):</label><input type="number" id="x0-M002" value="2" step="any"></div>
                    <div class="input-row"><label>Tolerance:</label><input type="number" id="tol-M002" value="0.001" step="any"></div>
                </div>

                <div id="inputs-M003" class="input-group hidden">
                    <div class="input-row"><label>Function f(x):</label><input type="text" id="eq-M003" value="cos(x) - x*exp(x)"></div>
                    <div class="input-row"><label>Guess 1 (x0):</label><input type="number" id="x0-M003" value="0" step="any"></div>
                    <div class="input-row"><label>Guess 2 (x1):</label><input type="number" id="x1-M003" value="1" step="any"></div>
                    <div class="input-row"><label>Tolerance:</label><input type="number" id="tol-M003" value="0.001" step="any"></div>
                </div>

                <div id="inputs-M004" class="input-group hidden">
                    <div class="input-row"><label>X Data (comma separated):</label><input type="text" id="x-M004" value="1, 2, 3, 4"></div>
                    <div class="input-row"><label>Y Data (comma separated):</label><input type="text" id="y-M004" value="1, 4, 9, 16"></div>
                    <div class="input-row"><label>Target X to Predict:</label><input type="number" id="target-M004" value="2.5" step="any"></div>
                </div>

                <div id="inputs-M011" class="input-group hidden">
                    <div class="input-row"><label>X Data (comma separated):</label><input type="text" id="x-M011" value="0, 1, 2"></div>
                    <div class="input-row"><label>Y Data (comma separated):</label><input type="text" id="y-M011" value="1, 3, 7"></div>
                    <div class="input-row"><label>Target X to Predict:</label><input type="number" id="target-M011" value="1.5" step="any"></div>
                </div>

                <div id="inputs-M005" class="input-group hidden">
                    <div class="input-row"><label>Function f(x):</label><input type="text" id="eq-M005" value="x^2"></div>
                    <div class="input-row"><label>Lower Limit (a):</label><input type="number" id="a-M005" value="0" step="any"></div>
                    <div class="input-row"><label>Upper Limit (b):</label><input type="number" id="b-M005" value="2" step="any"></div>
                    <div class="input-row"><label>Segments (n):</label><input type="number" id="n-M005" value="4"></div>
                </div>

                <div id="inputs-M006" class="input-group hidden">
                    <div class="input-row"><label>Function f(x):</label><input type="text" id="eq-M006" value="1/x"></div>
                    <div class="input-row"><label>Lower Limit (a):</label><input type="number" id="a-M006" value="1" step="any"></div>
                    <div class="input-row"><label>Upper Limit (b):</label><input type="number" id="b-M006" value="2" step="any"></div>
                    <div class="input-row"><label>Segments (n):</label><input type="number" id="n-M006" value="5"></div>
                </div>

                <div id="inputs-M007" class="input-group hidden">
                    <div class="input-row"><label>Function f(x):</label><input type="text" id="eq-M007" value="exp(x)"></div>
                    <div class="input-row"><label>Lower Limit (a):</label><input type="number" id="a-M007" value="0" step="any"></div>
                    <div class="input-row"><label>Upper Limit (b):</label><input type="number" id="b-M007" value="2" step="any"></div>
                    <div class="input-row"><label>Segments (n) [Must be EVEN]:</label><input type="number" id="n-M007" value="4"></div>
                </div>

                <div id="inputs-M012" class="input-group hidden">
                    <div class="input-row"><label for="diffXPoints">X Values (comma-separated):</label><input type="text" id="diffXPoints" value="1, 2, 3, 4"></div>
                    <div class="input-row"><label for="diffYPoints">Y Values (comma-separated):</label><input type="text" id="diffYPoints" value="2, 4, 8, 16"></div>
                    <div class="input-row"><label for="diffTargetX">Target X (Evaluation Point):</label><input type="number" step="any" id="diffTargetX" value="2"></div>
                    <div class="input-row">
                        <label for="diffMethod">Difference Formula Scheme:</label>
                        <select id="diffMethod">
                            <option value="forward">Forward Difference</option>
                            <option value="backward">Backward Difference</option>
                            <option value="central">Central Difference</option>
                        </select>
                    </div>
                </div>

                <div id="inputs-M008" class="input-group hidden">
                    <div class="input-row"><label>dy/dx = f(x,y):</label><input type="text" id="eq-M008" value="x + y"></div>
                    <div class="input-row"><label>Initial x (x0):</label><input type="number" id="x0-M008" value="0" step="any"></div>
                    <div class="input-row"><label>Initial y (y0):</label><input type="number" id="y0-M008" value="1" step="any"></div>
                    <div class="input-row"><label>Step Size (h):</label><input type="number" id="h-M008" value="0.1" step="any"></div>
                    <div class="input-row"><label>Target x:</label><input type="number" id="target-M008" value="0.2" step="any"></div>
                </div>
                
                <div id="inputs-M009" class="input-group hidden">
                    <div class="input-row"><label>True Value:</label><input type="number" id="true-M009" value="3.141592" step="any"></div>
                    <div class="input-row"><label>Approximate Value:</label><input type="number" id="approx-M009" value="3.14" step="any"></div>
                </div>

                <div class="sidebar-actions">
                    <button class="btn btn-primary" onclick="computeMath()">
                        Compute Result <i class='bx bx-right-arrow-alt'></i>
                    </button>
                    
                    <% if ("R003".equals(roleId) || "R002".equals(roleId)) { %>
                    <form id="saveForm" action="<%= request.getContextPath() %>/SaveComputationServlet" method="POST" style="margin: 0; width: 100%;">
                        <input type="hidden" name="computationId" id="saveComputationId" value="<%= loadedId != null ? loadedId : "" %>">
                        <input type="hidden" name="methodId" id="saveMethodId">
                        <input type="hidden" name="inputData" id="saveInputData">
                        <input type="hidden" name="result" id="saveResult">
                        <input type="hidden" name="iteration" id="saveIteration">
                        <input type="hidden" name="errorValue" id="saveErrorValue">
                        <input type="hidden" name="title" id="saveTitle">
                        <button type="submit" class="btn" style="background-color: #10b981; color: white;">
                            Save Result <i class='bx bx-save'></i>
                        </button>
                    </form>
                    <% } %>
                </div>
            </div>
        </div>

        <div class="main-panels" id="reportArea">
            
            <div id="actionToolbar" class="action-toolbar hidden animated-panel delay-1">
                <button class="action-btn" onclick="exportPDF()"><i class='bx bxs-file-pdf' style="color: #e3342f;"></i> Download PDF</button>
                <button class="action-btn" onclick="exportCSV()"><i class='bx bx-table' style="color: #10b981;"></i> Export CSV</button>
                <button class="action-btn" onclick="copySummary()"><i class='bx bx-copy' style="color: var(--primary);"></i> Copy</button>
                <button class="action-btn" onclick="clearWorkspace()"><i class='bx bx-trash' style="color: #64748b;"></i> Clear</button>
            </div>

            <div class="tab-container animated-panel delay-1">
                <button class="tab-btn active" onclick="switchOutputTab('graphTab', this)"><i class='bx bx-line-chart'></i> Graphical Plot</button>
                <button class="tab-btn" onclick="switchOutputTab('detailsTab', this)"><i class='bx bx-list-ol'></i> Calculation Details</button>
            </div>
            
            <div id="graphTab" class="tab-pane active-pane card animated-panel delay-2">
                <div class="card-title"><i class='bx bx-line-chart'></i> Visualization</div>
                <div id="graph">
                    <div style="text-align: center; padding: 120px 20px; color: #94a3b8;">
                        <i class='bx bx-line-chart' style="font-size: 3.5rem; opacity: 0.5;"></i>
                        <p style="margin-top: 10px;">Enter parameters and click Compute to generate graph.</p>
                    </div>
                </div>
            </div>

            <div id="detailsTab" class="tab-pane card animated-panel delay-2">
                <div class="card-title"><i class='bx bx-list-ol'></i> Calculation Details</div>
                
                <div id="resultArea" class="hidden" style="width: 100%;">
                    <div id="successBlock" style="width: 100%;">
                        <div id="standardSummary" class="summary-grid">
                            <div class="summary-card"><span>Final Answer</span><strong id="finalAnswer">-</strong></div>
                            <div class="summary-card"><span>Iterations / Steps</span><strong id="iterCount">-</strong></div>
                            <div class="summary-card"><span>Final Error / Diff</span><strong id="errValue">-</strong></div>
                        </div>
                        <div id="eulerSummary" class="summary-grid hidden">
                            <div class="summary-card"><span>Initial Point</span><strong id="eulerInitialPoint">-</strong></div>
                            <div class="summary-card"><span>Target X</span><strong id="eulerTargetX">-</strong></div>
                            <div class="summary-card"><span>Final Prediction (y)</span><strong id="eulerFinalPrediction">-</strong></div>
                        </div>
                    </div>
                    <div id="calculationDetails" class="details-box"></div>
                </div>

                <div id="emptyDetailsState" style="text-align: center; padding: 80px 20px; color: #94a3b8;">
                    <i class='bx bx-math' style="font-size: 3.5rem; opacity: 0.5;"></i>
                    <p style="margin-top: 10px;">Calculation details will appear here after computing.</p>
                </div>
            </div>

        </div>
    </div>

    <script>
        function switchOutputTab(tabId, btnElement) {
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.tab-pane').forEach(pane => pane.classList.remove('active-pane'));
            
            btnElement.classList.add('active');
            document.getElementById(tabId).classList.add('active-pane');

            // Force resize event so Plotly redraws flawlessly when tab opens
            if (tabId === 'graphTab') window.dispatchEvent(new Event('resize'));
        }
    </script>

    <script>
        const injectedId = "${loadedId}";
        const injectedMethod = "${loadedMethod}";
        const injectedInputs = "${loadedInputs}";

        function initPage() {
            if (injectedId && injectedId !== "null" && injectedId !== "") {
                const compIdField = document.querySelector('input[name="computationId"]') || document.getElementById("computationId");
                if (compIdField) compIdField.value = injectedId;
            }

            if (injectedMethod && injectedMethod !== "null" && injectedMethod !== "") {
                document.getElementById("methodSelect").value = injectedMethod;
                changeMethod();
                
                let parts = injectedInputs.split(';');
                parts.forEach(part => {
                    let eqIndex = part.indexOf('=');
                    if (eqIndex === -1) return;
                    
                    let key = part.substring(0, eqIndex).trim();
                    let val = part.substring(eqIndex + 1).trim();
                    
                    let el = null;
                    if (key === 'f(x)' || key === 'dy/dx') el = document.getElementById('eq-' + injectedMethod);
                    else if (key === 'a') el = document.getElementById('a-' + injectedMethod);
                    else if (key === 'b') el = document.getElementById('b-' + injectedMethod);
                    else if (key === 'tol') el = document.getElementById('tol-' + injectedMethod);
                    else if (key === 'x0') el = document.getElementById('x0-' + injectedMethod);
                    else if (key === 'x1') el = document.getElementById('x1-' + injectedMethod);
                    else if (key === 'h') el = document.getElementById('h-' + injectedMethod);
                    else if (key === 'target' || key === 'Target') el = document.getElementById('target-' + injectedMethod);
                    else if (key === 'n') el = document.getElementById('n-' + injectedMethod);
                    else if (key === 'scheme' || key === 'Scheme') el = document.getElementById('scheme-' + injectedMethod);
                    else if (key === 'x') el = document.getElementById('x-' + injectedMethod);
                    else if (key === 'X') { el = document.getElementById('x-' + injectedMethod); val = val.replace(/[\[\]]/g, ''); }
                    else if (key === 'Y') { el = document.getElementById('y-' + injectedMethod); val = val.replace(/[\[\]]/g, ''); }
                    
                    if (el) el.value = val;
                });
                
                setTimeout(() => computeMath(), 300);
            } else {
                changeMethod();
            }
        }

        window.latestCSVData = [];
        window.latestSummary = "";

        function changeMethod() {
            document.querySelectorAll('.input-group').forEach(el => el.classList.add('hidden'));
            const method = document.getElementById("methodSelect").value;
            const targetInput = document.getElementById("inputs-" + method);
            if(targetInput) targetInput.classList.remove('hidden');
        }

        function generateCurve(eqStr, minX, maxX, step = 0.1) {
            let xVals = [], yVals = [];
            let f = (x) => math.evaluate(eqStr, { x: x });
            
            if (maxX <= minX) { maxX = minX + 10; minX = minX - 10; } 
            if (step <= 0 || (maxX - minX) / step > 5000) step = Math.max((maxX - minX) / 1000, 0.01);

            for (let x = minX; x <= maxX; x += step) {
                xVals.push(x); yVals.push(f(x));
            }
            return { x: xVals, y: yVals };
        }

        function renderOutput(formula, sample, headers, rows) {
            let html = '<div class="math-box">' + formula + '<br><br><b>Step-by-Step Breakdown:</b><br>' + sample + '</div>';
            
            if (headers && headers.length > 0) {
                // FIXED: Wrapped the injected table in a .table-responsive div to prevent mobile overflow!
                html += '<div class="table-responsive"><table class="data-table"><thead><tr>';
                headers.forEach(function(h) { 
                    html += '<th>' + h + '</th>'; 
                });
                html += '</tr></thead><tbody>';
                
                rows.forEach(function(row) {
                    html += '<tr>';
                    row.forEach(function(cell) { 
                        html += '<td>' + cell + '</td>'; 
                    });
                    html += '</tr>';
                });
                html += '</tbody></table></div>';
            }
            document.getElementById("calculationDetails").innerHTML = html;
        }

        function computeMath() {
            Plotly.purge('graph');
            document.getElementById("graph").innerHTML = "";
            document.getElementById("calculationDetails").innerHTML = "";
            document.getElementById("resultArea").classList.add("hidden");
            document.getElementById("actionToolbar").classList.add("hidden");
            
            const successBlock = document.getElementById("successBlock");
            if(successBlock) successBlock.style.display = "block";

            try {
                const methodSelect = document.getElementById("methodSelect");
                const method = methodSelect.value;
                const methodName = methodSelect.selectedOptions[0].text;
                let result = 0, error = 0, iter = 0, inputs = "";
                let traces = []; let tableData = []; let tableHeaders = []; 
                let formula = "", sampleCalc = "";

                if (method === "M001" || method === "M010") { 
                    let eqStr = document.getElementById("eq-" + method).value;
                    let f = (x) => math.evaluate(eqStr, { x: x });
                    let a_init = parseFloat(document.getElementById("a-" + method).value);
                    let b_init = parseFloat(document.getElementById("b-" + method).value);
                    let a = a_init, b = b_init;
                    let tol = parseFloat(document.getElementById("tol-" + method).value);
                    
                    inputs = "f(x)=" + eqStr + "; a=" + a + "; b=" + b + "; tol=" + tol;
                    if (f(a) * f(b) >= 0) throw new Error("f(a) and f(b) must have opposite signs.");
                    
                    formula = method === "M001" ? "<b>Formula:</b> c = (a + b) / 2" : "<b>Formula:</b> c = a - [ f(a) * (b - a) ] / [ f(b) - f(a) ]";
                    
                    sampleCalc = method === "M001" ? 
                        "c = (" + a + " + " + b + ") / 2 = <b>" + ((a+b)/2).toFixed(5) + "</b>" : 
                        "c = " + a + " - [ " + f(a).toFixed(4) + " * (" + b + " - " + a + ") ] / [ " + f(b).toFixed(4) + " - " + f(a).toFixed(4) + " ]";
                    
                    tableHeaders = ['Iter', 'a', 'b', 'c', 'f(c)', 'Error'];

                    let c = a, c_old = a; error = 100;
                    while (error > tol && iter < 100) {
                        iter++;
                        c = (method === "M001") ? (a + b) / 2 : a - (f(a) * (b - a)) / (f(b) - f(a));
                        error = Math.abs(c - c_old);
                        tableData.push([iter, a.toFixed(5), b.toFixed(5), c.toFixed(5), f(c).toFixed(5), iter===1?"-":error.toFixed(5)]);
                        if (f(c) === 0) break;
                        if (f(c) * f(a) < 0) b = c; else a = c;
                        c_old = c;
                    }
                    result = c;

                    let curve = generateCurve(eqStr, Math.min(a_init, b_init) - 1, Math.max(a_init, b_init) + 1);
                    traces.push({ x: curve.x, y: curve.y, mode: 'lines', name: 'f(x)', line: {color: '#6366f1', width: 3} });
                    
                    [a_init, b_init].forEach((val, i) => {
                        traces.push({ x: [val, val], y: [0, f(val)], mode: 'lines', line: {color: '#94a3b8', dash: 'dash'}, name: i === 0 ? 'Start a' : 'Start b', showlegend: false });
                    });

                    traces.push({ x: [a_init, b_init], y: [f(a_init), f(b_init)], mode: 'markers', name: 'Interval Points', marker: {size: 10, color: '#1e293b'} });
                    traces.push({ x: [result], y: [0], mode: 'markers', name: 'Root', marker: {size: 15, color: '#ec4899', symbol: 'star'} });
                    renderOutput(formula, sampleCalc, tableHeaders, tableData);

                } else if (method === "M002") { // Newton-Raphson
                    let eqStr = document.getElementById("eq-M002").value;
                    let f = (x) => math.evaluate(eqStr, { x: x });
                    let x0_init = parseFloat(document.getElementById("x0-M002").value);
                    let x0 = x0_init;
                    let tol = parseFloat(document.getElementById("tol-M002").value);
                    
                    inputs = "f(x)=" + eqStr + "; x0=" + x0 + "; tol=" + tol;
                    formula = "<b>Formula:</b> x_{i+1} = x_i - [ f(x_i) / f'(x_i) ]";
                    const df = (x) => math.evaluate(math.derivative(eqStr, 'x').toString(), { x: x });
                    
                    sampleCalc = "x_1 = " + x0 + " - [ " + f(x0).toFixed(5) + " / " + df(x0).toFixed(5) + " ] = <b>" + (x0 - (f(x0)/df(x0))).toFixed(5) + "</b>";
                    
                    tableHeaders = ['Iter', 'x_i', 'f(x_i)', "f'(x_i)", 'x_{i+1}', 'Error'];
                    
                    error = 100; let x_hist = [x0];
                    while (error > tol && iter < 100) {
                        iter++; let d = df(x0);
                        if(d === 0) throw new Error("Derivative became zero. Method fails.");
                        let x1 = x0 - (f(x0) / d);
                        error = Math.abs(x1 - x0);
                        if (Math.abs(x1) > 1e10) throw new Error("Method diverging. Try a different initial guess.");
                        tableData.push([iter, x0.toFixed(5), f(x0).toFixed(5), d.toFixed(5), x1.toFixed(5), error.toFixed(5)]);
                        x0 = x1; x_hist.push(x0);
                    }
                    result = x0;

                    let curve = generateCurve(eqStr, Math.min(x0_init, result) - 1, Math.max(x0_init, result) + 1);
                    traces.push({ x: curve.x, y: curve.y, mode: 'lines', name: 'f(x)', line: {color: '#6366f1', width: 3} });
                    
                    traces.push({ x: [x0_init, result], y: [f(x0_init), 0], mode: 'lines', name: 'Tangent', line: {color: '#ef4444', dash: 'dash'} });
                    traces.push({ x: [x0_init, x0_init], y: [0, f(x0_init)], mode: 'lines', line: {color: '#94a3b8', dash: 'dot'}, showlegend: false });
                    traces.push({ x: [x0_init], y: [f(x0_init)], mode: 'markers', name: 'Initial Guess', marker: {size: 12, color: '#f59e0b'} });
                    traces.push({ x: [result], y: [0], mode: 'markers', name: 'Root', marker: {size: 15, color: '#ec4899', symbol: 'star'} });
                    renderOutput(formula, sampleCalc, tableHeaders, tableData);

                } else if (method === "M003") { // Secant Method
                    let eqStr = document.getElementById("eq-M003").value;
                    let f = (x) => math.evaluate(eqStr, { x: x });
                    let x0_init = parseFloat(document.getElementById("x0-M003").value);
                    let x1_init = parseFloat(document.getElementById("x1-M003").value);
                    let x0 = x0_init, x1 = x1_init;
                    let tol = parseFloat(document.getElementById("tol-M003").value);
                    
                    inputs = "f(x)=" + eqStr + "; x0=" + x0 + "; x1=" + x1 + "; tol=" + tol;
                    formula = "<b>Formula:</b> x_{i+1} = x_i - [ f(x_i) * (x_i - x_{i-1}) ] / [ f(x_i) - f(x_{i-1}) ]";
                    
                    sampleCalc = "x_2 = " + x1 + " - [ " + f(x1).toFixed(5) + " * (" + x1 + " - " + x0 + ") ] / [ " + f(x1).toFixed(5) + " - (" + f(x0).toFixed(5) + ") ]";
                    
                    tableHeaders = ['Iter', 'x_{i-1}', 'x_i', 'x_{i+1}', 'Error'];
                    
                    error = 100;
                    while (error > tol && iter < 100) {
                        iter++; 
                        if (f(x1) - f(x0) === 0) throw new Error("Division by zero in Secant formula.");
                        let x2 = x1 - (f(x1) * (x1 - x0)) / (f(x1) - f(x0));
                        error = Math.abs(x2 - x1);
                        tableData.push([iter, x0.toFixed(5), x1.toFixed(5), x2.toFixed(5), error.toFixed(5)]);
                        x0 = x1; x1 = x2;
                    }
                    result = x1;

                    let curve = generateCurve(eqStr, Math.min(x0_init, x1_init, result) - 1, Math.max(x0_init, x1_init, result) + 1);
                    traces.push({ x: curve.x, y: curve.y, mode: 'lines', name: 'f(x)', line: {color: '#6366f1', width: 3} });
                    traces.push({ x: [x0_init, x1_init, result], y: [f(x0_init), f(x1_init), 0], mode: 'lines', name: 'Secant Line', line: {color: '#ef4444', dash: 'dash'} });
                    [x0_init, x1_init].forEach(val => {
                        traces.push({ x: [val, val], y: [0, f(val)], mode: 'lines', line: {color: '#94a3b8', dash: 'dot'}, showlegend: false });
                    });
                    traces.push({ x: [x0_init, x1_init], y: [f(x0_init), f(x1_init)], mode: 'markers', name: 'Initial Guesses', marker: {size: 12, color: '#f59e0b'} });
                    traces.push({ x: [result], y: [0], mode: 'markers', name: 'Root', marker: {size: 15, color: '#ec4899', symbol: 'star'} });
                    renderOutput(formula, sampleCalc, tableHeaders, tableData);

                } else if (method === "M011" || method === "M004") { // Interpolation Upgrades
                    let xs = document.getElementById("x-" + method).value.split(',').map(Number);
                    let ys = document.getElementById("y-" + method).value.split(',').map(Number);
                    let targetX = parseFloat(document.getElementById("target-" + method).value);
                    
                    inputs = "X=[" + xs + "]; Y=[" + ys + "]; Target=" + targetX;
                    let curveX = [], curveY = [];
                    result = 0; 
                    
                    if(method === "M011") { // Lagrange Equation Mode
                        formula = "<b>Formula:</b> f(x) = &Sigma; [ y_i * &Pi; (x - x_j) / (x_i - x_j) ]";
                        
                        let polyTerms = [];
                        for (let i = 0; i < xs.length; i++) {
                            let numStr = "";
                            let denVal = 1;
                            for (let j = 0; j < xs.length; j++) {
                                if (i !== j) {
                                    numStr += "(x - " + xs[j] + ")";
                                    denVal *= (xs[i] - xs[j]);
                                }
                            }
                            polyTerms.push("[" + ys[i] + " * " + (numStr || "1") + " / " + denVal.toFixed(2) + "]");
                        }
                        let fullEquation = polyTerms.join(" + ");
                        sampleCalc = "<b>1. Full Polynomial Model f(x):</b><br><div style='background:#f1f5f9; padding:8px; border-radius:4px; font-family:monospace; word-break:break-all;'>f(x) = " + fullEquation + "</div><br><b>2. Evaluation at target x = " + targetX + ":</b>";

                        for (let i = 0; i < xs.length; i++) {
                            let term = ys[i];
                            for (let j = 0; j < xs.length; j++) { if (i !== j) term *= (targetX - xs[j]) / (xs[i] - xs[j]); }
                            result += term;
                        }
                        for(let x = Math.min(...xs)-1; x <= Math.max(...xs)+1; x += 0.1) {
                            curveX.push(x); let cy = 0;
                            for (let i = 0; i < xs.length; i++) {
                                let term = ys[i];
                                for (let j = 0; j < xs.length; j++) { if (i !== j) term *= (x - xs[j]) / (xs[i] - xs[j]); }
                                cy += term;
                            }
                            curveY.push(cy);
                        }
                        traces.push({ x: curveX, y: curveY, mode: 'lines', name: 'Lagrange Curve', line: {color: '#8b5cf6', shape: 'spline'} });
                    } else { // Linear Spline Segment Mode
                        formula = "<b>Formula:</b> S(x) = y_i + [ (y_{i+1} - y_i) / (x_{i+1} - x_i) ] * (x - x_i)";
                        
                        let segIdx = -1;
                        for (let i = 0; i < xs.length - 1; i++) {
                            if (targetX >= xs[i] && targetX <= xs[i+1]) { 
                                segIdx = i;
                                result = ys[i] + ((ys[i+1] - ys[i]) / (xs[i+1] - xs[i])) * (targetX - xs[i]); 
                                break; 
                            }
                        }
                        if (segIdx === -1) throw new Error("Target X falls outside the boundary of given points.");
                        
                        let x0 = xs[segIdx], x1 = xs[segIdx+1];
                        let y0 = ys[segIdx], y1 = ys[segIdx+1];
                        let slope = (y1 - y0) / (x1 - x0);
                        
                        sampleCalc = "<b>1. Located Target Interval Segment:</b> [" + x0 + ", " + x1 + "]<br>" +
                                     "<b>Active Linear Equation S(x):</b><br><div style='background:#f1f5f9; padding:8px; border-radius:4px; font-family:monospace;'>" +
                                     "S(x) = " + y0 + " + [(" + y1 + " - " + y0 + ") / (" + x1 + " - " + x0 + ")] * (x - " + x0 + ")<br>" +
                                     "S(x) = " + y0 + " + " + slope.toFixed(4) + " * (x - " + x0 + ")</div><br>" +
                                     "<b>2. Substitute target x = " + targetX + " into specific segment.</b>";

                        traces.push({ x: xs, y: ys, mode: 'lines', name: 'Spline Lines', line: {color: '#8b5cf6'} });
                    }
                    traces.push({ x: xs, y: ys, mode: 'markers', name: 'Data Points', marker: {size: 12, color: '#10b981'} });
                    traces.push({ x: [targetX], y: [result], mode: 'markers', name: 'Target Output', marker: {size: 18, color: '#f43f5e', symbol: 'diamond'} });
                    tableHeaders = ['Parameter', 'Value'];
                    tableData = [['Points Count', xs.length], ['Target X', targetX], ['Calculated Value Y', result.toFixed(6)]];
                    renderOutput(formula, sampleCalc, tableHeaders, tableData);

                } else if (method === "M012") { // First Derivative Approximation
                    let xs = document.getElementById("diffXPoints").value.split(',').map(Number);
                    let ys = document.getElementById("diffYPoints").value.split(',').map(Number);
                    let targetX = parseFloat(document.getElementById("diffTargetX").value);
                    let schemeEl = document.getElementById("diffMethod");
                    let scheme = schemeEl ? schemeEl.value : "central";

                    inputs = "X=[" + xs + "]; Y=[" + ys + "]; Target=" + targetX + "; Scheme=" + scheme;

                    let idx = xs.indexOf(targetX);
                    if (idx === -1) throw new Error("Target evaluation point must match an existing point in your X coordinate list.");

                    result = 0;
                    if (scheme === "forward") {
                        if (idx >= xs.length - 1) throw new Error("Forward scheme requires an extra data point ahead of target index.");
                        let h = xs[idx+1] - xs[idx];
                        result = (ys[idx+1] - ys[idx]) / h;
                        formula = "<b>Formula:</b> Forward Difference Scheme: f'(x) ≈ [ f(x_{i+1}) - f(x_i) ] / h";
                        sampleCalc = "f'(" + targetX + ") ≈ [" + ys[idx+1] + " - " + ys[idx] + "] / " + h.toFixed(4) + " = <b>" + result.toFixed(6) + "</b>";
                    } else if (scheme === "backward") {
                        if (idx <= 0) throw new Error("Backward scheme requires a preceding data point behind target index.");
                        let h = xs[idx] - xs[idx-1];
                        result = (ys[idx] - ys[idx-1]) / h;
                        formula = "<b>Formula:</b> Backward Difference Scheme: f'(x) ≈ [ f(x_i) - f(x_{i-1}) ] / h";
                        sampleCalc = "f'(" + targetX + ") ≈ [" + ys[idx] + " - " + ys[idx-1] + "] / " + h.toFixed(4) + " = <b>" + result.toFixed(6) + "</b>";
                    } else { // central
                        if (idx <= 0 || idx >= xs.length - 1) throw new Error("Central scheme requires data points immediately before and after the target index.");
                        let h1 = xs[idx+1] - xs[idx];
                        let h2 = xs[idx] - xs[idx-1];
                        result = (ys[idx+1] - ys[idx-1]) / (h1 + h2);
                        formula = "<b>Formula:</b> Central Difference Scheme: f'(x) ≈ [ f(x_{i+1}) - f(x_{i-1}) ] / (x_{i+1} - x_{i-1})";
                        sampleCalc = "f'(" + targetX + ") ≈ [" + ys[idx+1] + " - " + ys[idx-1] + "] / " + (h1 + h2).toFixed(4) + " = <b>" + result.toFixed(6) + "</b>";
                    }

                    traces.push({ x: xs, y: ys, mode: 'lines+markers', name: 'Data Trajectory', line: {color: '#6366f1'} });
                    traces.push({ x: [targetX], y: [ys[idx]], mode: 'markers', name: 'Evaluated Node', marker: {size: 14, color: '#f59e0b'} });

                    tableHeaders = ['Parameter', 'Value'];
                    tableData = [['Scheme Selected', scheme.toUpperCase()], ['Evaluation Target Node', targetX], ['Approx Slope Derivative', result.toFixed(6)]];
                    renderOutput(formula, sampleCalc, tableHeaders, tableData);
                
                } else if (method === "M005" || method === "M006" || method === "M007") { // Numerical Integration
                    let eqStr = document.getElementById("eq-" + method).value;
                    let f = (x) => math.evaluate(eqStr, { x: x });
                    let a = parseFloat(document.getElementById("a-" + method).value);
                    let b = parseFloat(document.getElementById("b-" + method).value);
                    let n = parseInt(document.getElementById("n-" + method).value);
                    inputs = "f(x)=" + eqStr + "; a=" + a + "; b=" + b + "; n=" + n;
                    let h = (b - a) / n; let sum = 0;
                    
                    let curve = generateCurve(eqStr, a - 0.5, b + 0.5, (b-a)/100);
                    traces.push({ x: curve.x, y: curve.y, mode: 'lines', name: 'f(x)', line: {color: '#6366f1', width: 3} });

                    if (method === "M005") { // Trapezoidal rule
                        let integrationLabel = (n === 1) ? "Basic Trapezoidal Rule" : "Composite Trapezoidal Rule";
                        formula = "<b>Classification:</b> " + integrationLabel + "<br><b>Formula:</b> I = (h/2) * [ f(x0) + 2*f(x1) + ... + f(xn) ]";
                        sampleCalc = "I ≈ (" + h.toFixed(4) + " / 2) * [ f(" + a + ") + 2*f(" + (a+h) + ") + ... ]";
                        
                        sum = f(a) + f(b); 
                        for (let i = 1; i < n; i++) sum += 2 * f(a + i * h);
                        result = (h / 2) * sum;

                        let trapX = [a], trapY = [0];
                        for(let i=0; i<=n; i++){ 
                            let xi = a + i*h; 
                            trapX.push(xi); trapY.push(f(xi)); 
                            traces.push({ x: [xi, xi], y: [0, f(xi)], mode: 'lines', line: {color: 'rgba(0,0,0,0.2)', width: 1}, showlegend: false });
                        }
                        trapX.push(b); trapY.push(0);
                        traces.push({ x: trapX, y: trapY, fill: 'toself', name: 'Trapezoids', fillcolor: 'rgba(236, 72, 153, 0.3)', line: {color: '#ec4899'} });

                    } else if (method === "M006") { // Midpoint
                        formula = "<b>Formula:</b> I = h * sum( f(x_mid) )";
                        sampleCalc = "I ≈ " + h.toFixed(4) + " * [ f(" + (a + 0.5*h) + ") + ... ]";
                        
                        let rectX = [], rectY = [];
                        for (let i = 0; i < n; i++) { 
                            let x_start = a + i * h;
                            let x_end = a + (i + 1) * h;
                            let xmid = a + (i + 0.5) * h; 
                            let ymid = f(xmid); 
                            sum += ymid; 

                            rectX.push(x_start, x_start, x_end, x_end, null); 
                            rectY.push(0, ymid, ymid, 0, null);
                            traces.push({ x: [xmid], y: [ymid], mode: 'markers', marker: {color: '#10b981', size: 8}, showlegend: false });
                        }
                        result = h * sum;
                        traces.push({ x: rectX, y: rectY, fill: 'toself', name: 'Midpoint Rects', fillcolor: 'rgba(16, 185, 129, 0.3)', line: {color: '#10b981'} });

                    } else if (method === "M007") { // Simpson's 1/3 Rule
                        if (n % 2 !== 0) throw new Error("Simpson's 1/3 Rule strictly requires an EVEN number of segments (n). Please adjust parameter configuration.");
                        formula = "<b>Formula:</b> I = (h/3) * [ f(x0) + 4*f(x1) + 2*f(x2) + ... + f(xn) ]";
                        sampleCalc = "I ≈ (" + h.toFixed(4) + " / 3) * [ f(" + a + ") + 4*f(" + (a+h) + ") + 2*f(" + (a+2*h) + ") ... ]";
                        
                        sum = f(a) + f(b); 
                        for (let i = 1; i < n; i++) {
                            sum += (i % 2 === 0 ? 2 : 4) * f(a + i * h);
                        }
                        result = (h / 3) * sum;
                        
                        let areaCurve = generateCurve(eqStr, a, b, (b-a)/100); 
                        traces.push({ x: areaCurve.x, y: areaCurve.y, fill: 'tozeroy', name: 'Simpson Area', fillcolor: 'rgba(139, 92, 246, 0.3)', line: {color: 'transparent'} });
                    }
                    tableHeaders = ['Parameter', 'Value'];
                    tableData = [['Integration Bounds', "[ " + a + ", " + b + " ]"], ['Segment Count (n)', n], ['Interval Delta (h)', h.toFixed(5)], ['Computed Definite Integral', result.toFixed(6)]];
                    renderOutput(formula, sampleCalc, tableHeaders, tableData);

                } else if (method === "M008") { // Euler's Method
                    const odeEqStr = document.getElementById("eq-M008").value;
                    const f_xy = (x, y) => math.evaluate(odeEqStr, { x: x, y: y });
                    let x0 = parseFloat(document.getElementById("x0-M008").value);
                    let y0 = parseFloat(document.getElementById("y0-M008").value);
                    let h = parseFloat(document.getElementById("h-M008").value);
                    let target = parseFloat(document.getElementById("target-M008").value);

                    if (target <= x0) {
                        throw new Error("Mathematical boundary error: Target X (end point) must be strictly greater than Initial X (x0).");
                    }
                    if (h <= 0) {
                        throw new Error("Step size (h) must be a positive number.");
                    }

                    inputs = "dy/dx=" + odeEqStr + "; x0=" + x0 + "; y0=" + y0 + "; h=" + h + "; target=" + target;

                    formula = "<div style='border: 1px solid #3b82f6; border-radius: 8px; padding: 16px; background: #eff6ff; margin-bottom: 12px;'>" +
                              "<h4 style='color:#1e40af; margin-top:0; margin-bottom:10px;'>Euler Parameter Highlights</h4>" +
                              "<b>Initial Condition Node Point:</b> (x₀: " + x0 + ", y₀: " + y0 + ")<br>" +
                              "<b>Target Evaluation Bound X:</b> " + target + "<br>" +
                              "<b>Fixed Step Configuration h:</b> " + h + "</div>";

                    let steps = Math.round((target - x0) / h);
                    let x = x0, y = y0;

                    for (let i = 1; i <= steps; i++) {
                        let slope = f_xy(x, y);
                        let nextY = y + h * slope;
                        tableData.push([i-1, x.toFixed(4), y.toFixed(4), slope.toFixed(4), nextY.toFixed(4)]);
                        x = x + h; y = nextY;
                    }
                    result = y; iter = steps;

                    sampleCalc = "<div style='font-size: 1.1em; color: #15803d; font-weight: bold; background: #f0fdf4; padding: 10px; border-radius: 6px; border: 1px solid #bbf7d0;'>" +
                                 "Final Estimated Prediction Target: y(" + target + ") ≈ " + result.toFixed(6) + "</div>";

                    traces = []; 
                    tableHeaders = ['Step (i)', 'x_i', 'y_i', 'f(x_i, y_i)', 'y_{i+1}'];
                    renderOutput(formula, sampleCalc, tableHeaders, tableData);
                }

                document.getElementById("resultArea").classList.remove("hidden");
                document.getElementById("actionToolbar").classList.remove("hidden");
                
                document.getElementById("finalAnswer").innerText = result.toFixed(6);
                document.getElementById("iterCount").innerText = iter || "-";
                document.getElementById("errValue").innerText = error === 0 ? "N/A" : error.toFixed(6);

                if(document.getElementById("saveMethodId")) {
                    document.getElementById("saveMethodId").value = method;
                    document.getElementById("saveInputData").value = inputs;
                    document.getElementById("saveErrorValue").value = error.toFixed(6);
                    document.getElementById("saveTitle").value = methodName;
                    
                    if(document.getElementById("saveStatus")) document.getElementById("saveStatus").value = "Completed";
                    document.getElementById("saveResult").value = result.toFixed(6);
                    document.getElementById("saveIteration").value = iter;
                }

                if (tableHeaders.length > 0) {
                    window.latestCSVData = [tableHeaders, ...tableData];
                }
                
                window.latestSummary = "NumSolve Computation Summary:\n" +
                                       "Method: " + methodName + "\n" +
                                       "Inputs: " + inputs + "\n" +
                                       "Final Result: " + result.toFixed(6) + "\n" +
                                       "Iterations: " + (iter || "-") + "\n" +
                                       "Error: " + (error === 0 ? "N/A" : error.toFixed(6));
                
                if (method === "M008") {
                    document.getElementById("graph").innerHTML = '<div style="text-align: center; padding: 80px 20px; color: #3b82f6;"><i class="bx bx-badge-check" style="font-size: 3.5rem; opacity: 0.6;"></i><p style="margin-top:8px;">Euler scorecard data processed. Graph hidden to optimize presentation.</p></div>';
                } else {
                    Plotly.newPlot('graph', traces, { 
                        title: { text: methodName, font: { size: 18, color: '#1e293b' } },
                        hovermode: 'closest', plot_bgcolor: '#f8fafc', paper_bgcolor: '#ffffff',
                        xaxis: { gridcolor: '#e2e8f0', zerolinecolor: '#cbd5e1' }, yaxis: { gridcolor: '#e2e8f0', zerolinecolor: '#cbd5e1' },
                        margin: { t: 40, b: 40, l: 40, r: 40 }
                    });
                }

            } catch (err) { 
                document.getElementById("resultArea").classList.remove("hidden");
                const successBlock = document.getElementById("successBlock");
                if(successBlock) successBlock.style.display = "none";
                document.getElementById("actionToolbar").classList.add("hidden");
                
                document.getElementById("calculationDetails").innerHTML = 
                    '<div style="background-color: #fee2e2; border: 1px solid #f87171; border-radius: 8px; padding: 20px; color: #b91c1c;">' +
                        '<h4 style="margin-top: 0;"><i class=\'bx bx-error-circle\'></i> Calculation Failed</h4>' +
                        '<p><b>Error Details:</b> ' + err.message + '</p>' +
                        '<p style="font-size: 0.9em; margin-bottom: 0;"><i>Hint: Verify that all parameter dimensions are properly aligned, intervals match method standards, and commas delimit arrays.</i></p>' +
                    '</div>';
                
                document.getElementById("graph").innerHTML = '<div style="text-align: center; padding: 100px 20px; color: #94a3b8;"><i class="bx bx-line-chart" style="font-size: 3rem; opacity: 0.5;"></i><p>Graph drawing suspended because of errors.</p></div>';
            }
        }

        function exportPDF() {
            window.scrollTo(0, 0); 
            
            const element = document.getElementById('reportArea');
            const toolbar = document.getElementById('actionToolbar');
            
            if(toolbar) toolbar.classList.add('hidden');
            
            const opt = {
                margin:       0.3,
                filename:     'NumSolve_Report.pdf',
                image:        { type: 'jpeg', quality: 0.98 },
                html2canvas:  { 
                    scale: 2, 
                    useCORS: true, 
                    scrollY: 0,    
                    windowWidth: document.documentElement.offsetWidth
                },
                jsPDF:        { unit: 'in', format: 'letter', orientation: 'portrait' }
            };
            
            html2pdf().set(opt).from(element).save().then(() => {
                if(toolbar) toolbar.classList.remove('hidden');
            }).catch(err => {
                alert("Error generating PDF: " + err);
                if(toolbar) toolbar.classList.remove('hidden');
            });
        }

        function exportCSV() {
            if (!window.latestCSVData || window.latestCSVData.length === 0) {
                alert("No table data available to export.");
                return;
            }
            
            let csvContent = window.latestCSVData.map(e => e.join(",")).join("\n");
            let blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            let url = URL.createObjectURL(blob);
            
            var link = document.createElement("a");
            link.setAttribute("href", url);
            link.setAttribute("download", "NumSolve_Data.csv");
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        function copySummary() {
            if(window.latestSummary) {
                navigator.clipboard.writeText(window.latestSummary).then(() => {
                    alert("Summary copied to clipboard!");
                }).catch(err => {
                    alert("Failed to copy text: ", err);
                });
            }
        }

        function clearWorkspace() {
            Plotly.purge('graph'); 
            document.getElementById("graph").innerHTML = '<div style="text-align: center; padding: 100px 20px; color: #94a3b8;"><i class="bx bx-line-chart" style="font-size: 3rem; opacity: 0.5;"></i><p>Enter parameters and click Compute to generate graph.</p></div>';
            document.getElementById("calculationDetails").innerHTML = "";
            document.getElementById("resultArea").classList.add("hidden");
            document.getElementById("actionToolbar").classList.add("hidden");
        }

        document.addEventListener("DOMContentLoaded", function() {
            initPage();
        });
    </script>
</body>
</html>