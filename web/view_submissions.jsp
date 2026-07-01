<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.User, model.Classroom, dao.ClassDAO" %>
<%
    // 1. Security Check
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    if (u == null || !"R002".equals(u.getRoleId())) { 
        response.sendRedirect("login.jsp"); 
        return; 
    }

    String classIdStr = request.getParameter("classId");
    String assessmentIdStr = request.getParameter("assessmentId");

    if (classIdStr == null || assessmentIdStr == null) {
        response.sendRedirect("manage_classes.jsp"); return;
    }
    
    int classId = Integer.parseInt(classIdStr);

    // 2. Verify Ownership
    ClassDAO classDao = new ClassDAO();
    Classroom currentClass = classDao.getClassById(classId);
    
    if (currentClass == null || currentClass.getUserId() != u.getUserId()) {
        response.sendRedirect("manage_classes.jsp?status=unauthorized"); return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Assessment Submissions | NumSolve Hub</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    <style>
        :root {
            --educator: #8b5cf6;       
            --educator-hover: #7c3aed; 
            --dark: #2c3e50;
            --light: #f4f6f9;
            --white: #ffffff;
            --gray: #858796;
            --border: #e2e8f0;
            --shadow: 0 4px 6px rgba(0,0,0,0.05);
        }
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        body { background-color: var(--light); color: var(--dark); min-height: 100vh; }
        
        .top-nav { width: 100%; background: linear-gradient(135deg, var(--educator) 0%, var(--educator-hover) 100%); padding: 15px 30px; display: flex; align-items: center; justify-content: space-between; box-shadow: 0 4px 15px rgba(0,0,0,0.15); color: var(--white); }
        .brand { font-size: 1.4rem; font-weight: 700; display: flex; align-items: center; gap: 10px; }
        .back-btn { color: white; text-decoration: none; padding: 8px 15px; border-radius: 8px; background: rgba(255,255,255,0.2); display: flex; align-items: center; gap: 5px; font-weight: 500;}
        
        .main-content { padding: 40px; max-width: 1000px; margin: 0 auto; }
        
        .header-card { background: var(--white); padding: 30px; border-radius: 12px; box-shadow: var(--shadow); margin-bottom: 30px; border-left: 5px solid #f59e0b; }
        .header-card h1 { font-size: 1.8rem; margin-bottom: 5px; color: var(--dark); }
        
        .empty-state { text-align: center; padding: 60px 20px; background: var(--white); border-radius: 12px; border: 2px dashed var(--border); }
        .empty-state i { font-size: 4rem; color: #cbd5e1; margin-bottom: 15px; }
        .empty-state h3 { color: var(--dark); margin-bottom: 5px; }
        .empty-state p { color: var(--gray); font-size: 0.95rem; }
    </style>
</head>
<body>
    <nav class="top-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <a href="view_class.jsp?id=<%= classId %>&tab=quizzes" class="back-btn"><i class='bx bx-arrow-back'></i> Go Back to Class</a>
    </nav>

    <main class="main-content">
        <div class="header-card">
            <h1><i class='bx bx-folder-open' style="color: #f59e0b;"></i> File Submissions Workspace</h1>
            <p style="color: var(--gray);">Viewing uploaded files for Assessment ID: <%= assessmentIdStr %></p>
        </div>

        <div class="empty-state">
            <i class='bx bx-cloud-download'></i>
            <h3>Awaiting Submissions</h3>
            <p>Students have not uploaded any files for this assessment yet.</p>
        </div>
    </main>
</body>
</html>