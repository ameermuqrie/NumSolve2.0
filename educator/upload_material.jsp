<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.User" %>
<%@ page import="dao.ClassDAO" %>
<%@ page import="model.Classroom" %>
<%@ page import="java.util.List" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Verify session and role clearance
    User u = (User) session.getAttribute("user");
    if (u == null || !"R002".equals(u.getRoleId())) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // Set Role Class for Dynamic Theming
    String roleClass = "role-R002";
    
    // Fetch educator classes to handle the target dropdown assignment
    ClassDAO classDAO = new ClassDAO();
    List<Classroom> educatorClasses = classDAO.getClassesByEducator(u.getUserId());
    
    // Extract a class tracking query if they are accessing this from a dedicated workspace
    String urlClassId = request.getParameter("classId");
    boolean hasClassContext = (urlClassId != null && !urlClassId.trim().isEmpty() && !urlClassId.equals("0"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload Material – NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
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
            
            --glass-bg: rgba(255, 255, 255, 0.75);
            --glass-border: rgba(255, 255, 255, 0.6);
            --shadow-sm: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
            --radius-lg: 24px;
            --text-main: #334155;
            --text-muted: #64748b;
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

        /* --- MAIN WRAPPER & TOP HEADER --- */
        .main-wrapper { 
            flex: 1; display: flex; flex-direction: column; width: 100%; max-width: 1400px;
        }

        .top-header {
            padding: 10px 30px; margin-bottom: 20px;
            display: flex; align-items: center; justify-content: space-between;
            z-index: 5;
        }

        .header-breadcrumb { font-size: 1.1rem; font-weight: 600; color: var(--dark); }

        .user-action { display: flex; align-items: center; gap: 20px; }
        
        .user-profile {
            display: flex; align-items: center; gap: 12px; background: var(--glass-bg);
            backdrop-filter: blur(10px); padding: 6px 12px 6px 15px; border-radius: 30px; 
            border: 1px solid var(--glass-border); transition: var(--transition);
            text-decoration: none; cursor: pointer; box-shadow: var(--shadow-sm);
        }
        .user-profile:hover { border-color: var(--primary); box-shadow: 0 4px 15px var(--primary-glow); }
        .user-profile span { font-weight: 500; color: var(--dark); font-size: 0.95rem; }
        .avatar {
            width: 32px; height: 32px; border-radius: 50%; background: var(--primary);
            color: var(--white); display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 1rem;
        }

        /* --- CONTENT AREA & HEADER --- */
        .content-area { 
            flex: 1; padding: 10px 30px 40px 30px; 
            display: flex; flex-direction: column; align-items: center;
        }
        
        .header-area {
            width: 100%; max-width: 750px; margin-bottom: 25px; text-align: left;
        }
        .header-area h2 { font-size: 1.8rem; color: var(--dark); font-weight: 700; display: flex; align-items: center; gap: 10px; }
        .header-area p { color: var(--text-muted); font-size: 1rem; margin-top: 5px; }

        /* --- FORM PANEL (GLASSMORPHISM) --- */
        .form-card {
            background: var(--glass-bg); backdrop-filter: blur(25px); padding: 40px; border-radius: var(--radius-lg);
            box-shadow: var(--shadow-lg); border: 1px solid var(--glass-border); border-top: 5px solid var(--primary);
            width: 100%; max-width: 750px; margin-bottom: 40px;
        }

        .form-group { margin-bottom: 25px; }
        .form-label { display: block; font-weight: 600; margin-bottom: 8px; color: var(--dark); font-size: 0.95rem; }
        
        .form-control { 
            width: 100%; padding: 12px 15px; border: 1px solid var(--glass-border); 
            border-radius: 12px; font-size: 0.95rem; font-family: 'Poppins', sans-serif;
            transition: var(--transition); background: rgba(255, 255, 255, 0.6); color: var(--text-main); outline: none;
            box-shadow: inset 0 2px 4px rgba(0,0,0,0.02);
        }
        .form-control:focus { 
            border-color: var(--primary); background: var(--white); 
            box-shadow: 0 0 0 4px var(--primary-glow); 
        }
        textarea.form-control { resize: vertical; min-height: 100px; }
        
        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }

        input[type="file"] { 
            background: rgba(255, 255, 255, 0.5); padding: 10px; cursor: pointer;
            border: 1px dashed var(--gray);
        }
        input[type="file"]::file-selector-button {
            background: var(--white); border: 1px solid var(--glass-border);
            padding: 8px 15px; border-radius: 8px; color: var(--dark);
            font-weight: 600; cursor: pointer; transition: var(--transition);
            margin-right: 15px; font-family: 'Poppins', sans-serif;
            box-shadow: var(--shadow-sm);
        }
        input[type="file"]::file-selector-button:hover { background: #f8fafc; border-color: var(--primary); color: var(--primary); }

        .form-help { display: block; margin-top: 6px; font-size: 0.85rem; color: var(--text-muted); }

        /* --- ACTION CONTROL INTERFACES --- */
        .btn-group { display: flex; gap: 15px; margin-top: 35px; }
        .btn {
            padding: 12px 25px; border-radius: 30px; font-weight: 600; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; flex: 1;
        }
        .btn-primary { background: var(--primary); color: var(--white); box-shadow: var(--shadow-sm); }
        .btn-primary:hover { background: var(--primary-hover); transform: translateY(-3px); box-shadow: 0 8px 15px var(--primary-glow); }
        
        .btn-secondary { background: rgba(255, 255, 255, 0.5); color: var(--dark); border: 1px solid var(--glass-border); backdrop-filter: blur(10px); }
        .btn-secondary:hover { background: var(--white); transform: translateY(-3px); box-shadow: var(--shadow-sm); border-color: var(--gray); }

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
            
            .top-header { flex-direction: column; gap: 15px; align-items: flex-start; padding: 10px 20px; }
            .content-area { padding: 10px 20px 30px 20px; }
            .grid-2 { grid-template-columns: 1fr; gap: 0; }
            .form-card { padding: 25px; }
            .btn-group { flex-direction: column; }
        }
    </style>
</head>
<body class="<%= roleClass %>">

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            <% if (hasClassContext) { %>
                <li><a href="${pageContext.request.contextPath}/class_dashboard.jsp?classId=<%= urlClassId %>" class="nav-link"><i class='bx bx-left-arrow-alt'></i> <span>Workspace Hub</span></a></li>
            <% } else { %>
                <li><a href="${pageContext.request.contextPath}/dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-folder-open'></i> <span>Records</span></a></li>
                <li><a href="${pageContext.request.contextPath}/manage_classes.jsp" class="nav-link"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
                <li><a href="${pageContext.request.contextPath}/educatorQuizzes" class="nav-link"><i class='bx bx-task'></i><span>Quizzes</span></a></li>
                <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                <li><a href="${pageContext.request.contextPath}/educator/my_materials.jsp" class="nav-link active"><i class='bx bxs-cloud-upload'></i> <span>My Materials</span></a></li>
                <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <% } %>
            <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
        </ul>
    </nav>

    <div class="main-wrapper">
        
        <header class="top-header">
            <div class="header-breadcrumb">Materials Management</div>
            <div class="user-action">
                <a href="${pageContext.request.contextPath}/profile.jsp" style="text-decoration: none;">
                    <div class="user-profile">
                        <span><%= u.getFullName() %></span>
                        <div class="avatar"><%= u.getFullName().charAt(0) %></div>
                    </div>
                </a>
            </div>
        </header>

        <main class="content-area">
            
            <div class="header-area animated-panel delay-1">
                <h2>
                    <i class='bx bx-cloud-upload' style="color: var(--primary);"></i> 
                    Publish Learning Material
                </h2>
                <p>Upload files or video tutorials to share publicly or limit visibility to specific class hubs.</p>
            </div>

            <div class="form-card animated-panel delay-2">
                <form method="post" action="<%=request.getContextPath()%>/uploadMaterial" enctype="multipart/form-data">
                    
                    <div class="grid-2">
                        <div class="form-group">
                            <label class="form-label">Visibility Scope</label>
                            <select name="visibility" id="visibilityType" class="form-control" onchange="toggleTargetClassGroup()" required>
                                <option value="Private" <%= hasClassContext ? "selected" : "" %>>Private (Specific Classroom)</option>
                                <option value="Public" <%= !hasClassContext ? "selected" : "" %>>Public (Global Discovery Pool)</option>
                            </select>
                        </div>

                        <div class="form-group" id="classIdGroup" style="<%= !hasClassContext ? "display:none;" : "" %>">
                            <label class="form-label">Target Classroom Destination</label>
                            <select name="classId" id="classIdInput" class="form-control">
                                <option value="">-- Assign to Class Workspace --</option>
                                <% 
                                    if (educatorClasses != null && !educatorClasses.isEmpty()) {
                                        for (Classroom c : educatorClasses) { 
                                            String isSelected = (urlClassId != null && urlClassId.equals(String.valueOf(c.getClassId()))) ? "selected" : "";
                                %>
                                            <option value="<%= c.getClassId() %>" <%= isSelected %>>
                                                <%= c.getClassName() %> (Code: <%= c.getClassCode() %>)
                                            </option>
                                <% 
                                        } 
                                    } else { 
                                %>
                                        <option value="" disabled>No active classrooms detected.</option>
                                <%  } %>
                            </select>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Topic Title</label>
                        <input type="text" name="topic" class="form-control" placeholder="e.g., Introduction to Matrix Operations" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Material Format Classification</label>
                        <select name="materialType" id="typeSelect" class="form-control" required onchange="updateFileAccept()">
                            <option value="">Select Resource Type...</option>
                            <option value="PDF">PDF Document</option>
                            <option value="Video">Video Tutorial</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Description / Summary</label>
                        <textarea name="description" class="form-control" placeholder="Provide notes, focus points, or dynamic summaries regarding this resource item..." required></textarea>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Resource File Attachment</label>
                        <input type="file" name="file" id="fileInput" class="form-control" required>
                        <small id="fileHelp" class="form-help"><i class='bx bx-info-circle'></i> Please select a material type first</small>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Cover Card Thumbnail (Optional)</label>
                        <input type="file" name="photo" accept="image/*" class="form-control">
                        <small class="form-help">Upload a custom visualization thumbnail for the platform layout.</small>
                    </div>

                    <div class="btn-group">
                        <% if (hasClassContext) { %>
                            <a href="${pageContext.request.contextPath}/class_dashboard.jsp?classId=<%= urlClassId %>" class="btn btn-secondary"><i class='bx bx-arrow-back'></i> Cancel</a>
                        <% } else { %>
                            <a href="${pageContext.request.contextPath}/educator/my_materials.jsp" class="btn btn-secondary"><i class='bx bx-arrow-back'></i> Cancel</a>
                        <% } %>
                        <button type="submit" class="btn btn-primary"><i class='bx bx-cloud-upload'></i> Upload Material</button>
                    </div>
                    
                </form>
            </div>
        </main>
    </div>

<script>
    // Handles show/hide toggles for target class assignments
    function toggleTargetClassGroup() {
        const type = document.getElementById("visibilityType").value;
        const classGroup = document.getElementById("classIdGroup");
        const classInput = document.getElementById("classIdInput");

        if (type === "Private") {
            classGroup.style.display = "block";
            classInput.setAttribute("required", "true");
        } else {
            classGroup.style.display = "none";
            classInput.removeAttribute("required");
            classInput.value = ""; 
        }
    }

    // Handles dynamically formatting restriction hooks for file selector forms
    function updateFileAccept() {
        var type = document.getElementById("typeSelect").value;
        var input = document.getElementById("fileInput");
        var help = document.getElementById("fileHelp");
        
        input.value = ""; 
        
        if (type === "PDF") {
            input.setAttribute("accept", ".pdf");
            help.innerHTML = "<i class='bx bxs-file-pdf' style='color:#ef4444;'></i> Allowed format: .pdf only";
        } else if (type === "Video") {
            input.setAttribute("accept", ".mp4,.mov,.avi,.mkv");
            help.innerHTML = "<i class='bx bxs-video' style='color:#3b82f6;'></i> Allowed formats: .mp4, .mov, .avi, .mkv";
        } else {
            input.removeAttribute("accept");
            help.innerHTML = "<i class='bx bx-info-circle'></i> Please select a material type first";
        }
    }

    // Initialize checking constraints on page rendering loop
    window.onload = function() {
        toggleTargetClassGroup();
    };
</script>
</body>
</html>