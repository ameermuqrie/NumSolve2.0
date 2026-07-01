<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.*,dao.*" %>
<%
    User u = (User) session.getAttribute("user");
    if (u == null || !"R002".equals(u.getRoleId())) { response.sendRedirect("../login.jsp"); return; }
    
    int id = Integer.parseInt(request.getParameter("id"));
    LearningMaterial m = new LearningMaterialDAO().getById(id);
    if(m.getUserId() != u.getUserId()) { response.sendRedirect("my_materials.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Material – NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES (Educator Theme - Purple) --- */
        :root {
            --educator: #8b5cf6;         
            --educator-hover: #7c3aed;   
            --sidebar-bg: #1e1e2d;
            --sidebar-hover: #2b2b40;
            --dark: #2c3e50;
            --light: #f4f6f9;
            --white: #ffffff;
            --gray: #858796;
            --border: #e2e8f0;
            --shadow: 0 4px 6px rgba(0,0,0,0.05);
            --shadow-hover: 0 10px 20px rgba(0,0,0,0.1);
            --transition: all 0.3s ease;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background-color: var(--light); 
            color: var(--dark); 
            height: 100vh; 
            display: flex; 
            overflow: hidden;
        }

        /* --- PAGE LOAD ANIMATION --- */
        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .animated-panel { animation: fadeInUp 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }

        /* --- SIDEBAR NAVIGATION --- */
        .sidebar {
            width: 260px;
            background-color: var(--sidebar-bg);
            color: var(--white);
            display: flex;
            flex-direction: column;
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
            z-index: 10;
        }

        .brand { 
            font-size: 1.5rem; font-weight: 700; padding: 25px 20px; 
            display: flex; align-items: center; gap: 10px; 
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }
        .brand i { color: var(--educator); font-size: 1.8rem; }
        
        .nav-menu { 
            list-style: none; padding: 20px 15px; flex: 1; overflow-y: auto; 
        }
        .nav-menu::-webkit-scrollbar { display: none; }

        .nav-link {
            display: flex; align-items: center; gap: 12px; padding: 12px 15px; 
            border-radius: 8px; color: #a1a5b7; 
            font-weight: 500; text-decoration: none; 
            transition: var(--transition); margin-bottom: 5px;
        }

        .nav-link i { font-size: 1.3rem; }
        .nav-link:hover { background: var(--sidebar-hover); color: var(--white); }
        .nav-link.active { background: var(--educator); color: var(--white); }

        .bottom-nav {
            padding: 15px;
            border-top: 1px solid rgba(255,255,255,0.05);
        }

        /* --- MAIN WRAPPER & TOP HEADER --- */
        .main-wrapper { 
            flex: 1; display: flex; flex-direction: column; overflow: hidden; 
        }

        .top-header {
            height: 70px; background: var(--white); padding: 0 30px;
            display: flex; align-items: center; justify-content: space-between;
            box-shadow: var(--shadow); z-index: 5;
        }

        .header-breadcrumb { font-size: 1.1rem; font-weight: 600; color: var(--dark); }

        .user-action { display: flex; align-items: center; gap: 20px; }
        
        .user-profile {
            display: flex; align-items: center; gap: 12px; background: var(--light);
            padding: 6px 12px 6px 15px; border-radius: 30px; 
            border: 1px solid var(--border); transition: var(--transition);
            text-decoration: none; cursor: pointer;
        }
        .user-profile:hover { border-color: var(--educator); }
        .user-profile span { font-weight: 500; color: var(--dark); font-size: 0.95rem; }
        .avatar {
            width: 32px; height: 32px; border-radius: 50%; background: var(--educator);
            color: var(--white); display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 1rem;
        }

        /* --- CONTENT AREA & HEADER --- */
        .content-area { 
            flex: 1; padding: 40px; overflow-y: auto; background-color: var(--light);
            display: flex; flex-direction: column; align-items: center;
        }
        
        .header-area {
            width: 100%; max-width: 700px; margin-bottom: 25px;
        }
        .header-area h2 { font-size: 1.8rem; color: var(--dark); font-weight: 600; display: flex; align-items: center; gap: 10px; }
        .header-area p { color: var(--gray); font-size: 1rem; margin-top: 5px; }

        /* --- FORM STYLING --- */
        .form-card {
            background: var(--white); padding: 40px; border-radius: 12px;
            box-shadow: var(--shadow); border-top: 4px solid var(--educator);
            width: 100%; max-width: 700px; margin-bottom: 40px;
        }

        .form-group { margin-bottom: 25px; }
        .form-label { display: block; font-weight: 600; margin-bottom: 8px; color: var(--dark); font-size: 0.95rem; }
        
        .form-control { 
            width: 100%; padding: 12px 15px; border: 1px solid var(--border); 
            border-radius: 8px; font-size: 0.95rem; font-family: 'Poppins', sans-serif;
            transition: var(--transition); background: #f8fafc; color: var(--dark);
        }
        .form-control:focus { 
            outline: none; border-color: var(--educator); background: var(--white); 
            box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.15); 
        }
        textarea.form-control { resize: vertical; min-height: 100px; }
        
        input[type="file"] { 
            background: var(--white); padding: 10px; cursor: pointer;
            border: 1px dashed var(--gray);
        }
        input[type="file"]::file-selector-button {
            background: #f1f5f9; border: 1px solid var(--border);
            padding: 8px 15px; border-radius: 6px; color: var(--dark);
            font-weight: 500; cursor: pointer; transition: var(--transition);
            margin-right: 15px; font-family: 'Poppins', sans-serif;
        }
        input[type="file"]::file-selector-button:hover { background: #e2e8f0; }

        .form-help { display: block; margin-top: 6px; font-size: 0.85rem; color: var(--gray); }
        .divider { margin: 30px 0; border: 0; border-top: 2px dashed var(--border); }

        /* --- CURRENT FILE & PHOTO STYLES --- */
        .current-attachment {
            display: flex; align-items: center; gap: 10px; background: #f8fafc;
            padding: 10px 15px; border-radius: 8px; border: 1px solid var(--border);
            margin-bottom: 10px; font-size: 0.9rem; color: var(--gray);
        }
        .current-attachment a { color: var(--educator); font-weight: 500; text-decoration: none; }
        .current-attachment a:hover { text-decoration: underline; }
        .current-attachment img { height: 40px; width: 40px; object-fit: cover; border-radius: 4px; }
        .current-attachment i { font-size: 1.5rem; color: var(--dark); }

        /* --- BUTTONS --- */
        .btn-group { display: flex; gap: 15px; margin-top: 35px; }
        .btn {
            padding: 12px 25px; border-radius: 8px; font-weight: 500; font-size: 1rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; flex: 1;
        }
        .btn-primary { background: var(--educator); color: var(--white); }
        .btn-primary:hover { background: var(--educator-hover); transform: translateY(-2px); box-shadow: 0 4px 10px rgba(139, 92, 246, 0.3); }
        
        .btn-secondary { background: #f1f5f9; color: var(--dark); border: 1px solid var(--border); }
        .btn-secondary:hover { background: #e2e8f0; transform: translateY(-2px); }

        @media (max-width: 900px) {
            .sidebar { width: 80px; }
            .sidebar .brand { justify-content: center; padding: 25px 0; }
            .sidebar .brand span, .nav-link span { display: none; }
            .nav-link { justify-content: center; padding: 12px 0; }
            .content-area { padding: 20px; }
            .form-card { padding: 25px; }
        }
    </style>
</head>
<body>

    <aside class="sidebar">
        <div class="brand">
            <i class='bx bxs-cube-alt'></i> <span>NumSolve</span>
        </div>
        <ul class="nav-menu">
            <li><a href="<%=request.getContextPath()%>/dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="#" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
            <li><a href="#" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
            <li><a href="#" class="nav-link"><i class='bx bxs-folder-open'></i> <span>Records</span></a></li>
            <li><a href="#" class="nav-link"><i class='bx bxs-report'></i> <span>Reports</span></a></li>
            <li><a href="<%=request.getContextPath()%>/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="<%=request.getContextPath()%>/educator/my_materials.jsp" class="nav-link active"><i class='bx bxs-cloud-upload'></i> <span>My Materials</span></a></li>
        </ul>
        <div class="bottom-nav">
            <a href="../logout" class="nav-link"><i class='bx bx-log-out-circle'></i> <span>Logout</span></a>
        </div>
    </aside>

    <div class="main-wrapper">
        
        <header class="top-header">
            <div class="header-breadcrumb">Materials Management</div>
            <div class="user-action">
                <a href="../profile.jsp" style="text-decoration: none;">
                    <div class="user-profile">
                        <span><%= u.getFullName() %></span>
                        <div class="avatar"><%= u.getFullName().charAt(0) %></div>
                    </div>
                </a>
            </div>
        </header>

        <main class="content-area">
            
            <div class="header-area animated-panel delay-1">
                <h2><i class='bx bx-edit' style="color: var(--educator);"></i> Edit Material</h2>
                <p>Update resource details or replace files</p>
            </div>

            <div class="form-card animated-panel delay-2">
                <form method="post" action="../editMaterial" enctype="multipart/form-data">
                    <input type="hidden" name="id" value="<%= m.getMaterialId() %>">

                    <div class="form-group">
                        <label class="form-label">Topic Title</label>
                        <input type="text" name="topic" value="<%= m.getTopic() %>" class="form-control" required>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Material Type</label>
                        <select name="materialType" id="typeSelect" class="form-control" onchange="updateFileAccept()">
                            <option <%= "PDF".equals(m.getMaterialType()) ? "selected" : "" %>>PDF</option>
                            <option <%= "Video".equals(m.getMaterialType()) ? "selected" : "" %>>Video</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Description</label>
                        <textarea name="description" class="form-control"><%= m.getDescription() %></textarea>
                    </div>

                    <hr class="divider">

                    <div class="form-group">
                        <label class="form-label">Update File (Optional)</label>
                        <div class="current-attachment">
                            <i class='bx bx-file'></i>
                            <span>Current File: <a href="../<%= m.getFilePath() %>" target="_blank"><%= m.getFileName() %></a></span>
                        </div>
                        <input type="file" name="file" id="fileInput" class="form-control">
                        <small id="fileHelp" class="form-help">Leave empty to keep the existing file.</small>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Update Cover Photo (Optional)</label>
                        <% if(m.getPhotoPath() != null && !m.getPhotoPath().isEmpty()) { %>
                            <div class="current-attachment">
                                <img src="../<%= m.getPhotoPath() %>" alt="Cover Thumbnail">
                                <span>Current Cover Image</span>
                            </div>
                        <% } %>
                        <input type="file" name="photo" accept="image/*" class="form-control">
                        <small class="form-help">Leave empty to keep the existing cover photo.</small>
                    </div>

                    <div class="btn-group">
                        <a href="my_materials.jsp" class="btn btn-secondary"><i class='bx bx-arrow-back'></i> Cancel</a>
                        <button type="submit" class="btn btn-primary"><i class='bx bx-save'></i> Save Changes</button>
                    </div>
                </form>
            </div>
        </main>
    </div>

<script>
    // Set initial accept attributes based on currently selected type
    window.onload = function() { updateFileAccept(); };

    function updateFileAccept() {
        var type = document.getElementById("typeSelect").value;
        var input = document.getElementById("fileInput");
        
        if (type === "PDF") {
            input.setAttribute("accept", ".pdf");
        } else if (type === "Video") {
            input.setAttribute("accept", ".mp4,.mov,.avi,.mkv");
        } else {
            input.removeAttribute("accept");
        }
    }
</script>
</body>
</html>