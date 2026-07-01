<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
    // Prevent the user from hitting the "Back" button after submitting the quiz
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${quiz.quizTitle} – NumSolve</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        :root {
            --student: #3b82f6;         
            --student-hover: #2563eb;   
            --dark: #2c3e50;
            --light: #f4f6f9;
            --white: #ffffff;
            --gray: #858796;
            --danger: #ef4444;
            --border: #e2e8f0;
            --shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        body { font-family: 'Poppins', sans-serif; background-color: var(--light); color: var(--dark); margin: 0; padding: 0; padding-bottom: 80px; }
        
        /* --- STICKY HEADER WITH TIMER --- */
        .game-header {
            position: sticky; top: 0; background: var(--white); padding: 15px 30px;
            display: flex; justify-content: space-between; align-items: center;
            box-shadow: var(--shadow); z-index: 100; border-bottom: 4px solid var(--student);
        }
        .quiz-info h1 { font-size: 1.5rem; margin: 0; color: var(--dark); }
        .quiz-info p { margin: 0; font-size: 0.9rem; color: var(--gray); }
        
        .timer-box {
            background: var(--light); border: 2px solid var(--student); padding: 10px 20px;
            border-radius: 30px; font-size: 1.5rem; font-weight: 700; color: var(--student);
            display: flex; align-items: center; gap: 10px; transition: all 0.3s;
        }
        .timer-warning { border-color: var(--danger); color: var(--danger); animation: pulse 1s infinite; }
        @keyframes pulse { 0% { transform: scale(1); } 50% { transform: scale(1.05); } 100% { transform: scale(1); } }

        /* --- QUESTION ARENA --- */
        .container { max-width: 900px; margin: 40px auto; padding: 0 20px; }
        
        .question-card {
            background: var(--white); border-radius: 12px; padding: 30px;
            margin-bottom: 30px; box-shadow: var(--shadow); border: 1px solid var(--border);
        }
        
        .question-header { display: flex; justify-content: space-between; margin-bottom: 20px; font-weight: 600; color: var(--gray); border-bottom: 2px dashed var(--border); padding-bottom: 10px; }
        .question-text { font-size: 1.2rem; font-weight: 500; color: var(--dark); margin-bottom: 25px; line-height: 1.6; }
        
        .options-grid { display: grid; grid-template-columns: 1fr; gap: 15px; }
        
        /* Custom Radio Button Styling */
        .option-label {
            display: flex; align-items: center; padding: 15px 20px; background: var(--light);
            border: 2px solid var(--border); border-radius: 8px; cursor: pointer;
            transition: all 0.2s; font-size: 1.05rem; font-weight: 500;
        }
        .option-label:hover { border-color: var(--student); background: #eff6ff; }
        
        /* Hide default radio, style the container when checked */
        .option-label input[type="radio"] { display: none; }
        .option-label input[type="radio"]:checked + .option-text { color: var(--student); font-weight: 600; }
        
        /* The CSS trick to highlight the parent label when the hidden radio is checked */
        .options-grid div { position: relative; }
        input[type="radio"]:checked ~ label { border-color: var(--student); background: #dbeafe; box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2); }

        .btn-submit {
            display: block; width: 100%; background: var(--student); color: var(--white);
            padding: 15px; border-radius: 10px; border: none; font-size: 1.2rem; font-weight: 600;
            cursor: pointer; transition: all 0.3s; box-shadow: 0 4px 10px rgba(59, 130, 246, 0.3);
        }
        .btn-submit:hover { background: var(--student-hover); transform: translateY(-3px); }
    </style>
</head>
<body>

    <div class="game-header">
        <div class="quiz-info">
            <h1><i class='bx bx-joystick'></i> ${quiz.quizTitle}</h1>
            <p>Total Points: ${quiz.totalMarks} | Time Limit: ${quiz.timeLimit} Mins</p>
        </div>
        <div class="timer-box" id="timerDisplay">
            <i class='bx bx-stopwatch'></i> <span id="timeText">--:--</span>
        </div>
    </div>

    <div class="container">
        <form action="SubmitQuizServlet" method="POST" id="quizForm">
            <input type="hidden" name="quizId" value="${quiz.quizId}">
            
            <input type="hidden" name="classId" value="${classId}">
            
            <c:forEach var="q" items="${questions}" varStatus="loop">
                <div class="question-card">
                    <div class="question-header">
                        <span>Question ${loop.count} of ${questions.size()}</span>
                        <span>⭐ ${q.points} Pts</span>
                    </div>
                    
                    <div class="question-text">${q.questionText}</div>
                    
                    <div class="options-grid">
                        <c:forEach var="opt" items="${q.options}">
                            <div>
                                <input type="radio" id="opt_${opt.optionId}" name="q_${q.questionId}" value="${opt.optionId}">
                                <label for="opt_${opt.optionId}" class="option-label">
                                    <span class="option-text">${opt.optionText}</span>
                                </label>
                            </div>
                        </c:forEach>
                    </div>
                </div>
            </c:forEach>
            
            <button type="submit" class="btn-submit" onclick="return confirm('Are you sure you want to submit your mission?');">
                <i class='bx bx-check-shield'></i> SUBMIT MISSION
            </button>
        </form>
    </div>

    <script>
        // Grab the time limit from the database (in minutes) and convert to seconds
        let timeInSeconds = ${quiz.timeLimit} * 60;
        const timerDisplay = document.getElementById('timerDisplay');
        const timeText = document.getElementById('timeText');
        const quizForm = document.getElementById('quizForm');

        function updateTimer() {
            let minutes = Math.floor(timeInSeconds / 60);
            let seconds = timeInSeconds % 60;
            
            // Format to always show two digits (e.g., 09:05)
            seconds = seconds < 10 ? '0' + seconds : seconds;
            minutes = minutes < 10 ? '0' + minutes : minutes;
            
            timeText.textContent = minutes + ":" + seconds;

            // Turn red and pulse when 1 minute is left
            if (timeInSeconds <= 60 && timeInSeconds > 0) {
                timerDisplay.classList.add('timer-warning');
            }

            // AUTO SUBMIT WHEN TIME IS UP!
            if (timeInSeconds <= 0) {
                clearInterval(timerInterval);
                timeText.textContent = "00:00";
                alert("⏳ TIME IS UP! Auto-submitting your mission now!");
                // Remove the "onsubmit" confirm so it forces the submit immediately
                quizForm.removeAttribute("onsubmit"); 
                quizForm.submit(); 
            } else {
                timeInSeconds--;
            }
        }

        // Run the timer every 1000 milliseconds (1 second)
        const timerInterval = setInterval(updateTimer, 1000);
        updateTimer(); // Call it immediately so there's no 1-second delay on page load
    </script>

</body>
</html>