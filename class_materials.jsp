<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*,model.*,dao.*" %>
<%
    // 1. SECURITY & CACHE CONTROL
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    if (u == null) { response.sendRedirect("login.jsp"); return; }
    
    // 2. GET CLASS ID & FETCH PRIVATE CLASS MATERIALS
    String classIdStr = request.getParameter("classId");
    if (classIdStr == null || classIdStr.isEmpty()) {
        response.sendRedirect("dashboard/student.jsp"); // Fallback if no ID is passed
        return;
    }
    int classId = Integer.parseInt(classIdStr);
    
    // FIX: Using the upgraded secure method from your DAO!
    List<LearningMaterial> list = new LearningMaterialDAO().getClassMaterialsSecure(classId, u.getUserId(), u.getRoleId());
    
    // 3. SET ROLE CLASS (Used for dynamic CSS styling)
    String roleClass = "role-" + u.getRoleId();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Class Materials | NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES & DYNAMIC ROLE THEMING --- */
        :root {
            --dark: #2c3e50;
            --light: #f4f6f9;
            --white: #ffffff;
            --gray: #858796;
            --border: #e2e8f0;
            --shadow: 0 4px 6px rgba(0,0,0,0.1);
            --shadow-hover: 0 10px 20px rgba(0,0,0,0.15);
            --transition: all 0.3s ease;
            --danger: #ef4444;
            --warning: #ca8a04;
            --warning-light: #fef08a;
        }

        body.role-R002 { --primary: #8b5cf6; --primary-hover: #7c3aed; } /* Educator */
        body.role-R003 { --primary: #3b82f6; --primary-hover: #2563eb; } /* Student */

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        body { background-color: var(--light); color: var(--dark); min-height: 100vh; display: flex; flex-direction: column; }

        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .animated-panel { animation: fadeInUp 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }

        /* --- COLORED TOP NAVIGATION --- */
        .top-nav {
            width: 100%; background: linear-gradient(135deg, var(--primary) 0%, var(--primary-hover) 100%); 
            padding: 10px 30px; display: flex; align-items: center; justify-content: space-between;
            box-shadow: 0 4px 15px rgba(0,0,0,0.15); z-index: 20; color: var(--white);
        }
        .brand { font-size: 1.4rem; font-weight: 700; display: flex; align-items: center; gap: 10px; }
        
        .nav-menu { list-style: none; display: flex; align-items: center; gap: 5px; }
        .nav-link { display: flex; align-items: center; gap: 10px; padding: 10px; border-radius: 30px; color: rgba(255, 255, 255, 0.8); font-weight: 500; text-decoration: none; max-width: 44px; white-space: nowrap; overflow: hidden; transition: all 0.4s ease; }
        .nav-link i { font-size: 1.4rem; min-width: 24px; text-align: center; }
        .nav-link span { opacity: 0; transform: translateX(-10px); transition: all 0.3s ease; }
        .nav-link:hover, .nav-link.active { background: rgba(255, 255, 255, 0.2); color: var(--white); max-width: 180px; padding: 10px 20px; }
        .nav-link:hover span, .nav-link.active span { opacity: 1; transform: translateX(0); }

        /* --- MAIN CONTENT & HEADER --- */
        .main-content { padding: 40px; flex: 1; max-width: 1400px; margin: 0 auto; width: 100%; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; 
            margin-bottom: 30px; background: var(--white); padding: 25px; 
            border-radius: 12px; box-shadow: var(--shadow); border-left: 5px solid var(--primary);
        }
        .header-left { display: flex; flex-direction: column; gap: 5px; }
        .header-area h2 { font-size: 1.8rem; color: var(--dark); font-weight: 600; display: flex; align-items: center; gap: 10px; }
        
        .btn {
            padding: 10px 20px; border-radius: 8px; font-weight: 500; font-size: 0.95rem;
            text-decoration: none; transition: var(--transition); cursor: pointer; border: none;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px;
        }
        .btn-primary { background: var(--primary); color: var(--white); }
        .btn-primary:hover { background: var(--primary-hover); transform: translateY(-2px); box-shadow: 0 4px 10px rgba(0,0,0,0.15); }
        .btn-outline { background: transparent; border: 1px solid var(--border); color: var(--dark); }
        .btn-outline:hover { background: var(--light); border-color: var(--gray); }
        .btn-danger { background: #fee2e2; color: var(--danger); }
        .btn-danger:hover { background: var(--danger); color: var(--white); }
        .btn-warning { background: var(--warning-light); color: var(--warning); }
        .btn-warning:hover { background: var(--warning); color: var(--white); }

        /* --- MATERIAL GRID --- */
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 25px; margin-top: 30px; }
        .material-card { background: var(--white); border-radius: 12px; overflow: hidden; box-shadow: var(--shadow); transition: var(--transition); display: flex; flex-direction: column; }
        .material-card:hover { transform: translateY(-5px); box-shadow: var(--shadow-hover); }

        .thumbnail { height: 160px; background: #f1f5f9; display: flex; align-items: center; justify-content: center; position: relative; border-bottom: 1px solid var(--border); }
        .thumbnail img { width: 100%; height: 100%; object-fit: cover; }
        .thumbnail-icon { font-size: 4.5rem; color: var(--primary); opacity: 0.3; }
        .tag { position: absolute; top: 12px; right: 12px; background: rgba(255,255,255,0.9); color: var(--dark); padding: 4px 10px; border-radius: 20px; font-size: 0.8rem; font-weight: 600; box-shadow: 0 2px 4px rgba(0,0,0,0.1); display: flex; align-items: center; gap: 5px; }

        .card-body { padding: 20px; display: flex; flex-direction: column; flex: 1; }
        .uploader-name { font-size: 0.85rem; color: var(--primary); font-weight: 500; margin-bottom: 5px; display: flex; align-items: center; gap: 5px; }
        .card-title { font-size: 1.15rem; font-weight: 600; color: var(--dark); margin-bottom: 8px; }
        .card-desc { font-size: 0.9rem; color: var(--gray); margin-bottom: 20px; height: 40px; overflow: hidden; }
        .card-actions { display: flex; gap: 10px; margin-top: auto; }
        .btn-full { flex: 1; }
        .btn-icon { padding: 10px; width: 42px; display: flex; align-items: center; justify-content: center; }

        /* --- MODAL --- */
        .modal-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); display: none; align-items: center; justify-content: center; z-index: 100; backdrop-filter: blur(3px); }
        .modal-content { background: var(--white); padding: 30px; border-radius: 12px; width: 100%; max-width: 500px; box-shadow: 0 10px 25px rgba(0,0,0,0.2); transform: translateY(-20px); animation: fadeInUp 0.3s forwards; }
        .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
        .close-btn { background: none; border: none; font-size: 1.5rem; cursor: pointer; color: var(--gray); }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: 500; font-size: 0.9rem; }
        .form-group input[type="text"], .form-group textarea, .form-group select, .form-group input[type="file"] { width: 100%; padding: 10px; border: 1px solid var(--border); border-radius: 8px; }
    </style>
