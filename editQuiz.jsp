<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NumSolve | Edit Mission</title>
    
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

        body { 
            font-family: 'Poppins', sans-serif; 
            background-color: #F4F7FE; 
            color: var(--text-dark); 
            margin: 0; 
            padding: 40px 20px; 
            display: flex;
            justify-content: center;
        }

        .container { 
            width: 100%; 
            max-width: 900px; 
            animation: fadeInUp 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }

        @keyframes fadeInUp { 
            from { opacity: 0; transform: translateY(30px); } 
            to { opacity: 1; transform: translateY(0); } 
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

        select {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%234A5568'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 20px center;
            background-size: 16px;
            padding-right: 45px;
        }

        .file-hint { font-size: 0.85rem; color: var(--text-muted); margin-bottom: 8px; font-weight: 500; }

        /* --- QUESTION BLOCKS --- */
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

        /* --- OPTIONS GRID --- */
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

        /* --- BUTTONS --- */
        .btn { 
            display: inline-flex; 
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 14px 28px; 
            font-weight: 700; 
            border: none; 
            border-radius: 14px; 
            cursor: pointer; 
            text-decoration: none; 
            font-size: 1rem;
            transition: all 0.3s ease; 
            box-sizing: border-box; 
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

        .action-button-group { display: flex; gap: 15px; margin-top: 10px; width: 100%; }
        .action-button-group .btn { flex: 1; }

        .btn-submit { 
            background: var(--gradient-purple); 
            color: var(--white); 
            box-shadow: 0 8px 20px rgba(124, 92, 255, 0.25); 
        }
        .btn-submit:hover { 
            transform: translateY(-2px); 
            box-shadow: 0 12px 25px rgba(124, 92, 255, 0.35); 
        }

        .btn-cancel { 
            background: var(--white); 
            color: var(--text-dark); 
            border: 1.5px solid #E2E8F0; 
        }
        .btn-cancel:hover { 
            background: #F4F7FE; 
            border-color: var(--text-muted); 
            transform: translateY(-2px);
        }

        .flex-row { display: flex; gap: 20px; } 
        .flex-row > div { flex: 1; }

        @media (max-width: 768px) {
            .options-grid, .flex-row { grid-template-columns: 1fr; flex-direction: column; gap: 0; }
            .action-button-group { flex-direction: column; }
        }
    </style>
</head>
<body>

<div class="container">
    <h1 class="header-title"><i class='bx bxs-edit'></i> Edit Mission</h1>

    <form action="UpdateQuizServlet" method="POST" enctype="multipart/form-data">
        
        <input type="hidden" name="quizId" value="${quiz.quizId}">
        <input type="hidden" name="view" value="${viewContext}">
        <input type="hidden" name="classId" value="${classId}">
        <input type="hidden" name="existingPhotoPath" value="${quiz.photoPath}">
        
        <div class="card">
            <h3><i class='bx bx-detail'></i> Mission Details</h3>
            
            <div class="form-group">
                <label>Update Quiz Cover Image</label>
                <c:choose>
                    <c:when test="${not empty quiz.photoPath}">
                        <div class="file-hint">Current image loaded. Leave this blank to keep it.</div>
                    </c:when>
                    <c:otherwise>
                        <div class="file-hint">No image currently uploaded. (Optional)</div>
                    </c:otherwise>
                </c:choose>
                <input type="file" name="quizCover" accept="image/png, image/jpeg, image/jpg">
            </div>

            <div class="form-group">
                <label>Quiz Title</label>
                <input type="text" name="quizTitle" value="${quiz.quizTitle}" required>
            </div>
            
            <div class="form-group">
                <label>Description</label>
                <textarea name="quizDescription" rows="3">${quiz.quizDescription}</textarea>
            </div>

            <div class="flex-row">
                <div class="form-group">
                    <label>Time Limit (Minutes)</label>
                    <input type="number" name="timeLimit" value="${quiz.timeLimit}" required>
                </div>
                <div class="form-group">
                    <label>Total Marks</label>
                    <input type="number" name="totalMarks" value="${quiz.totalMarks}" required>
                </div>
            </div>

            <div class="flex-row">
                <div class="form-group">
                    <label>Quiz Type</label>
                    <select name="quizType" id="quizType" onchange="toggleClassId()">
                        <option value="Public" ${quiz.quizType == 'Public' ? 'selected' : ''}>Public (Global Platform)</option>
                        <option value="Private" ${quiz.quizType == 'Private' ? 'selected' : ''}>Private (For a specific Class)</option>
                    </select>
                </div>
                <div class="form-group" id="classIdGroup" style="display: ${quiz.quizType == 'Private' ? 'block' : 'none'};">
                    <label>Class ID</label>
                    <input type="number" name="classIdInput" value="${quiz.classId}">
                </div>
            </div>
        </div>

        <div id="questionsContainer">
            <c:forEach var="q" items="${questions}" varStatus="qLoop">
                <div class="question-block" id="qBlock_${qLoop.count}">
                    <div class="question-number">Question ${qLoop.count}</div>
                    
                    <div class="form-group" style="margin-top: 10px;">
                        <label>Question Text</label>
                        <input type="text" name="questionText_${qLoop.count}" value="${q.questionText}" required>
                    </div>

                    <div class="flex-row">
                        <div class="form-group">
                            <label>Points</label>
                            <input type="number" name="points_${qLoop.count}" value="${q.points}" required>
                        </div>
                        <div class="form-group">
                            <label>Explanation</label>
                            <input type="text" name="explanation_${qLoop.count}" value="${q.explanation}">
                        </div>
                    </div>

                    <label style="margin-top: 15px;">Answer Options</label>
                    <div class="options-grid">
                        <c:forEach var="opt" items="${q.options}" varStatus="optLoop">
                            <div class="option-item">
                                <input type="radio" name="correctOption_${qLoop.count}" value="${optLoop.count}" ${opt.correct ? 'checked' : ''} required>
                                <input type="text" name="optionText_${qLoop.count}_${optLoop.count}" value="${opt.optionText}" required placeholder="Option text...">
                            </div>
                        </c:forEach>
                    </div>
                </div>
            </c:forEach>
        </div>

        <input type="hidden" name="questionCount" id="questionCount" value="${questions.size()}">

        <button type="button" class="btn btn-add" onclick="addQuestion()">
            <i class='bx bx-plus-circle'></i> Add Another Question
        </button>
        
        <div class="action-button-group">
            <a href="educatorQuizzes?view=${viewContext}${not empty classId ? '&classId='.concat(classId) : ''}" class="btn btn-cancel">
                <i class='bx bx-x'></i> Cancel
            </a>
            <button type="submit" class="btn btn-submit">
                <i class='bx bx-save'></i> Save Changes
            </button>
        </div>

    </form>
</div>

<script>
    let qCount = ${not empty questions ? questions.size() : 0};

    function toggleClassId() {
        const type = document.getElementById("quizType").value;
        document.getElementById("classIdGroup").style.display = (type === "Private") ? "block" : "none";
    }

    function addQuestion() {
        qCount++;
        document.getElementById("questionCount").value = qCount;

        const questionHTML = `
            <div class="question-block" id="qBlock_` + qCount + `">
                <div class="question-number">Question ` + qCount + `</div>
                <div class="form-group" style="margin-top: 10px;">
                    <label>Question Text</label>
                    <input type="text" name="questionText_` + qCount + `" placeholder="Enter new question..." required>
                </div>
                <div class="flex-row">
                    <div class="form-group">
                        <label>Points</label>
                        <input type="number" name="points_` + qCount + `" value="10" required>
                    </div>
                    <div class="form-group">
                        <label>Explanation</label>
                        <input type="text" name="explanation_` + qCount + `" placeholder="Optional reasoning...">
                    </div>
                </div>
                <label style="margin-top: 15px;">Answer Options</label>
                <div class="options-grid">
                    <div class="option-item"><input type="radio" name="correctOption_` + qCount + `" value="1" required checked><input type="text" name="optionText_` + qCount + `_1" placeholder="Option 1" required></div>
                    <div class="option-item"><input type="radio" name="correctOption_` + qCount + `" value="2"><input type="text" name="optionText_` + qCount + `_2" placeholder="Option 2" required></div>
                    <div class="option-item"><input type="radio" name="correctOption_` + qCount + `" value="3"><input type="text" name="optionText_` + qCount + `_3" placeholder="Option 3" required></div>
                    <div class="option-item"><input type="radio" name="correctOption_` + qCount + `" value="4"><input type="text" name="optionText_` + qCount + `_4" placeholder="Option 4" required></div>
                </div>
            </div>`;
        
        document.getElementById("questionsContainer").insertAdjacentHTML('beforeend', questionHTML);
        document.getElementById("qBlock_" + qCount).scrollIntoView({ behavior: "smooth", block: "center" });
    }
</script>

</body>
</html>