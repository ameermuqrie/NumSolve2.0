<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.*, model.*, dao.*" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // 1. Security & Cache Control
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    User u = (User) session.getAttribute("user");
    if (u == null || !"R003".equals(u.getRoleId())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // 2. Smart Context Routing (Public vs Private Classroom Assessments)
    String classIdStr = request.getParameter("classId");
    QuizDAO quizDao = new QuizDAO();
    List<Quiz> quizzesList;

    if (classIdStr != null && !classIdStr.trim().isEmpty()) {
        // PRIVATE MODE: Student entered from a specific classroom dashboard
        int classId = Integer.parseInt(classIdStr);
        
        // Fetch secure quizzes assigned to this class
        quizzesList = quizDao.getClassQuizzesSecure(classId, u.getUserId(), u.getRoleId());
        
        request.setAttribute("isPrivate", true);
        request.setAttribute("classId", classId);
    } else {
        // PUBLIC MODE: Student clicked "Quiz" from the global navigation bar
        quizzesList = quizDao.getAvailableQuizzes(null); 
        request.setAttribute("isPrivate", false);
    }
    
    // Safety check to avoid any downstream NullPointerExceptions
    if (quizzesList == null) {
        quizzesList = new ArrayList<>();
    }
    
    // Synchronize data structure with downstream JSTL loop
    request.setAttribute("availableQuizzes", quizzesList);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Available Quizzes | NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES & THEME ADJUSTMENTS (STUDENT BLUE) --- */
        :root {
            --dark: #0f172a;
            --white: #ffffff;
            --gray: #64748b;
            --border: rgba(255, 255, 255, 0.4);
            --shadow: 0 10px 30px rgba(0,0,0,0.05);
            --shadow-hover: 0 20px 40px rgba(0,0,0,0.1);
            --transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
            --radius: 20px;
            
            /* Student Style Palette Synchronization */
            --primary: #3b82f6; 
            --primary-hover: #2563eb; 
            --primary-glow: rgba(59, 130, 246, 0.3);
            --bg-1: #dbeafe; 
            --bg-2: #bfdbfe; 
            --bg-3: #93c5fd;
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

        /* --- FLOATING GLASS NAV --- */
        .top-nav {
            width: 95%; max-width: 1400px; margin: 25px auto;
            background: rgba(255, 255, 255, 0.5); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
            padding: 12px 25px; display: flex; align-items: center; justify-content: space-between;
            border-radius: 50px; box-shadow: 0 15px 35px var(--primary-glow);
            border: 1px solid var(--border); z-index: 100; position: sticky; top: 25px;
            gap: 20px; transition: var(--transition);
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

        /* Expandable Pill Nav Links */
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

        /* Workspace Hub Context Class Buttons */
        .back-btn { 
            color: var(--primary); text-decoration: none; display: inline-flex; align-items: center; gap: 8px; 
            font-weight: 700; background: rgba(255,255,255,0.7); padding: 10px 20px; 
            border-radius: 40px; transition: var(--transition); border: 1px solid var(--border);
            font-size: 0.95rem;
        }
        .back-btn:hover { background: var(--white); box-shadow: var(--shadow); transform: translateY(-2px); color: var(--primary-hover); }
        .back-btn i { font-size: 1.3rem; }

        /* --- MAIN CONTENT & HEADER LAYOUT --- */
        .main-content { padding: 10px 20px 40px 20px; flex: 1; max-width: 1400px; width: 100%; margin: 0 auto; }
        
        .header-area {
            display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 20px;
            margin-bottom: 40px; background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); 
            padding: 30px 40px; border-radius: var(--radius); box-shadow: var(--shadow); 
            border: 1px solid var(--border);
        }
        .header-area h2 { font-size: 2.2rem; color: var(--dark); font-weight: 800; display: flex; align-items: center; gap: 12px; letter-spacing: -0.5px;}
        .header-area p { color: var(--gray); font-size: 1.1rem; margin-top: 5px; font-weight: 500;}

        /* --- MODERN GLASS SEARCH BAR --- */
        .search-container { position: relative; max-width: 380px; width: 100%; }
        .search-container i {
            position: absolute; left: 18px; top: 50%; transform: translateY(-50%);
            color: var(--gray); font-size: 1.25rem; transition: var(--transition);
        }
        .search-input {
            width: 100%; padding: 14px 16px 14px 50px; border: 1px solid var(--border);
            border-radius: 30px; font-size: 0.95rem; font-weight: 500; outline: none;
            color: var(--dark); transition: var(--transition); background: rgba(255, 255, 255, 0.7);
            backdrop-filter: blur(5px); box-shadow: 0 4px 10px rgba(0,0,0,0.02);
        }
        .search-input:hover { background: rgba(255, 255, 255, 0.9); }
        .search-input:focus {
            background: var(--white); border-color: var(--primary);
            box-shadow: 0 8px 20px var(--primary-glow);
        }
        .search-input:focus + i { color: var(--primary); }

        /* --- PREMIUM QUIZ GRID & CARDS --- */
        .quiz-grid {
            display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); 
            gap: 35px; padding-top: 10px;
        }

        .quiz-card {
            background: linear-gradient(145deg, rgba(255, 255, 255, 0.95) 0%, rgba(255, 255, 255, 0.8) 100%);
            backdrop-filter: blur(20px); border-radius: 24px; padding: 0; 
            box-shadow: 0 15px 35px rgba(15, 23, 42, 0.04), 0 5px 15px rgba(0,0,0,0.02);
            position: relative; overflow: hidden;
            transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275), box-shadow 0.4s ease, border-color 0.4s ease;
            display: flex; flex-direction: column; border: 1px solid rgba(255, 255, 255, 0.9);
            will-change: transform;
        }
        .quiz-card:hover { 
            box-shadow: 0 25px 50px rgba(59, 130, 246, 0.15), 0 10px 20px rgba(0,0,0,0.04); 
            border-color: rgba(59, 130, 246, 0.4); z-index: 10;
        }

        .quiz-image { width: 100%; height: 170px; position: relative; background: #e2e8f0; border-radius: 24px 24px 0 0; overflow: hidden; }
        .quiz-image img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.6s cubic-bezier(0.25, 1, 0.5, 1); }
        .quiz-card:hover .quiz-image img { transform: scale(1.08); }
        
        .quiz-image::after {
            content: ''; position: absolute; inset: 0;
            background: linear-gradient(180deg, rgba(0,0,0,0) 30%, rgba(15,23,42,0.6) 100%); pointer-events: none;
        }

        /* Frosted Glass Custom Badges */
        .quiz-badge {
            position: absolute; top: 16px; right: 16px; padding: 8px 16px; 
            border-radius: 30px; font-size: 0.75rem; font-weight: 700; 
            letter-spacing: 0.5px; text-transform: uppercase; z-index: 2; 
            box-shadow: 0 8px 20px rgba(0,0,0,0.15); backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px); display: flex; align-items: center; gap: 6px;
        }
        .badge-public { background: rgba(255, 255, 255, 0.25); color: #ffffff; border: 1px solid rgba(255, 255, 255, 0.5); } 
        .badge-private { background: rgba(245, 158, 11, 0.35); color: #ffffff; border: 1px solid rgba(245, 158, 11, 0.5); }

        .quiz-content { padding: 24px; display: flex; flex-direction: column; flex-grow: 1; }
        .quiz-title { font-size: 1.35rem; font-weight: 800; color: var(--dark); margin-bottom: 8px; line-height: 1.3; }
        
        .quiz-desc { 
            color: var(--gray); font-size: 0.95rem; margin-bottom: 24px; line-height: 1.6; 
            flex-grow: 1; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; 
            overflow: hidden; font-weight: 500;
        }

        /* Pill-Shaped Stats Container Layout */
        .quiz-stats { display: flex; gap: 12px; margin-bottom: 24px; font-size: 0.85rem; font-weight: 700; }
        .quiz-stats div { 
            display: flex; align-items: center; gap: 6px; color: #475569; 
            background: rgba(241, 245, 249, 0.8); padding: 8px 14px; border-radius: 12px;
            box-shadow: inset 0 2px 4px rgba(255, 255, 255, 0.6);
        }
        .quiz-stats i.bx-timer { color: #0ea5e9; font-size: 1.3rem; }
        .quiz-stats i.bx-star { color: #f59e0b; font-size: 1.3rem; }

        /* Premium Action Buttons */
        .btn-play {
            background: linear-gradient(135deg, var(--primary) 0%, #6366f1 100%); color: var(--white); 
            padding: 14px 20px; border-radius: 14px; text-align: center; text-decoration: none; 
            font-weight: 700; letter-spacing: 0.5px; transition: all 0.3s ease;
            display: flex; align-items: center; justify-content: center; gap: 10px; 
            width: 100%; border: none; box-shadow: 0 8px 20px rgba(99, 102, 241, 0.25); 
            font-size: 1rem; position: relative; z-index: 1; overflow: hidden; cursor: pointer;
        }
        .btn-play::before {
            content: ''; position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            background: linear-gradient(135deg, #6366f1 0%, var(--primary) 100%);
            z-index: -1; transition: opacity 0.4s ease; opacity: 0;
        }
        .btn-play:hover { transform: translateY(-3px); box-shadow: 0 12px 25px rgba(99, 102, 241, 0.45); }
        .btn-play:hover::before { opacity: 1; }
        .btn-play i { font-size: 1.3rem; transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
        .btn-play:hover i { transform: translateX(6px) scale(1.1); }

        /* Empty State Layout Fallbacks */
        .empty-state {
            grid-column: 1 / -1; text-align: center; padding: 60px 20px;
            background: rgba(255, 255, 255, 0.6); backdrop-filter: blur(10px); border-radius: var(--radius);
            box-shadow: var(--shadow); border: 1px dashed rgba(100, 116, 139, 0.3);
        }
        .empty-state i { font-size: 4rem; color: #cbd5e1; margin-bottom: 15px; }
        .empty-state h3 { color: var(--dark); margin-bottom: 10px; font-weight: 800;}
        .empty-state p { color: var(--gray); font-weight: 500;}

        /* --- TABLET BREAKPOINT (MAX-WIDTH: 1024PX) --- */
        @media (max-width: 1024px) {
            .nav-link span { display: none !important; }
            .nav-link.active, .nav-link:hover { max-width: 44px; padding: 10px; justify-content: center; }
            .nav-link i { margin: 0; }
            
            .header-area { flex-direction: column; align-items: flex-start; gap: 20px; padding: 25px 30px; }
            .search-container { max-width: 100%; }
        }

        /* --- MOBILE BREAKPOINT (MAX-WIDTH: 768PX) --- */
        @media (max-width: 768px) {
            .top-nav { flex-direction: column; gap: 15px; border-radius: 25px; padding: 15px 20px; width: 92%; margin: 15px auto; }
            .brand { justify-content: center; width: 100%; }
            .nav-menu { flex-direction: row; flex-wrap: wrap; justify-content: center; width: 100%; gap: 8px; }
            .logout-item { margin-left: 0; border-left: none; padding-left: 0; }
            
            .header-area h2 { font-size: 1.8rem; }
            .quiz-grid { gap: 20px; }
        }
    </style>
</head>
<body>

    <canvas id="mathCanvas" style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: -1; pointer-events: none; opacity: 0.4;"></canvas>

    <nav class="top-nav animated-nav">
        <div class="brand"><i class='bx bxs-cube-alt'></i> NumSolve</div>
        
        <c:choose>
            <c:when test="${isPrivate}">
                <a href="${pageContext.request.contextPath}/class_dashboard.jsp?classId=${classId}" class="back-btn">
                    <i class='bx bx-left-arrow-alt'></i> Workspace Hub
                </a>
            </c:when>
            
            <c:otherwise>
                <ul class="nav-menu">
                    <li><a href="${pageContext.request.contextPath}/dashboard/student.jsp" class="nav-link"><i class='bx bxs-dashboard'></i> <span>Dashboard</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/solver.jsp" class="nav-link"><i class='bx bxs-calculator'></i> <span>Compute</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/recommendation.jsp" class="nav-link"><i class='bx bxs-bulb'></i> <span>Recommend</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/computations.jsp" class="nav-link"><i class='bx bxs-report'></i> <span>Records</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/student_classes.jsp" class="nav-link"><i class='bx bxs-group'></i> <span>Classes</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/StudentDashboardServlet" class="nav-link active"><i class='bx bx-task'></i> <span>Quizzes</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/materials.jsp" class="nav-link"><i class='bx bxs-book-content'></i> <span>Materials</span></a></li>
                    <li><a href="${pageContext.request.contextPath}/profile.jsp" class="nav-link"><i class='bx bxs-user'></i> <span>Profile</span></a></li>
                    <li class="logout-item"><a href="${pageContext.request.contextPath}/logout" class="nav-link"><i class='bx bx-power-off'></i> <span>Logout</span></a></li>
                </ul>
            </c:otherwise>
        </c:choose>
    </nav>

    <main class="main-content">
        
        <div class="header-area animated-panel delay-1">
            <div>
                <c:choose>
                    <c:when test="${isPrivate}">
                        <h2><i class='bx bx-laptop' style="color: var(--primary);"></i> Classroom Mission Hub</h2>
                        <p>Complete assigned quizzes and track submission timelines below.</p>
                    </c:when>
                    <c:otherwise>
                        <h2><i class='bx bx-world' style="color: var(--primary);"></i> Public Mission Hub</h2>
                        <p>Select an open challenge to practice your numeric computation skills.</p>
                    </c:otherwise>
                </c:choose>
            </div>
            
            <div class="search-container">
                <input type="text" id="quizSearch" class="search-input" placeholder="Search quizzes by title or keyword...">
                <i class='bx bx-search'></i>
            </div>
        </div>

        <div class="quiz-grid animated-panel delay-2">
            <c:choose>
                <c:when test="${empty availableQuizzes}">
                    <div class="empty-state">
                        <i class='bx bx-ghost'></i>
                        <h3>No Active Assessments Found</h3>
                        <p>There are no tasks assigned under this section right now. If you believe this is an error, ensure you are enrolled in the class.</p>
                    </div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="quiz" items="${availableQuizzes}">
                        <div class="quiz-card">
                            
                            <div class="quiz-image">
                                <c:choose>
                                    <c:when test="${not empty quiz.photoPath}">
                                        <img src="${pageContext.request.contextPath}/${quiz.photoPath}" alt="Quiz Cover">
                                    </c:when>
                                    <c:otherwise>
                                        <img src="https://images.unsplash.com/photo-1509228468518-180dd4864904?q=80&w=800&auto=format&fit=crop" alt="Default Cover">
                                    </c:otherwise>
                                </c:choose>
                                
                                <c:choose>
                                    <c:when test="${isPrivate}">
                                        <span class="quiz-badge badge-private">
                                            <i class='bx bx-lock-alt'></i> Required Assignment
                                        </span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="quiz-badge badge-public">
                                            <i class='bx bx-world'></i> General Practice
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                            </div>

                            <div class="quiz-content">
                                <h3 class="quiz-title">${quiz.quizTitle}</h3>
                                <p class="quiz-desc" title="${quiz.quizDescription}">${quiz.quizDescription}</p>
                                
                                <div class="quiz-stats">
                                    <div><i class='bx bx-timer'></i> ${quiz.timeLimit} Mins</div>
                                    <div><i class='bx bx-star'></i> ${quiz.totalMarks} Pts</div>
                                </div>
                                
                                <a href="PlayQuizServlet?quizId=${quiz.quizId}<c:if test='${isPrivate}'>&classId=${classId}</c:if>" class="btn-play">
                                    Start Mission <i class='bx bx-right-arrow-alt'></i>
                                </a>
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
        
    </main>
    <script>
        document.addEventListener("DOMContentLoaded", () => {
            
            // --- 1. JELLY SEARCH BAR & SEARCH LOGIC ---
            const searchInput = document.getElementById('quizSearch');
            const quizCards = document.querySelectorAll('.quiz-card');
            const gridContainer = document.querySelector('.quiz-grid');
            
            searchInput.addEventListener('input', function() {
                // Jelly Bounce Effect
                this.classList.remove('jelly-active');
                void this.offsetWidth; // Trigger reflow to restart animation
                this.classList.add('jelly-active');

                // Search Filter Logic
                const searchTerm = this.value.toLowerCase().trim();
                let visibleCardsCount = 0;
                
                quizCards.forEach(card => {
                    const title = card.querySelector('.quiz-title').textContent.toLowerCase();
                    const description = card.querySelector('.quiz-desc').textContent.toLowerCase();
                    
                    if (title.includes(searchTerm) || description.includes(searchTerm)) {
                        card.style.display = 'flex';
                        visibleCardsCount++;
                    } else {
                        card.style.display = 'none';
                    }
                });
                
                const dynamicEmptyState = document.getElementById('search-empty-state');
                if (dynamicEmptyState) dynamicEmptyState.remove();
                
                if (visibleCardsCount === 0 && quizCards.length > 0) {
                    const fallbackDiv = document.createElement('div');
                    fallbackDiv.id = 'search-empty-state';
                    fallbackDiv.className = 'empty-state animated-panel';
                    fallbackDiv.style.gridColumn = '1 / -1';
                    fallbackDiv.innerHTML = 
                        '<i class="bx bx-search-alt" style="font-size: 4rem; color: #cbd5e1; margin-bottom: 15px; display: block;"></i>' +
                        '<h3>No Matching Quizzes Found</h3>' +
                        '<p>We couldn\'t find anything matching "' + this.value + '". Try checking your spelling!</p>';
                    gridContainer.appendChild(fallbackDiv);
                }
            });

            // --- 2. 3D "TRADING CARD" TILT EFFECT ---
            quizCards.forEach(card => {
                card.addEventListener('mousemove', (e) => {
                    const rect = card.getBoundingClientRect();
                    const x = e.clientX - rect.left; // x position within the element.
                    const y = e.clientY - rect.top;  // y position within the element.
                    
                    const centerX = rect.width / 2;
                    const centerY = rect.height / 2;
                    
                    const rotateX = ((y - centerY) / centerY) * -8; // Max 8 degrees
                    const rotateY = ((x - centerX) / centerX) * 8;
                    
                    card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-12px) scale(1.02)`;
                    card.style.transition = 'transform 0.1s ease-out';
                });
                
                card.addEventListener('mouseleave', () => {
                    card.style.transform = `perspective(1000px) rotateX(0deg) rotateY(0deg) translateY(0px) scale(1)`;
                    card.style.transition = 'transform 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
                });
            });

            // --- 3. FLOATING MATH MAGIC (CANVAS BACKGROUND) ---
            const canvas = document.getElementById('mathCanvas');
            const ctx = canvas.getContext('2d');
            let width, height;
            let particles = [];
            const symbols = ['+', '-', '×', '÷', '=', 'π', '∞', '%'];

            function resize() {
                width = canvas.width = window.innerWidth;
                height = canvas.height = window.innerHeight;
            }
            window.addEventListener('resize', resize);
            resize();

            class MathParticle {
                constructor() {
                    this.x = Math.random() * width;
                    this.y = Math.random() * height;
                    this.size = Math.random() * 15 + 10;
                    this.speedY = (Math.random() * 0.5 + 0.2) * -1; // float upwards
                    this.speedX = (Math.random() - 0.5) * 0.5; // slight left/right drift
                    this.symbol = symbols[Math.floor(Math.random() * symbols.length)];
                    this.opacity = Math.random() * 0.5 + 0.1;
                    // Mix of soft blues and teals
                    const colors = ['#3b82f6', '#0ea5e9', '#6366f1', '#93c5fd'];
                    this.color = colors[Math.floor(Math.random() * colors.length)];
                    this.rotation = Math.random() * 360;
                    this.rotSpeed = (Math.random() - 0.5) * 2;
                }
                update() {
                    this.y += this.speedY;
                    this.x += this.speedX;
                    this.rotation += this.rotSpeed;
                    // Reset if it floats off screen
                    if (this.y < -50) {
                        this.y = height + 50;
                        this.x = Math.random() * width;
                    }
                }
                draw() {
                    ctx.save();
                    ctx.translate(this.x, this.y);
                    ctx.rotate(this.rotation * Math.PI / 180);
                    ctx.fillStyle = this.color;
                    ctx.globalAlpha = this.opacity;
                    ctx.font = "bold " + this.size + "px Poppins";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillText(this.symbol, 0, 0);
                    ctx.restore();
                }
            }

            // Create particles based on screen size so it isn't crowded
            const particleCount = Math.floor(window.innerWidth / 30);
            for (let i = 0; i < particleCount; i++) {
                particles.push(new MathParticle());
            }

            function animateCanvas() {
                ctx.clearRect(0, 0, width, height);
                particles.forEach(p => {
                    p.update();
                    p.draw();
                });
                requestAnimationFrame(animateCanvas);
            }
            animateCanvas();
        });
    </script>

</body>
</html>