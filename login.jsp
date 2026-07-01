<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login | NumSolve 2.0</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght=300;400;500;600;700&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES --- */
        :root {
            --primary: #6366f1; 
            --secondary: #8b5cf6; 
            --card-glow: rgba(99, 102, 241, 0); 
            
            --dark: #1e293b;
            --gray: #64748b;
            --light: #f8fafc;
            --border: #e2e8f0;
            --white: #ffffff;
            --transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }

        /* --- ANIMATED BACKGROUND --- */
        body {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
            background-size: 400% 400%;
            animation: gradientBG 15s ease infinite;
            padding: 20px;
            overflow-x: hidden;
            overflow-y: auto; 
        }

        @keyframes gradientBG {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }

        /* --- AUTHENTICATION CARD --- */
        .auth-wrapper {
            width: 100%;
            max-width: 420px;
            perspective: 1000px;
            z-index: 10;
        }

        .auth-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            padding: 40px 30px;
            border-radius: 20px;
            text-align: center;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.2), 0 0 30px var(--card-glow);
            transition: var(--transition);
            animation: floatUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards;
            opacity: 0;
            transform: translateY(30px);
        }

        .auth-card.success-animate {
            transform: scale(0.9) translateY(-20px) !important;
            opacity: 0 !important;
            pointer-events: none;
        }

        @keyframes floatUp {
            to { opacity: 1; transform: translateY(0); }
        }

        /* --- BRANDING --- */
        .auth-logo {
            width: 70px;
            height: 70px;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 15px;
            box-shadow: 0 8px 15px var(--card-glow);
            transform: rotate(-5deg);
            transition: var(--transition);
        }
        .auth-card:hover .auth-logo { transform: rotate(0deg) scale(1.05); }
        .auth-logo i { font-size: 2.5rem; color: var(--white); }

        .auth-title { font-size: 1.8rem; font-weight: 700; color: var(--dark); margin-bottom: 5px; }
        .auth-subtitle { color: var(--gray); font-size: 0.95rem; margin-bottom: 30px; }

        /* --- ALERTS --- */
        .alert {
            padding: 12px 15px; border-radius: 10px; font-size: 0.9rem; margin-bottom: 20px;
            display: flex; align-items: center; gap: 10px; text-align: left; font-weight: 500;
            animation: slideDown 0.4s ease;
        }
        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .alert-error { background: #fee2e2; color: #b91c1c; border-left: 4px solid #ef4444; }
        .alert-error i { color: #ef4444; font-size: 1.2rem; }
        .alert-success { background: #dcfce7; color: #15803d; border-left: 4px solid #22c55e; }
        .alert-success i { color: #22c55e; font-size: 1.2rem; }

        /* --- INPUT FIELDS --- */
        .input-group { position: relative; margin-bottom: 20px; text-align: left; }
        .input-group label {
            display: block; font-size: 0.85rem; font-weight: 600; color: var(--dark);
            margin-bottom: 8px; margin-left: 5px; text-transform: uppercase; letter-spacing: 0.5px;
        }
        
        .input-wrapper { position: relative; }
        .input-wrapper i {
            position: absolute; left: 15px; top: 50%; transform: translateY(-50%);
            color: var(--gray); font-size: 1.2rem; transition: var(--transition);
        }
        .input-field {
            width: 100%; padding: 14px 15px 14px 45px; border: 2px solid var(--border);
            border-radius: 12px; font-size: 0.95rem; background: var(--light);
            outline: none; transition: var(--transition); color: var(--dark);
        }
        .input-field:focus { 
            border-color: var(--primary); 
            background: var(--white); 
            box-shadow: 0 0 0 4px var(--card-glow); 
        }
        .input-wrapper:focus-within i { color: var(--primary); }

        /* --- BUTTONS --- */
        .btn {
            width: 100%; padding: 14px; border-radius: 12px; font-weight: 600; font-size: 1rem;
            cursor: pointer; transition: var(--transition); border: none;
            display: flex; align-items: center; justify-content: center; gap: 8px;
        }
        .btn-primary {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: var(--white); box-shadow: 0 4px 15px var(--card-glow); margin-top: 10px;
        }
        .btn-primary:hover {
            transform: translateY(-2px); box-shadow: 0 8px 25px var(--card-glow);
        }
        
        .btn-secondary {
            background: transparent; color: var(--primary); border: 2px solid var(--border);
            margin-top: 15px;
        }
        .btn-secondary:hover {
            border-color: var(--primary); background: var(--card-glow); transform: translateY(-2px);
        }

        .forgot-link {
            display: block; text-align: right; font-size: 0.85rem; color: var(--primary);
            text-decoration: none; margin-top: -10px; margin-bottom: 20px; font-weight: 500;
            cursor: pointer;
        }
        .forgot-link:hover { text-decoration: underline; }

        /* --- LOADING SPINNER --- */
        .spinner {
            border: 3px solid rgba(255,255,255,0.3);
            border-top: 3px solid var(--white);
            border-radius: 50%;
            width: 20px;
            height: 20px;
            animation: spin 1s linear infinite;
            display: none;
        }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

        /* --- FORGOT PASSWORD MODAL --- */
        .modal-overlay {
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(15, 23, 42, 0.6); backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            display: flex; justify-content: center; align-items: center;
            z-index: 1000; opacity: 0; pointer-events: none; transition: var(--transition);
        }
        .modal-overlay.active { opacity: 1; pointer-events: auto; }

        .modal-card {
            background: rgba(255, 255, 255, 0.95); padding: 35px 30px; border-radius: 20px;
            width: 90%; max-width: 380px; text-align: center;
            box-shadow: 0 25px 50px rgba(0,0,0,0.25);
            transform: scale(0.9) translateY(20px); transition: var(--transition);
        }
        .modal-overlay.active .modal-card { transform: scale(1) translateY(0); }

        .modal-icon {
            width: 60px; height: 60px; margin: 0 auto 15px; border-radius: 50%;
            background: var(--card-glow); color: var(--primary); font-size: 2rem;
            display: flex; justify-content: center; align-items: center;
        }
        .modal-card h3 { font-size: 1.4rem; color: var(--dark); margin-bottom: 10px; }
        .modal-card p { font-size: 0.9rem; color: var(--gray); margin-bottom: 20px; line-height: 1.5; }
        
        .phone-box {
            background: var(--light); border: 2px dashed var(--border); border-radius: 12px;
            padding: 15px; font-size: 1.3rem; font-weight: 700; color: var(--primary);
            display: flex; justify-content: center; align-items: center; gap: 10px; margin-bottom: 25px;
        }

        /* --- MOBILE MEDIA QUERIES --- */
        @media (max-width: 480px) {
            body {
                padding: 15px 10px;
                align-items: flex-start; 
                padding-top: 6vh;
            }
            .auth-card {
                padding: 30px 20px;
                border-radius: 16px;
            }
            .auth-title {
                font-size: 1.5rem;
            }
            .auth-subtitle {
                margin-bottom: 20px;
                font-size: 0.88rem;
            }
            .input-field {
                padding: 12px 15px 12px 42px;
                font-size: 0.9rem;
            }
            .input-wrapper i {
                left: 14px;
                font-size: 1.1rem;
            }
            .btn {
                padding: 12px;
                font-size: 0.95rem;
            }
            .modal-card {
                padding: 25px 15px;
                width: 95%;
            }
            .phone-box {
                font-size: 1.15rem;
                padding: 12px;
            }
        }
    </style>
</head>
<body>

    <div class="auth-wrapper">
        <div class="auth-card" id="loginCard">
            
            <div class="auth-logo">
                <i class='bx bxs-cube-alt'></i>
            </div>
            
            <h1 class="auth-title">Welcome Back</h1>
            <p class="auth-subtitle">Sign in to NumSolve 2.0</p>

            <% if(request.getParameter("error") != null) { %>
                <div class="alert alert-error">
                    <i class='bx bxs-error-circle'></i> 
                    <span><%= request.getParameter("error") %></span>
                </div>
            <% } %>
            <% if(request.getParameter("msg") != null) { %>
                <div class="alert alert-success">
                    <i class='bx bxs-check-circle'></i> 
                    <span><%= request.getParameter("msg") %></span>
                </div>
            <% } %>

            <form action="<%= request.getContextPath() %>/auth" method="post" id="loginForm">
                <input type="hidden" name="action" value="login">
                
                <div class="input-group">
                    <label>User ID</label>
                    <div class="input-wrapper">
                        <i class='bx bx-user'></i>
                        <input type="text" name="username" id="usernameInput" class="input-field" placeholder="Enter your ID (admin, educator, student)" required autocomplete="off">
                    </div>
                </div>

                <div class="input-group">
                    <label>Password</label>
                    <div class="input-wrapper">
                        <i class='bx bx-lock-alt'></i>
                        <input type="password" name="password" class="input-field" placeholder="Min 8 characters" required minlength="8">
                    </div>
                </div>

                <a class="forgot-link" id="openForgotModal">Forgot password?</a>

                <button type="submit" class="btn btn-primary" id="submitBtn">
                    <div class="spinner" id="btnSpinner"></div>
                    <span id="btnText">Sign In</span> <i class='bx bx-right-arrow-alt' id="btnIcon"></i>
                </button>
                
                <button type="button" class="btn btn-secondary" onclick="location.href='<%= request.getContextPath() %>/register.jsp'">
                    Create an Account
                </button>
            </form>
            
        </div>
    </div>

    <div class="modal-overlay" id="forgotModal">
        <div class="modal-card">
            <div class="modal-icon">
                <i class='bx bx-support'></i>
            </div>
            <h3>Need Help?</h3>
            <p>For security purposes, please contact the system administrator to reset your credentials.</p>
            
            <div class="phone-box">
                <i class='bx bxs-phone'></i>
                <span>09-xxxxxxx</span>
            </div>

            <button class="btn btn-primary" id="closeForgotModal">Got it, thanks!</button>
        </div>
    </div>

    <script>
        const root = document.documentElement;
        const usernameInput = document.getElementById('usernameInput');
        let typingTimer;
        const doneTypingInterval = 300; 

        // 1. Dynamic Database Role Checking
        usernameInput.addEventListener('input', function(e) {
            clearTimeout(typingTimer);
            const val = e.target.value.trim();

            if (val.length === 0) {
                resetColors();
                return;
            }

            typingTimer = setTimeout(() => {
                fetch('<%= request.getContextPath() %>/checkRole.jsp?username=' + encodeURIComponent(val))
                    .then(response => response.text())
                    .then(role => {
                        role = role.trim(); 
                        
                        if (role === 'admin') {
                            root.style.setProperty('--primary', '#ef4444');
                            root.style.setProperty('--secondary', '#dc2626');
                            root.style.setProperty('--card-glow', 'rgba(239, 68, 68, 0.25)');
                        } 
                        else if (role === 'educator') {
                            root.style.setProperty('--primary', '#8b5cf6');
                            root.style.setProperty('--secondary', '#6d28d9');
                            root.style.setProperty('--card-glow', 'rgba(139, 92, 246, 0.3)');
                        } 
                        else if (role === 'student') {
                            root.style.setProperty('--primary', '#3b82f6');
                            root.style.setProperty('--secondary', '#2563eb');
                            root.style.setProperty('--card-glow', 'rgba(59, 130, 246, 0.3)');
                        } 
                        else {
                            resetColors();
                        }
                    })
                    .catch(err => console.error("Database check failed", err));
            }, doneTypingInterval);
        });

        function resetColors() {
            root.style.setProperty('--primary', '#6366f1');
            root.style.setProperty('--secondary', '#8b5cf6');
            root.style.setProperty('--card-glow', 'rgba(99, 102, 241, 0)');
        }

        // 2. Safe Mobile Form Submission Animation
        const loginForm = document.getElementById('loginForm');
        const loginCard = document.getElementById('loginCard');
        const submitBtn = document.getElementById('submitBtn');
        const btnText = document.getElementById('btnText');
        const btnIcon = document.getElementById('btnIcon');
        const btnSpinner = document.getElementById('btnSpinner');
        
        let isAnimating = false;

        loginForm.addEventListener('submit', function(e) {
            if (!isAnimating) {
                e.preventDefault(); // Stop initial submission to perform visual change
                isAnimating = true;
                
                // Trigger button loading UI
                btnText.textContent = "Authenticating...";
                btnIcon.style.display = "none";
                btnSpinner.style.display = "block";
                submitBtn.style.pointerEvents = "none"; 
                
                // Start exit animation smoothly
                setTimeout(() => {
                    loginCard.classList.add('success-animate');
                    
                    // Allow natural form post context without breaking mobile views
                    setTimeout(() => {
                        loginForm.submit();
                    }, 250); 
                }, 400); 
            }
        });

        // 3. Forgot Password Modal Logic
        const forgotModal = document.getElementById('forgotModal');
        const openForgotModal = document.getElementById('openForgotModal');
        const closeForgotModal = document.getElementById('closeForgotModal');

        openForgotModal.addEventListener('click', (e) => {
            e.preventDefault();
            forgotModal.classList.add('active');
        });

        closeForgotModal.addEventListener('click', () => {
            forgotModal.classList.remove('active');
        });

        forgotModal.addEventListener('click', (e) => {
            if(e.target === forgotModal) {
                forgotModal.classList.remove('active');
            }
        });
    </script>
</body>
</html>