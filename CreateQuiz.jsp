<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="model.User" %>
<%@ page import="dao.ClassDAO" %>
<%@ page import="model.Classroom" %>
<%@ page import="java.util.List" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Fetch user for navigation role checking
    User u = (User) session.getAttribute("user");
    if (u == null || !"R002".equals(u.getRoleId())) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // Fetch the educator's classes for the dropdown
    ClassDAO classDAO = new ClassDAO();
    List<Classroom> educatorClasses = classDAO.getClassesByEducator(u.getUserId());
    
    // Grab classId from URL if they came directly from a specific section
    String urlClassId = request.getParameter("classId");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NumSolve | Create a Mission</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <style>
        /* --- GLOBAL MATERIALS-STYLE VARIABLES --- */
        :root {
            --primary-purple: #7C5CFF;
            --gradient-purple: linear-gradient(135deg, #9D80FF, #6B46E5);
            --bg-glass: rgba(255, 255, 255, 0.85);
            --border-glass: rgba(255, 255, 255, 0.6);
            --text-dark: #2D3748;
            --text-muted: #718096;
            --white: #ffffff;
            --radius: 24px;
            --danger: #ef4444;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background-color: #F4F7FE; 
            color: var(--text-dark); 
            min-height: 100vh; 
            display: flex; 
            flex-direction: column; 
            align-items: center;
        }

        /* --- MAIN CONTAINER --- */
        .main-content { padding: 40px 20px; flex: 1; width: 100%; display: flex; justify-content: center; }
        .container { width: 100%; max-width: 900px; animation: fadeInUp 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards; }

        @keyframes fadeInUp { 
            from { opacity: 0; transform: translateY(30px); } 
            to { opacity: 1; transform: translateY(0); } 
        }

        /* --- BACK BUTTON & HEADER --- */
        .header-actions { display: flex; justify-content: flex-start; align-items: center; margin-bottom: 25px; }
        .btn-back {
            display: inline-flex; align-items: center; gap: 8px;
            background: var(--white); color: var(--text-dark); padding: 10px 18px;
            border-radius: 12px; text-decoration: none; font-weight: 600; font-size: 0.95rem;
            border: 1.5px solid #E2E8F0;
            transition: all 0.3s ease;
        }
        .btn-back:hover { 
            background: #F4F7FE; 
            border-color: var(--text-muted); 
            transform: translateY(-2px);
        }

        .header-title { 
            text-align: center; 
            font-weight: 800; 
            font-size: 2.2rem; 
            color: var(--text-dark); 
            margin-bottom: 35px; 
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            letter-spacing: -0.5px;
        }
        .header-title i { color: var(--primary-purple); }

        /* --- GLASSMORPHISM CARD --- */
        .card { 
            background: var(--bg-glass); 
            backdrop-filter: blur(12px); 
            -webkit-backdrop-filter: blur(12px); 
            border-radius: var(--radius); 
            padding: 35px; 
            box-shadow: 0 15px 35px rgba(141, 110, 255, 0.12); 
            margin-bottom: 30px; 
            border: 1px solid var(--border-glass); 
        }
        .card h3 {
            font-size: 1.25rem;
            font-weight: 700;
            margin-top: 0;
            margin-bottom: 25px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .card h3 i { color: var(--primary-purple); font-size: 1.4rem; }

        /* --- FORM INPUTS --- */
        .form-group { margin-bottom: 20px; }
        label { display: block; font-weight: 600; margin-bottom: 8px; color: var(--text-dark); font-size: 0.95rem; }
        
        input[type="text"], input[type="number"], select, textarea, input[type="file"] { 
            width: 100%; 
            padding: 14px 20px; 
            border: 1.5px solid #E2E8F0; 
            border-radius: 12px; 
            font-family: 'Poppins', sans-serif; 
            font-size: 0.95rem;
            font-weight: 500;
            background: rgba(255, 255, 255, 0.7); 
            color: var(--text-dark); 
            transition: all 0.3s ease; 
            box-sizing: border-box; 
            outline: none;
        }
        input:focus, select:focus, textarea:focus { 
            background: var(--white); 
            border-color: var(--primary-purple); 
            box-shadow: 0 0 0 3px rgba(124, 92, 255, 0.15); 
        }

        /* Locked input styling */
        input[readonly] { 
            background: rgba(226, 232, 240, 0.5); 
            color: var(--text-muted); 
            cursor: not-allowed; 
            border-color: #E2E8F0; 
        }

        select {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%234A5568'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 20px center;
            background-size: 16px;
            padding-right: 45px;
        }

        .flex-row { display: flex; gap: 20px; }
        .flex-row > div { flex: 1; }

        /* --- DYNAMIC QUESTION BLOCKS --- */
        .question-block { 
            background: rgba(255, 255, 255, 0.6); 
            border: 1px solid var(--border-glass); 
            border-radius: 20px; 
            padding: 35px 30px 25px 30px; 
            margin-bottom: 25px; 
            position: relative; 
            transition: all 0.3s ease;
        }
        .question-block:hover { 
            background: rgba(255, 255, 255, 0.9); 
            box-shadow: 0 10px 25px rgba(141, 110, 255, 0.08); 
            border-color: rgba(124, 92, 255, 0.3); 
        }
        .question-number { 
            position: absolute; 
            top: -14px; 
            left: 25px; 
            background: var(--gradient-purple); 
            color: white; 
            padding: 6px 20px; 
            border-radius: 30px; 
            font-weight: 700; 
            font-size: 0.85rem; 
            box-shadow: 0 6px 15px rgba(124, 92, 255, 0.25); 
        }

        /* DELETE QUESTION BUTTON */
        .btn-delete-q {
            position: absolute; top: 15px; right: 20px; background: rgba(239, 68, 68, 0.1); color: var(--danger);
            border: none; border-radius: 10px; width: 36px; height: 36px; cursor: pointer;
            display: flex; align-items: center; justify-content: center; font-size: 1.2rem; transition: all 0.2s ease;
        }
        .btn-delete-q:hover { background: var(--danger); color: white; transform: scale(1.05); }

        /* Options Grid */
        .options-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-top: 15px; }
        .option-item { 
            display: flex; 
            align-items: center; 
            background: var(--white); 
            padding: 12px 16px; 
            border-radius: 12px; 
            border: 1.5px solid #E2E8F0; 
            transition: all 0.2s ease;
        }
        .option-item:focus-within {
            border-color: var(--primary-purple);
            box-shadow: 0 0 0 3px rgba(124, 92, 255, 0.1);
        }
        .option-item input[type="radio"] { 
            margin-right: 12px; 
            transform: scale(1.3); 
            accent-color: var(--primary-purple); 
            cursor: pointer;
        }
        .option-item input[type="text"] { 
            border: none; 
            background: transparent; 
            padding: 0; 
            width: 100%;
            font-size: 0.95rem;
            border-radius: 0;
            box-shadow: none;
        }
        .option-item input[type="text"]:focus { box-shadow: none; border-color: transparent; }

        /* --- ACTION BUTTONS --- */
        .btn { 
            display: inline-flex; align-items: center; justify-content: center; gap: 8px; 
            padding: 14px 28px; font-weight: 700; border: none; border-radius: 14px; 
            cursor: pointer; text-decoration: none; font-size: 1rem;
            transition: all 0.3s ease; box-sizing: border-box; 
        }
        .btn-add { 
            background: rgba(124, 92, 255, 0.08); 
            color: var(--primary-purple); 
            width: 100%; 
            border: 2px dashed rgba(124, 92, 255, 0.3); 
            margin-bottom: 25px;
        }
        .btn-add:hover { 
            background: rgba(124, 92, 255, 0.15); 
            border-color: var(--primary-purple);
            transform: translateY(-2px);
        }

        .btn-submit { 
            background: var(--gradient-purple); 
            color: var(--white); 
            width: 100%;
            font-size: 1.1rem;
            box-shadow: 0 8px 20px rgba(124, 92, 255, 0.25); 
        }
        .btn-submit:hover { 
            transform: translateY(-3px); 
            box-shadow: 0 12px 25px rgba(124, 92, 255, 0.35); 
        }

        @media (max-width: 768px) {
            .options-grid, .flex-row { grid-template-columns: 1fr; flex-direction: column; gap: 0; }
        }
    </style>
</head>
<body>

    <main class="main-content">
        <div class="container">
            
            <div class="header-actions">
                <% if (urlClassId != null && !urlClassId.trim().isEmpty()) { %>
                    <a href="educatorQuizzes?view=personal&classId=<%= urlClassId %>" class="btn-back">
                        <i class='bx bx-arrow-back'></i> Go Back
                    </a>
                <% } else { %>
                    <a href="educatorQuizzes?view=personal" class="btn-back">
                        <i class='bx bx-arrow-back'></i> Go Back
                    </a>
                <% } %>
            </div>

            <h1 class="header-title"><i class='bx bxs-rocket'></i> Create a Mission</h1>

            <form action="${pageContext.request.contextPath}/CreateQuizServlet" method="POST" id="quizForm" enctype="multipart/form-data">
                
                <div class="card">
                    <h3><i class='bx bx-detail'></i> Mission Details</h3>

                    <div class="flex-row">
                        <div class="form-group">
                            <label>Visibility Type</label>
                            <select name="quizType" id="quizType" onchange="toggleClassId()">
                                <option value="Private" <%= urlClassId != null ? "selected" : "" %>>Private (For a specific Class)</option>
                                <option value="Public" <%= urlClassId == null ? "selected" : "" %>>Public (Global Platform)</option>
                            </select>
                        </div>

                        <div class="form-group" id="classIdGroup" style="<%= urlClassId == null ? "display:none;" : "" %>">
                            <label>Target Class</label>
                            <select name="classId" id="classIdInput">
                                <option value="">-- Select one of your classes --</option>
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
                                        <option value="" disabled>You have not created any classes yet.</option>
                                <%  } %>
                            </select>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>Quiz Cover Image (Optional)</label>
                        <input type="file" name="quizCover" accept="image/png, image/jpeg, image/jpg" class="form-control">
                    </div>

                    <div class="form-group">
                        <label>Quiz Title</label>
                        <input type="text" name="quizTitle" placeholder="e.g., The Ultimate Algebra Challenge" required>
                    </div>

                    <div class="form-group">
                        <label>Description</label>
                        <textarea name="quizDescription" rows="3" placeholder="What is this mission about?"></textarea>
                    </div>

                    <div class="flex-row">
                        <div class="form-group">
                            <label>Time Limit (Minutes)</label>
                            <input type="number" name="timeLimit" placeholder="e.g., 30" required min="1">
                        </div>
                        <div class="form-group">
                            <label>Total Marks (Auto-calculated)</label>
                            <input type="number" name="totalMarks" id="totalMarks" value="0" readonly>
                        </div>
                    </div>
                </div>

                <div id="questionsContainer"></div>

                <input type="hidden" name="questionCount" id="questionCount" value="0">

                <button type="button" class="btn btn-add" onclick="addQuestion()">
                    <i class='bx bx-plus-circle'></i> Add New Question
                </button>
                <button type="submit" class="btn btn-submit">
                    <i class='bx bxs-send'></i> Launch Mission!
                </button>

            </form>
        </div>
    </main>

    <script>
        let qCount = 0;

        function calculateTotalMarks() {
            let total = 0;
            const pointInputs = document.querySelectorAll('.point-input');
            pointInputs.forEach(input => {
                const val = parseInt(input.value);
                if (!isNaN(val)) {
                    total += val;
                }
            });
            document.getElementById("totalMarks").value = total;
        }

        function addQuestion() {
            qCount++;
            document.getElementById("questionCount").value = qCount;

            const questionHTML = `
                <div class="question-block" id="qBlock_` + qCount + `">
                    <div class="question-number">Question ` + qCount + `</div>
                    
                    <button type="button" class="btn-delete-q" onclick="deleteQuestion(this)" title="Delete Question">
                        <i class='bx bx-trash'></i>
                    </button>
                    
                    <div class="form-group" style="margin-top: 10px;">
                        <label>Question Text</label>
                        <input type="text" name="questionText_` + qCount + `" placeholder="Enter your question here..." required>
                    </div>

                    <div class="flex-row">
                        <div class="form-group">
                            <label>Points for this question</label>
                            <input type="number" class="point-input" name="points_` + qCount + `" value="10" required min="1" onchange="calculateTotalMarks()" onkeyup="calculateTotalMarks()">
                        </div>
                        <div class="form-group">
                            <label>Explanation (Shown after quiz)</label>
                            <input type="text" name="explanation_` + qCount + `" placeholder="Optional reasoning...">
                        </div>
                    </div>

                    <label style="margin-top: 15px;">Answer Options</label>
                    <div class="options-grid">
                        <div class="option-item">
                            <input type="radio" name="correctOption_` + qCount + `" value="1" required checked>
                            <input type="text" name="optionText_` + qCount + `_1" placeholder="Option A" required>
                        </div>
                        <div class="option-item">
                            <input type="radio" name="correctOption_` + qCount + `" value="2">
                            <input type="text" name="optionText_` + qCount + `_2" placeholder="Option B" required>
                        </div>
                        <div class="option-item">
                            <input type="radio" name="correctOption_` + qCount + `" value="3">
                            <input type="text" name="optionText_` + qCount + `_3" placeholder="Option C" required>
                        </div>
                        <div class="option-item">
                            <input type="radio" name="correctOption_` + qCount + `" value="4">
                            <input type="text" name="optionText_` + qCount + `_4" placeholder="Option D" required>
                        </div>
                    </div>
                </div>
            `;

            document.getElementById("questionsContainer").insertAdjacentHTML('beforeend', questionHTML);
            calculateTotalMarks();
            document.getElementById("qBlock_" + qCount).scrollIntoView({ behavior: "smooth", block: "center" });
        }

        function deleteQuestion(btn) {
            if (document.querySelectorAll('.question-block').length <= 1) {
                alert("You must have at least one question in your mission!");
                return;
            }

            const block = btn.closest('.question-block');
            block.remove();

            reindexQuestions();
            calculateTotalMarks();
        }

        function reindexQuestions() {
            const blocks = document.querySelectorAll('.question-block');
            qCount = blocks.length;
            document.getElementById("questionCount").value = qCount;

            blocks.forEach((block, index) => {
                const newNum = index + 1;
                
                block.id = "qBlock_" + newNum;
                block.querySelector('.question-number').innerText = "Question " + newNum;

                block.querySelector('input[name^="questionText_"]').name = "questionText_" + newNum;
                block.querySelector('input[name^="points_"]').name = "points_" + newNum;
                block.querySelector('input[name^="explanation_"]').name = "explanation_" + newNum;

                const radios = block.querySelectorAll('input[type="radio"]');
                radios.forEach(radio => radio.name = "correctOption_" + newNum);

                const optionInputs = block.querySelectorAll('input[name^="optionText_"]');
                optionInputs.forEach((optInput, optIndex) => {
                    optInput.name = "optionText_" + newNum + "_" + (optIndex + 1);
                });
            });
        }
        
        function toggleClassId() {
            const type = document.getElementById("quizType").value;
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

        window.onload = function() {
            toggleClassId();
            addQuestion(); 
        };
        
        document.getElementById('quizForm').onsubmit = function(e) {
            const questions = document.querySelectorAll('.question-block');
            if (questions.length === 0) {
                e.preventDefault();
                alert("You must add at least one question before publishing the quiz.");
            }
        };
    </script>
</body>
</html>