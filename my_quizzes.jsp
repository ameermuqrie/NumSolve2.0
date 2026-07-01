<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.User" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User u = (User) session.getAttribute("user");
    if (u == null || !"R002".equals(u.getRoleId())) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NumSolve | My Personal Quizzes</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES (Exact Educator Purple Theme) --- */
        :root {
            --educator: #8b5cf6;         
            --educator-hover: #7c3aed;   
            --dark: #2c3e50;
            --light: #f4f6f9;
            --white: #ffffff;
            --gray: #858796;
            --danger: #ef4444;
            --border: #e2e8f0;
            --shadow: 0 4px 6px rgba(0,0,0,0.1);
            --shadow-hover: 0 10px 20px rgba(0,0,0,0.15);
            --transition: all 0.3s ease;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        body { background-color: var(--light); color: var(--dark); min-height: 100vh; display: flex; flex-direction: column; }

        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(15px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .animate-fade-in { animation: fadeInUp 0.5s ease-out forwards; opacity: 0; }

        /* --- COLORED TOP NAVIGATION (UNTOUCHED STRUCTURE) --- */
        .top-nav {
            width: 100%; background: linear-gradient(135deg, var(--educator) 0%, var(--educator-hover) 100%); 
            padding: 10px 30px; display: flex; align-items: center; justify-content: space-between;
            box-shadow: 0 4px 15px rgba(0,0,0,0.15); z-index: 20; color: var(--white);
        }
        .brand { font-size: 1.4rem; font-weight: 700; display: flex; align-items: center; gap: 10px; }
        
        .nav-menu { list-style: none; display: flex; align-items: center; gap: 5px; overflow-x: auto; scrollbar-width: none; }
        .nav-menu::-webkit-scrollbar { display: none; }
        .nav-link {
            display: flex; align-items: center; gap: 10px; padding: 10px; border-radius: 30px; color: rgba(255, 255, 255, 0.8); 
            font-weight: 500; text-decoration: none; max-width: 44px; white-space: nowrap; overflow: hidden;
            transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
        }
        .nav-link i { font-size: 1.4rem; min-width: 24px; text-align: center; }
        .nav-link span { opacity: 0; transform: translateX(-10px); transition: all 0.3s ease; }
        .nav-link:hover, .nav-link.active { background: rgba(255, 255, 255, 0.2); color: var(--white); max-width: 180px; padding: 10px 20px; }
        .nav-link:hover span, .nav-link.active span { opacity: 1; transform: translateX(0); }
        .logout-item { margin-left: 10px; border-left: 1px solid rgba(255,255,255,0.3); padding-left: 10px; }

        /* --- SUB NAVIGATION TABS --- */
        .sub-nav {
            display: flex; gap: 30px; padding: 25px 40px 0; max-width: 1400px; margin: 0 auto; width: 100%;
            border-bottom: 2px solid var(--border);
        }
        .sub-nav-item {
            text-decoration: none; color: var(--gray); font-weight: 600; font-size: 1rem;
            padding-bottom: 12px; position: relative; transition: var(--transition);
            display: flex; align-items: center; gap: 8px;
        }
        .sub-nav-item:hover { color: var(--educator); }
        .sub-nav-item.active { color: var(--educator); }
        .sub-nav-item.active::after {
            content: ''; position: absolute; bottom: -2px; left: 0; width: 100%;
            height: 3px; background-color: var(--educator); border-radius: 3px 3px 0 0;
        }

        /* --- CONTENT AREA --- */
        .main-content { padding: 40px; flex: 1; max-width: 1400px; margin: 0 auto; width: 100%; }
        .header-area { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; }
        .header-area h2 { font-size: 1.8rem; color: var(--dark); font-weight: 600; display: flex; align-items: center; gap: 10px; }
        
        .btn-create {
            background: var(--educator); color: var(--white); padding: 10px 25px; border-radius: 30px; text-decoration: none;
            font-weight: 500; box-shadow: 0 4px 10px rgba(139, 92, 246, 0.3); transition: var(--transition); display: flex; align-items: center; gap: 8px;
        }
        .btn-create:hover { transform: translateY(-2px); background: var(--educator-hover); box-shadow: 0 6px 15px rgba(139, 92, 246, 0.4); }

        .dashboard-card { background: var(--white); border-radius: 12px; padding: 25px; box-shadow: var(--shadow); border: 1px solid var(--border); overflow-x: auto; }

        /* --- CLEAN TABLES --- */
        table { width: 100%; border-collapse: separate; border-spacing: 0; }
        th { font-weight: 600; color: var(--gray); text-transform: uppercase; font-size: 0.8rem; letter-spacing: 0.05em; padding: 16px 15px; border-bottom: 2px solid var(--border); background: #f8fafc; }
        td { padding: 18px 15px; text-align: left; border-bottom: 1px solid #f1f5f9; vertical-align: middle; color: var(--dark); }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background-color: #f8fafc; }

        .badge { display: inline-flex; align-items: center; gap: 5px; padding: 6px 14px; border-radius: 20px; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; }
        .badge-public { background: #ecfdf5; color: #15803d; border: 1px solid #a7f3d0; } 
        .badge-private { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; }

        /* --- ACTION BUTTONS --- */
        .btn-action { padding: 8px 14px; border-radius: 30px; text-decoration: none; font-size: 0.85rem; font-weight: 500; transition: var(--transition); display: inline-flex; align-items: center; gap: 5px; margin-right: 5px; border: 1px solid transparent; }
        .btn-play { background: #eff6ff; color: #3b82f6; }
        .btn-play:hover { background: #3b82f6; color: white; }
        .btn-grades { background: #f5f3ff; color: var(--educator); }
        .btn-grades:hover { background: var(--educator); color: white; }
        .btn-edit { background: #f1f5f9; color: var(--dark); border-color: var(--border); }
        .btn-edit:hover { background: #e2e8f0; }
        .btn-delete { background: #fef2f2; color: var(--danger); margin-right: 0;}
        .btn-delete:hover { background: var(--danger); color: white; }

        .empty-state { text-align: center; padding: 60px 20px; color: var(--gray); }
        .empty-state i { font-size: 3.5rem; color: #cbd5e1; margin-bottom: 15px; }
        .empty-state h3 { color: var(--dark); margin-bottom: 8px; font-weight: 600; }
        
        @media (max-width: 900px) {
            .nav-link.active span { display: none; } 
            .nav-link.active { max-width: 44px; padding: 10px; }
            .nav-link:hover span { display: none; }
            .nav-link:hover { max-width: 44px; padding: 10px; }
        }
    </style>
</head>
<body>

    <nav class="top-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        <ul class="nav-menu">
            <li><a href="${pageContext.request.contextPath}/dashboard/educator.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
            <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
            <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
            <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
            <li><a href="${pageContext.request.contextPath}/manage_classes.jsp" class="nav-link"><i class='bx bxs-school'></i> <span>Classes</span></a></li>
            <li><a href="${pageContext.request.contextPath}/educatorQuizzes" class="nav-link active"><i class='bx bx-task'></i> <span>Quizzes</span></a></li>
            <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
            <li><a href="${pageContext.request.contextPath}/educator/my_materials.jsp" class="nav-link"><i class='bx bxs-cloud-upload'></i> <span>My Materials</span></a></li>
            <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
            <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bxs-log-out-circle'></i> <span>Logout</span></a></li>
        </ul>
    </nav>

    <div class="sub-nav animate-fade-in">
        <a href="educatorQuizzes?view=public" class="sub-nav-item"><i class='bx bx-world'></i> Public Missions Pool</a>
        <a href="educatorQuizzes?view=personal" class="sub-nav-item active"><i class='bx bx-folder'></i> My Personal Missions</a>
    </div>

    <main class="main-content">
        <div class="header-area animate-fade-in">
            <h2><i class='bx bx-folder' style="color: var(--educator);"></i> My Created Missions</h2>
            <a href="CreateQuiz.jsp?type=Public" class="btn-create"><i class='bx bx-plus'></i> Create New Mission</a>
        </div>

        <div class="dashboard-card animate-fade-in">
            <table>
                <thead>
                    <tr>
                        <th>Mission Title</th>
                        <th>Type</th>
                        <th>Time Limit</th>
                        <th>Marks</th>
                        <th>Questions</th>
                        <th>Created On</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <c:set var="myMatchCount" value="0" />
                    <c:forEach var="quiz" items="${quizList}">
                        <c:if test="${quiz.userId == sessionScope.user.userId}">
                            <c:set var="myMatchCount" value="${myMatchCount + 1}" />
                            <c:set var="cleanedType" value="${fn:trim(fn:toUpperCase(quiz.quizType))}" />
                            <tr>
                                <td style="font-weight: 600; color: var(--dark);">${quiz.quizTitle}</td>
                                <td>
                                    <span class="badge ${cleanedType == 'PUBLIC' ? 'badge-public' : 'badge-private'}">
                                        <i class="bx ${cleanedType == 'PUBLIC' ? 'bx-world' : 'bx-lock-alt'}"></i> ${quiz.quizType}
                                    </span>
                                </td>
                                <td style="color: var(--gray);"><i class='bx bx-timer'></i> ${quiz.timeLimit} mins</td>
                                <td style="color: var(--gray);"><i class='bx bx-star'></i> ${quiz.totalMarks} pts</td>
                                <td style="color: var(--gray);"><i class='bx bx-list-ol'></i> <strong style="color: var(--dark);">${quiz.questionCount}</strong> Qs</td>
                                <td style="font-size: 0.9rem; color: var(--gray);">${quiz.createdDate}</td>
                                <td>
                                    <a href="play_quiz.jsp?quizId=${quiz.quizId}" class="btn-action btn-play"><i class='bx bx-play-circle'></i> Play</a>
                                    <a href="educatorQuizzes?action=viewGrades&quizId=${quiz.quizId}&view=personal" class="btn-action btn-grades"><i class='bx bx-bar-chart-alt-2'></i> Grades</a>
                                    <a href="EditQuizServlet?id=${quiz.quizId}" class="btn-action btn-edit"><i class='bx bx-edit-alt'></i> Edit</a>
                                    <a href="DeleteQuizServlet?id=${quiz.quizId}" class="btn-action btn-delete" onclick="return confirm('Are you sure you want to delete this mission?');"><i class='bx bx-trash'></i> Delete</a>
                                </td>
                            </tr>
                        </c:if>
                    </c:forEach>
                    
                    <c:if test="${myMatchCount == 0}">
                        <tr>
                            <td colspan="7">
                                <div class="empty-state">
                                    <i class='bx bx-folder-open'></i>
                                    <h3>You haven't created any missions yet!</h3>
                                    <p>Get started by clicking the "Create New Mission" button above.</p>
                                </div>
                            </td>
                        </tr>
                    </c:if>
                </tbody>
            </table>
        </div>
    </main>
</body>
</html>