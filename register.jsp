<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register | NumSolve 2.0</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght=300;400;500;600;700&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL VARIABLES --- */
        :root {
            --primary: #6366f1; /* Indigo */
            --primary-hover: #4f46e5;
            --secondary: #8b5cf6; /* Purple */
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
            max-width: 550px; 
            perspective: 1000px;
            z-index: 10;
        }

        .auth-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            padding: 40px 30px;
            border-radius: 20px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.2);
            text-align: center;
            animation: floatUp 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards;
            opacity: 0;
            transform: translateY(30px);
            transition: var(--transition);
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
            box-shadow: 0 8px 15px rgba(99, 102, 241, 0.3);
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

        /* --- INPUT FIELDS --- */
        .input-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 20px; }
        
        .input-group { position: relative; text-align: left; margin-bottom: 20px; }
        .input-grid .input-group { margin-bottom: 0; } 
        
        .input-group label {
            display: block; font-size: 0.85rem; font-weight: 600; color: var(--dark);
            margin-bottom: 8px; margin-left: 5px; text-transform: uppercase; letter-spacing: 0.5px;
        }
        
        .input-wrapper { position: relative; }
        .input-wrapper i.icon-main {
            position: absolute; left: 15px; top: 50%; transform: translateY(-50%);
            color: var(--gray); font-size: 1.2rem; transition: var(--transition); pointer-events: none;
        }
        .input-field {
            width: 100%; padding: 14px 15px 14px 45px; border: 2px solid var(--border);
            border-radius: 12px; font-size: 0.95rem; background: var(--light);
            outline: none; transition: var(--transition); color: var(--dark);
        }
        
        /* Select Dropdown specifics */
        select.input-field { appearance: none; -webkit-appearance: none; cursor: pointer; }
        .select-arrow {
            position: absolute; right: 15px; top: 50%; transform: translateY(-50%);
            color: var(--gray); pointer-events: none; font-size: 1.2rem;
        }

        .input-field:focus { border-color: var(--primary); background: var(--white); box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.15); }
        .input-wrapper:focus-within i.icon-main { color: var(--primary); }

        /* --- BUTTONS --- */
        .btn {
            width: 100%; padding: 14px; border-radius: 12px; font-weight: 600; font-size: 1rem;
            cursor: pointer; transition: var(--transition); border: none;
            display: flex; align-items: center; justify-content: center; gap: 8px;
        }
        .btn-primary {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: var(--white); box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3); margin-top: 10px;
        }
        .btn-primary:hover {
            transform: translateY(-2px); box-shadow: 0 6px 20px rgba(99, 102, 241, 0.4);
        }
        
        .btn-secondary {
            background: transparent; color: var(--primary); border: 2px solid var(--border);
            margin-top: 15px;
        }
        .btn-secondary:hover {
            border-color: var(--primary); background: rgba(99, 102, 241, 0.05); transform: translateY(-2px);
        }

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

        /* --- RESPONSIVE MEDIA QUERIES --- */
        @media (max-width: 600px) {
            .input-grid { grid-template-columns: 1fr; gap: 20px; }
        }

        @media (max-width: 480px) {
            body {
                padding: 15px 10px;
                align-items: flex-start;
                padding-top: 4vh;
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
            .input-wrapper i.icon-main {
                left: 14px;
                font-size: 1.1rem;
            }
            .btn {
                padding: 12px;
                font-size: 0.95rem;
            }
        }
    </style>
</head>
<body>

    <div class="auth-wrapper">
        <div class="auth-card" id="registerCard">
            
            <div class="auth-logo">
                <i class='bx bxs-user-plus'></i>
            </div>
            
            <h1 class="auth-title">Join NumSolve</h1>
            <p class="auth-subtitle">Create your academic profile</p>

            <%-- Error Messages --%>
            <% if(request.getParameter("error") != null) { %>
                <div class="alert alert-error">
                    <i class='bx bxs-error-circle'></i> 
                    <span><%= request.getParameter("error") %></span>
                </div>
            <% } %>

            <form action="<%= request.getContextPath() %>/auth" method="post" id="registerForm">
                <input type="hidden" name="action" value="register">
                
                <div class="input-grid">
                    <div class="input-group">
                        <label>Username</label>
                        <div class="input-wrapper">
                            <i class='bx bx-id-card icon-main'></i>
                            <input type="text" name="username" class="input-field" placeholder="Create an ID" required autocomplete="off">
                        </div>
                    </div>
                    
                    <div class="input-group">
                        <label>Full Name</label>
                        <div class="input-wrapper">
                            <i class='bx bx-user icon-main'></i>
                            <input type="text" name="fullName" class="input-field" placeholder="John Doe" required>
                        </div>
                    </div>
                </div>

                <div class="input-group">
                    <label>Email Address</label>
                    <div class="input-wrapper">
                        <i class='bx bx-envelope icon-main'></i>
                        <input type="email" name="email" class="input-field" placeholder="name@school.edu" required>
                    </div>
                </div>

                <div class="input-group">
                    <label>Password</label>
                    <div class="input-wrapper">
                        <i class='bx bx-lock-alt icon-main'></i>
                        <input type="password" name="password" class="input-field" placeholder="Min 8 characters" minlength="8" required>
                    </div>
                </div>

                <div class="input-group">
                    <label>Account Type</label>
                    <div class="input-wrapper">
                        <i class='bx bx-briefcase-alt-2 icon-main'></i>
                        <select name="role" class="input-field" required>
                            <option value="" disabled selected>Select your role</option>
                            <option value="R003">Student</option>
                            <option value="R002">Educator</option>
                        </select>
                        <i class='bx bx-chevron-down select-arrow'></i>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary" id="submitBtn">
                    <div class="spinner" id="btnSpinner"></div>
                    <span id="btnText">Register Now</span> <i class='bx bx-right-arrow-alt' id="btnIcon"></i>
                </button>
                
                <button type="button" class="btn btn-secondary" onclick="location.href='<%= request.getContextPath() %>/login.jsp'">
                    Back to Login
                </button>
            </form>
            
        </div>
    </div>

    <script>
        // Safe Mobile Form Submission Animation Architecture
        const registerForm = document.getElementById('registerForm');
        const registerCard = document.getElementById('registerCard');
        const submitBtn = document.getElementById('submitBtn');
        const btnText = document.getElementById('btnText');
        const btnIcon = document.getElementById('btnIcon');
        const btnSpinner = document.getElementById('btnSpinner');
        
        let isAnimating = false;

        registerForm.addEventListener('submit', function(e) {
            if (!isAnimating) {
                e.preventDefault(); // Stop initial context break
                isAnimating = true;
                
                // Trigger button loading indicator UI element layout updates
                btnText.textContent = "Creating Account...";
                btnIcon.style.display = "none";
                btnSpinner.style.display = "block";
                submitBtn.style.pointerEvents = "none"; 
                
                // Execute layout exit animation smoothly
                setTimeout(() => {
                    registerCard.classList.add('success-animate');
                    
                    // Fire natural submission within clean timeframe anchor limits
                    setTimeout(() => {
                        registerForm.submit();
                    }, 250); 
                }, 400); 
            }
        });
    </script>
</body>
</html>