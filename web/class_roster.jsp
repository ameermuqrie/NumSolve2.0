<%-- 
    Document   : class_roster
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="dao.ClassDAO, model.Classroom, model.User, java.util.*" %>
<%
    // 1. Security Check
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    if (u == null) { response.sendRedirect("login.jsp"); return; }

    boolean isEducator = "R002".equals(u.getRoleId());
    boolean isStudent = "R003".equals(u.getRoleId());
    if (!isEducator && !isStudent) { response.sendRedirect("login.jsp"); return; }

    // 2. Get Class Details
    ClassDAO classDao = new ClassDAO();
    String classIdStr = request.getParameter("classId");
    int classId = 0;
    Classroom currentClass = null;
    
    // Create a list to hold the real students from the database
    List<User> enrolledStudents = new ArrayList<>();

    try {
        if (classIdStr != null && !classIdStr.isEmpty()) {
            classId = Integer.parseInt(classIdStr);
            currentClass = classDao.getClassById(classId);
            
            // Calling actual DAO method
            enrolledStudents = classDao.getStudentsByClass(classId); 
        }
    } catch (Exception e) { 
        e.printStackTrace();
    }

    if (currentClass == null) {
        response.sendRedirect(isEducator ? "manage_classes.jsp" : "student_classes.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isEducator ? "Manage Roster" : "Classmates" %> | NumSolve</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    <style>
        /* --- GLOBAL VARIABLES (Premium UI Theme) --- */
        :root {
                  
            --primary: #6366f1;
            --primary-hover: #4f46e5;
            --primary-glow: rgba(99, 102, 241, 0.25);
            --dark: #1e293b;
            --text-main: #334155;
            --text-muted: #64748b;
            --white: #ffffff;
            
            /* Background Gradients */
            --bg-gradient-1: #e0e7ff;
            --bg-gradient-2: #c7d2fe;
            --bg-gradient-3: #ddd6fe;
            
            /* Glass Effects */
            --glass-bg: rgba(255, 255, 255, 0.75);
            --glass-border: rgba(255, 255, 255, 0.6);
            
            /* Shadows & Transitions */
            --shadow-sm: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
            --shadow-md: 0 10px 25px -5px rgba(0, 0, 0, 0.05);
            --shadow-lg: 0 20px 25px -5px rgba(0, 0, 0, 0.05);
            --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            --radius-lg: 24px;
            --radius-md: 16px;

            /* Elegant Card Accent Colors */
            --purple: #8b5cf6;   --purple-bg: #f5f3ff;
            --red: #ef4444;      --red-bg: #fee2e2;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(135deg, var(--bg-gradient-1) 0%, var(--bg-gradient-2) 50%, var(--bg-gradient-3) 100%);
            background-attachment: fixed;
            color: var(--text-main); 
            min-height: 100vh; 
            display: flex; 
            flex-direction: column; 
            align-items: center;
            overflow-x: hidden;
        }

        /* --- ENTRANCE ANIMATIONS --- */
        @keyframes slideDown { from { opacity: 0; transform: translateY(-20px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes fadeUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
        
        .animated-nav { animation: slideDown 0.6s ease-out forwards; }
        .animated-panel { animation: fadeUp 0.6s ease-out forwards; opacity: 0; }
        .delay-1 { animation-delay: 0.1s; }
        .delay-2 { animation-delay: 0.2s; }

        /* --- FLOATING GLASS NAV --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 24px auto;
            background: var(--glass-bg); 
            backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
            padding: 12px 24px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: var(--shadow-sm);
            border: 1px solid var(--glass-border); z-index: 100; position: sticky; top: 24px;
        }

        .brand { 
            font-size: 1.4rem; font-weight: 800; display: flex; align-items: center; gap: 8px; letter-spacing: -0.5px;
            color: var(--dark);
        }
        .brand i { color: var(--primary); font-size: 1.8rem; }

        .back-btn {
            display: flex; align-items: center; gap: 8px; padding: 10px 18px; 
            border-radius: 40px; color: var(--text-main); font-weight: 600; font-size: 0.95rem; 
            text-decoration: none; transition: var(--transition); background: rgba(255, 255, 255, 0.5);
            border: 1px solid var(--glass-border);
        }
        .back-btn:hover { background: var(--white); color: var(--primary); box-shadow: var(--shadow-sm); transform: translateX(-4px); }

        /* --- MAIN CONTENT & HEADER --- */
        .main-content { padding: 10px 24px 48px 24px; flex: 1; max-width: 1200px; width: 100%; }
        
        .section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 15px; }
        .title-area h2 { font-size: 1.8rem; font-weight: 700; color: var(--dark); letter-spacing: -0.3px; display: flex; align-items: center; gap: 10px; }
        .title-area p { color: var(--text-muted); font-size: 1.05rem; font-weight: 400; margin-top: 4px; }

        .action-btn { 
            background: var(--purple); color: var(--white); padding: 12px 24px; border-radius: var(--radius-md); 
            text-decoration: none; font-weight: 600; font-size: 0.95rem; display: inline-flex; align-items: center; 
            gap: 8px; border: none; cursor: pointer; transition: var(--transition); 
            box-shadow: 0 4px 10px rgba(139, 92, 246, 0.3);
        }
        .action-btn:hover { background: #7c3aed; transform: translateY(-3px); box-shadow: 0 8px 16px rgba(139, 92, 246, 0.4); }

        /* --- ROSTER GLASS CARD & TABLE --- */
        .roster-card { 
            background: var(--glass-bg); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
            border-radius: var(--radius-lg); box-shadow: var(--shadow-md); 
            border: 1px solid var(--glass-border); overflow: hidden; 
        }
        
        .search-bar-container { padding: 24px; border-bottom: 1px solid var(--glass-border); background-color: rgba(255, 255, 255, 0.3); display: flex; align-items: center; }
        .search-wrapper { position: relative; width: 100%; max-width: 400px; }
        .search-wrapper i { position: absolute; left: 16px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 1.2rem; }
        .search-input { 
            width: 100%; padding: 12px 16px 12px 48px; border-radius: var(--radius-md); 
            border: 1px solid var(--glass-border); background: rgba(255, 255, 255, 0.6);
            font-size: 0.95rem; outline: none; transition: var(--transition); color: var(--text-main);
        }
        .search-input:focus { border-color: var(--purple); background: var(--white); box-shadow: 0 0 0 3px var(--purple-bg); }

        .roster-table { width: 100%; border-collapse: collapse; text-align: left; }
        .roster-table th { background-color: rgba(255, 255, 255, 0.4); padding: 18px 24px; font-weight: 600; color: var(--dark); font-size: 0.95rem; border-bottom: 2px solid var(--glass-border); }
        .roster-table td { padding: 18px 24px; border-bottom: 1px solid var(--glass-border); font-size: 0.95rem; color: var(--text-main); vertical-align: middle; transition: background 0.2s; }
        .roster-table tr:last-child td { border-bottom: none; }
        .roster-table tr:hover td { background-color: rgba(255, 255, 255, 0.5); }

        .student-profile { display: flex; align-items: center; gap: 14px; font-weight: 500; color: var(--dark); }
        .avatar { width: 42px; height: 42px; background-color: var(--purple-bg); color: var(--purple); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 1rem; text-transform: uppercase; border: 1px solid rgba(139, 92, 246, 0.2);}
        
        .badge { padding: 6px 12px; border-radius: 20px; font-size: 0.85rem; font-weight: 600; display: inline-block; }
        .badge-student { background-color: rgba(99, 102, 241, 0.1); color: var(--primary); border: 1px solid rgba(99, 102, 241, 0.2); }

        .btn-delete { background: var(--red-bg); border: 1px solid transparent; color: var(--red); cursor: pointer; font-size: 1.2rem; padding: 8px; border-radius: 10px; transition: var(--transition); display: inline-flex; align-items: center; justify-content: center;}
        .btn-delete:hover { background-color: var(--red); color: var(--white); box-shadow: 0 4px 10px rgba(239, 68, 68, 0.3); }

        /* --- Custom Modal Styling (Glass Theme) --- */
        .modal-overlay {
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(30, 41, 59, 0.4);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 9999;
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
        }
        .modal-content {
            background: var(--glass-bg);
            border: 1px solid var(--glass-border);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            padding: 32px;
            border-radius: var(--radius-lg);
            width: 90%;
            max-width: 400px;
            box-shadow: var(--shadow-lg);
            animation: fadeUp 0.3s ease-out forwards;
        }
        .modal-content h3 {
            margin-top: 0;
            margin-bottom: 8px;
            color: var(--dark);
            font-size: 1.4rem;
            font-weight: 700;
        }
        .modal-content p {
            color: var(--text-muted);
            font-size: 0.95rem;
            margin-bottom: 24px;
            line-height: 1.5;
        }
        .modal-content input {
            width: 100%;
            padding: 14px 16px;
            margin-bottom: 24px;
            border: 1px solid var(--glass-border);
            background: rgba(255, 255, 255, 0.7);
            border-radius: var(--radius-md);
            box-sizing: border-box;
            font-size: 1rem;
            outline: none;
            transition: var(--transition);
        }
        .modal-content input:focus {
            border-color: var(--purple);
            background: var(--white);
            box-shadow: 0 0 0 3px var(--purple-bg);
        }
        .modal-actions {
            display: flex;
            justify-content: flex-end;
            gap: 12px;
        }
        .btn-cancel {
            background: rgba(255, 255, 255, 0.5);
            color: var(--text-main);
            border: 1px solid var(--glass-border);
            padding: 12px 20px;
            border-radius: var(--radius-md);
            cursor: pointer;
            font-weight: 600;
            transition: var(--transition);
        }
        .btn-cancel:hover { background: var(--white); box-shadow: var(--shadow-sm); }
        
        .btn-confirm-modal {
            background: var(--purple);
            color: var(--white);
            border: none;
            padding: 12px 20px;
            border-radius: var(--radius-md);
            cursor: pointer;
            font-weight: 600;
            transition: var(--transition);
            box-shadow: 0 4px 10px rgba(139, 92, 246, 0.3);
        }
        .btn-confirm-modal:hover { background: #7c3aed; box-shadow: 0 6px 14px rgba(139, 92, 246, 0.4); transform: translateY(-2px); }

        @media (max-width: 1024px) {
            .top-nav { width: 90%; border-radius: 20px; }
        }
        @media (max-width: 768px) {
            .section-header { flex-direction: column; align-items: flex-start; }
            .action-btn { width: 100%; justify-content: center; }
            .roster-table { display: block; overflow-x: auto; white-space: nowrap; }
        }
    </style>
</head>
<body>

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <a href="class_dashboard.jsp?classId=<%= classId %>" class="back-btn"><i class='bx bx-left-arrow-alt'></i> Workspace Hub</a>
    </nav>

    <main class="main-content">
        <div class="section-header animated-panel delay-1">
            <div class="title-area">
                <h2><i class='bx bx-group' style="color: var(--purple);"></i> <%= isEducator ? "Class Roster Management" : "Classmates Directory" %></h2>
                <p>Course: <strong><%= currentClass.getClassName() %></strong></p>
            </div>
            <% if (isEducator) { %>
                <form id="enrollForm" action="EnrollStudentServlet" method="GET" style="display: none;">
                    <input type="hidden" name="classId" value="<%= classId %>">
                    <input type="hidden" name="studentId" id="enrollStudentId">
                </form>

                <button class="action-btn" onclick="promptEnrollment(<%= classId %>)">
                    <i class='bx bx-user-plus'></i> Enroll Student
                </button>
            <% } %>
        </div>

        <div class="roster-card animated-panel delay-2">
            <div class="search-bar-container">
                <div class="search-wrapper">
                    <i class='bx bx-search'></i>
                    <input type="text" class="search-input" placeholder="Search by name or ID...">
                </div>
            </div>

            <table class="roster-table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th> <th>Enroll Date</th>
                        <th>Role</th>
                        <% if (isEducator) { %><th>Actions</th><% } %>
                    </tr>
                </thead>
                <tbody>
                    <% 
                        // DYNAMIC DATABASE LOOP
                        if (enrolledStudents != null && !enrolledStudents.isEmpty()) { 
                            for (User student : enrolledStudents) {
                                String name = student.getFullName() != null ? student.getFullName() : "Unknown";
                                String email = student.getEmail() != null ? student.getEmail() : "N/A";
                                String initials = name.length() >= 2 ? name.substring(0, 2) : "ST";
                    %>
                    <tr>
                        <td>
                            <div class="student-profile">
                                <div class="avatar"><%= initials %></div>
                                <span><%= name %></span>
                            </div>
                        </td>
                        <td><%= email %></td>
                        <td><%= student.getMemberSince() != null ? student.getMemberSince().toString() : "Unknown" %></td>
                        <td><span class="badge badge-student">Student</span></td>
                        <% if (isEducator) { %>
                        <td>
                            <form action="RemoveStudentServlet" method="GET" style="margin:0;">
                                <input type="hidden" name="classId" value="<%= classId %>">
                                <input type="hidden" name="studentId" value="<%= student.getUserId() %>">
                                <button type="submit" class="btn-delete" title="Remove Student From Class" onclick="return confirm('Are you sure you want to unenroll this student?')">
                                    <i class='bx bx-trash'></i>
                                </button>
                            </form>
                        </td>
                        <% } %>
                    </tr>
                    <%      } 
                        } else { 
                    %>
                    <tr>
                        <td colspan="<%= isEducator ? 5 : 4 %>" style="text-align: center; padding: 40px; color: var(--text-muted);">
                            <i class='bx bx-folder-open' style="font-size: 3rem; opacity: 0.5; display: block; margin-bottom: 10px;"></i>
                            No students are currently enrolled in this class.
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </main>

    <div id="enrollModal" class="modal-overlay" style="display: none;">
        <div class="modal-content">
            <h3>Enroll a Student</h3>
            <p>Enter the User ID of the student you want to add to this class.</p>
            <input type="text" id="studentIdInput" placeholder="e.g., 104" autocomplete="off" />
            
            <div class="modal-actions">
                <button class="btn-cancel" onclick="closeEnrollModal()">Cancel</button>
                <button class="btn-confirm-modal" onclick="submitEnrollment()">Enroll Student</button>
            </div>
        </div>
    </div>

    <script>
        let currentClassId = null;

        // 1. Opens the stylish custom modal
        function promptEnrollment(classId) {
            currentClassId = classId;
            document.getElementById('enrollModal').style.display = 'flex';
            document.getElementById('studentIdInput').focus();
        }

        // 2. Closes the modal and flushes the input
        function closeEnrollModal() {
            document.getElementById('enrollModal').style.display = 'none';
            document.getElementById('studentIdInput').value = '';
        }

        // 3. Bundles the values and submits through your hidden form infrastructure
        function submitEnrollment() {
            let studentId = document.getElementById('studentIdInput').value;
            
            if (studentId != null && studentId.trim() !== "") {
                document.getElementById('enrollStudentId').value = studentId.trim();
                document.getElementById('enrollForm').submit();
            } else {
                alert("Please enter a valid User ID."); 
            }
        }
    </script>
</body>
</html>