</head>
<body class="<%= roleClass %>">

    <nav class="top-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            <li><a href="dashboard/<%= "R002".equals(u.getRoleId()) ? "educator" : "student" %>.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Public Library</span></a></li>
            <li><a href="profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="logout" class="nav-link"><i class='bx bxs-log-out-circle'></i> <span>Logout</span></a></li>
        </ul>
    </nav>

    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <div class="header-left">
                <h2><i class='bx bxs-folder-open' style="color: var(--primary);"></i> Class Materials</h2>
                <p style="color: var(--gray); font-size: 0.95rem;">Private resources exclusively for this class.</p>
            </div>
            
            <div style="display: flex; gap: 10px;">
                <%-- Back button to go back to the specific class dashboard --%>
                <button onclick="history.back()" class="btn btn-outline"><i class='bx bx-arrow-back'></i> Back</button>
                
                <%-- EDUCATOR ONLY: Upload button --%>
                <% if ("R002".equals(u.getRoleId())) { %>
                    <button class="btn btn-primary" onclick="document.getElementById('uploadModal').style.display='flex'">
                        <i class='bx bx-plus-circle'></i> Add Material
                    </button>
                <% } %>
            </div>
        </div>

        <div class="grid animated-panel delay-2">
            <% for (LearningMaterial m : list) { %>
                <div class="material-card">
                    
                    <div class="thumbnail">
                        <% if(m.getPhotoPath() != null && !m.getPhotoPath().isEmpty()) { %>
                            <img src="<%= request.getContextPath() %>/<%= m.getPhotoPath() %>" onerror="this.style.display='none'; this.nextElementSibling.style.display='block';"> 
                        <% } %>
                        <i class='bx <%= "Video".equals(m.getMaterialType()) ? "bxs-video" : "bxs-file-pdf" %> thumbnail-icon' style="display:<%= (m.getPhotoPath() != null && !m.getPhotoPath().isEmpty()) ? "none" : "block" %>;"></i>
                        <span class="tag"><i class='bx <%= "Video".equals(m.getMaterialType()) ? "bx-video" : "bx-file" %>'></i> <%= m.getMaterialType() %></span>
                    </div>

                    <div class="card-body">
                        <div class="uploader-name"><i class='bx bxs-user-circle'></i> <%= m.getUploaderName() != null ? m.getUploaderName() : "Educator" %></div>
                        <h3 class="card-title"><%= m.getTopic() %></h3>
                        <p class="card-desc"><%= (m.getDescription() != null && m.getDescription().length() > 50) ? m.getDescription().substring(0, 50) + "..." : m.getDescription() %></p>
                        
                        <div class="card-actions">
                            <a href="<%= request.getContextPath() %>/<%= m.getFilePath() %>" target="_blank" class="btn btn-primary btn-full"><i class='bx bx-show'></i> Open</a>

                            <%-- EDUCATOR ONLY: Edit/Delete their own class material --%>
                            <% if ("R002".equals(u.getRoleId()) && m.getUserId() == u.getUserId()) { 
                                // FIX: Protect JavaScript execution from newlines/enters in the description string!
                                String safeTopic = m.getTopic() != null ? m.getTopic().replace("'", "\\'") : "";
                                String safeDesc = m.getDescription() != null ? m.getDescription().replace("'", "\\'").replace("\n", "\\n").replace("\r", "") : "";
                            %>
                                <button type="button" class="btn btn-warning btn-icon" title="Edit Material" 
                                        onclick="openEditModal('<%= m.getMaterialId() %>', '<%= safeTopic %>', '<%= safeDesc %>')">
                                    <i class='bx bx-edit-alt'></i>
                                </button>
                                
                                <a href="deleteMaterial?id=<%= m.getMaterialId() %>&classId=<%= classIdStr %>" class="btn btn-danger btn-icon" title="Delete" onclick="return confirm('Are you sure you want to delete this from the class?')">
                                    <i class='bx bx-trash'></i>
                                </a>
                            <% } %>
                        </div>
                    </div>

                </div>
            <% } %>
            
            <% if(list.isEmpty()){ %>
                <div style="grid-column: 1 / -1; text-align: center; padding: 40px; border: 2px dashed var(--border); border-radius: 12px; background: transparent;">
                    <i class='bx bx-folder-minus' style="font-size: 3.5rem; color: var(--gray); margin-bottom: 10px;"></i>
                    <h3 style="color: var(--dark);">No materials added yet.</h3>
                    <% if ("R002".equals(u.getRoleId())) { %>
                        <p style="color: var(--gray); margin-bottom: 15px;">Upload notes or videos to share with your students.</p>
                        <button class="btn btn-primary" onclick="document.getElementById('uploadModal').style.display='flex'">Upload Now</button>
                    <% } else { %>
                        <p style="color: var(--gray);">Your educator hasn't uploaded any resources for this class yet.</p>
                    <% } %>
                </div>
            <% } %>
        </div>
        
    </main>

    <%-- MODALS FOR EDUCATORS ONLY --%>
    <% if ("R002".equals(u.getRoleId())) { %>
    
    <div class="modal-overlay" id="uploadModal">
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class='bx bxs-lock-alt' style="color: var(--primary);"></i> Add Class Material</h3>
                <button type="button" class="close-btn" onclick="document.getElementById('uploadModal').style.display='none'"><i class='bx bx-x'></i></button>
            </div>
            
            <form action="uploadMaterial" method="post" enctype="multipart/form-data">
                <input type="hidden" name="classId" value="<%= classId %>">
                <div class="form-group"><label>Topic / Title</label><input type="text" name="topic" required placeholder="e.g. Chapter 1 Notes"></div>
                <div class="form-group">
                    <label>Material Type</label>
                    <select name="materialType" required>
                        <option value="PDF">PDF Document</option>
                        <option value="Video">Video Tutorial</option>
                    </select>
                </div>
                <div class="form-group"><label>Description (Optional)</label><textarea name="description" rows="2" placeholder="Brief instructions..."></textarea></div>
                <div class="form-group"><label>Main File (PDF/MP4)</label><input type="file" name="file" required accept=".pdf,video/mp4,video/mkv"></div>
                <div class="form-group"><label>Cover Image (Optional)</label><input type="file" name="photo" accept="image/png,image/jpeg,image/jpg"></div>
                <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 10px;"><i class='bx bx-upload'></i> Share with Class</button>
            </form>
        </div>
    </div>

    <div class="modal-overlay" id="editModal">
        <div class="modal-content">
            <div class="modal-header">
                <h3><i class='bx bx-edit-alt' style="color: var(--warning);"></i> Edit Material</h3>
                <button type="button" class="close-btn" onclick="closeEditModal()"><i class='bx bx-x'></i></button>
            </div>
            
            <form action="editMaterial" method="post">
                <input type="hidden" name="classId" value="<%= classId %>">
                <input type="hidden" name="materialId" id="edit_materialId" value="">
                
                <div class="form-group">
                    <label>Topic / Title</label>
                    <input type="text" name="topic" id="edit_topic" required>
                </div>
                
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" id="edit_description" rows="3"></textarea>
                </div>
                
                <button type="submit" class="btn btn-warning" style="width: 100%; margin-top: 10px; background: var(--warning); color: var(--white);">
                    <i class='bx bx-save'></i> Save Changes
                </button>
            </form>
        </div>
    </div>

    <script>
        function openEditModal(materialId, topic, description) {
            document.getElementById('edit_materialId').value = materialId;
            document.getElementById('edit_topic').value = topic;
            document.getElementById('edit_description').value = description;
            document.getElementById('editModal').style.display = 'flex';
        }

        function closeEditModal() {
            document.getElementById('editModal').style.display = 'none';
        }
    </script>
    
    <% } %>

</body>
</html>