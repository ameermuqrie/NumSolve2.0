<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="dao.ClassDAO, dao.MessageDAO, dao.UserDAO, model.Classroom, model.User, model.DirectMessage, java.util.*" %>
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

    try {
        if (classIdStr != null && !classIdStr.isEmpty()) {
            classId = Integer.parseInt(classIdStr);
            currentClass = classDao.getClassById(classId);
        }
    } catch (NumberFormatException e) { }

    if (currentClass == null) {
        response.sendRedirect(isEducator ? "manage_classes.jsp" : "student_classes.jsp");
        return;
    }

    // 3. Determine Chat Target & Fetch Users
    int targetUserId = 0;
    String targetUserName = "Loading...";
    List<User> enrolledStudents = classDao.getStudentsByClass(classId);
    if (enrolledStudents == null) enrolledStudents = new ArrayList<>();
    
    MessageDAO msgDao = new MessageDAO(); 
    
    // Get Educator Details
    int educatorId = currentClass.getUserId();
    User educatorUser = null;
    String educatorName = "Educator";
    try {
        educatorUser = new UserDAO().getUserById(educatorId);
        if(educatorUser != null && educatorUser.getFullName() != null) {
            educatorName = educatorUser.getFullName();
        }
    } catch (Exception e) {}

    // Build a Name Map (Needed to display who sent a message in the Group Chat)
    Map<Integer, String> userNamesMap = new HashMap<>();
    userNamesMap.put(educatorId, educatorName + " (Educator)");
    for (User s : enrolledStudents) {
        userNamesMap.put(s.getUserId(), s.getFullName() != null ? s.getFullName() : "Student");
    }
    userNamesMap.put(u.getUserId(), "You");

    // Check URL parameter for requested chat
    String sId = request.getParameter("studentId");
    if (sId != null && !sId.isEmpty()) {
        targetUserId = Integer.parseInt(sId);
    } else {
        targetUserId = -1; // Default everyone to the Class Group Chat!
    }

    // Resolve Target User Name based on ID
    if (targetUserId == -1) {
        targetUserName = "Class Group Chat";
    } else if (targetUserId == educatorId) {
        targetUserName = educatorName + " (Educator)";
    } else if (targetUserId > 0) {
        targetUserName = userNamesMap.getOrDefault(targetUserId, "Student");
    }

    // --- SMART SESSION TRICK: MARK CHAT AS READ ---
    if (targetUserId != 0) {
        session.setAttribute("read_chat_" + classId + "_" + targetUserId, true);
    }

    // 4. Fetch Active Chat History
    List<DirectMessage> chatHistory = new ArrayList<>();
    if (targetUserId == -1) {
        // Group Chat: Fetch all messages where receiver is -1
        chatHistory = msgDao.getGroupConversation(classId);
    } else if (targetUserId > 0) {
        // Private Chat: Fetch 1-on-1 messages
        chatHistory = msgDao.getConversation(classId, u.getUserId(), targetUserId);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Q&A - <%= currentClass.getClassName() %></title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    <style>
        :root {
            --primary: <%= isEducator ? "#8b5cf6" : "#3b82f6" %>;        
            --primary-hover: <%= isEducator ? "#7c3aed" : "#2563eb" %>;
            --gradient: <%= isEducator ? "linear-gradient(135deg, #7c3aed, #a855f7)" : "linear-gradient(135deg, #2563eb, #3b82f6)" %>;
            --bg: #f3f4f6;
            --white: #ffffff;
            --dark: #1e293b;
            --border: #e2e8f0;
            --msg-sent: <%= isEducator ? "#f3e8ff" : "#e0f2fe" %>;
            --msg-received: #f8fafc;
            --chat-bg: #ffffff;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        
        body { 
            background: linear-gradient(180deg, #f1f5f9 0%, #e2e8f0 100%); 
            color: var(--dark); 
            height: 100vh; 
            max-height: 100vh; 
            display: flex; 
            flex-direction: column; 
            overflow: hidden; 
            align-items: center;
        }
        
        /* --- NAV WRAPPER (MATCHES DASHBOARD HIERARCHY) --- */
        .nav-wrapper {
            width: 100%;
            max-width: 1440px;
            padding: 0 24px;
        }
        .top-nav { 
            background: var(--white); 
            padding: 14px 28px; 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            color: var(--dark); 
            box-shadow: 0 4px 20px rgba(0,0,0,0.03); 
            border-radius: 100px;
            margin-top: 20px;
            margin-bottom: 16px;
            border: 1px solid rgba(255, 255, 255, 0.8);
        }
        .nav-title {
            display: flex;
            align-items: center;
            gap: 10px;
            font-weight: 600;
            font-size: 1.1rem;
            color: #0f172a;
        }
        .nav-title i {
            color: var(--primary);
            font-size: 1.3rem;
        }
        .back-btn { 
            color: #475569; 
            text-decoration: none; 
            display: flex; 
            align-items: center; 
            gap: 6px; 
            background: #f1f5f9; 
            padding: 8px 18px; 
            border-radius: 50px; 
            font-size: 0.85rem; 
            font-weight: 500;
            transition: all 0.2s ease;
        }
        .back-btn:hover {
            background: #e2e8f0;
            color: #0f172a;
            transform: translateX(-2px);
        }

        /* --- MAIN DASHBOARD CONTAINER CANVAS --- */
        .app-container { 
            display: flex; 
            flex: 1; 
            max-width: 1440px; 
            width: calc(100% - 48px); 
            margin-bottom: 24px; 
            background: var(--white); 
            box-shadow: 0 10px 30px rgba(15, 23, 42, 0.04); 
            border-radius: 24px;
            overflow: hidden; 
            min-height: 0; 
            border: 1px solid var(--border);
        }

        /* --- SIDEBAR WORKSPACE THREADS --- */
        .sidebar { 
            width: 340px; 
            display: flex; 
            flex-direction: column; 
            border-right: 1px solid var(--border); 
            background: #fafafa; 
        }
        .sidebar-header { 
            padding: 20px 18px; 
            background: var(--white);
            border-bottom: 1px solid var(--border); 
        }
        .search-container { position: relative; width: 100%; }
        .search-container i { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); color: #94a3b8; font-size: 1.1rem; }
        .search-input { 
            width: 100%; 
            padding: 10px 16px 10px 40px; 
            border: 1px solid #e2e8f0; 
            border-radius: 12px; 
            outline: none; 
            background: #f8fafc; 
            font-size: 0.88rem; 
            transition: all 0.2s;
        }
        .search-input:focus {
            background: var(--white);
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.1);
        }
        
        .student-list { 
            flex: 1; 
            overflow-y: auto; 
            background: #fafafa; 
            padding: 10px;
        }
        .student-item { 
            display: flex; 
            align-items: center; 
            padding: 12px 14px; 
            border-radius: 16px;
            text-decoration: none; 
            color: var(--dark); 
            cursor: pointer; 
            transition: all 0.2s ease; 
            position: relative; 
            margin-bottom: 6px;
            background: var(--white);
            border: 1px solid rgba(0, 0, 0, 0.02);
        }
        .student-item:hover { 
            background: #f1f5f9; 
            transform: translateY(-1px);
        }
        .student-item.active { 
            background: var(--gradient); 
            color: var(--white) !important;
            box-shadow: 0 4px 12px rgba(139, 92, 246, 0.15);
        }
        
        .avatar { 
            width: 42px; 
            height: 42px; 
            min-width: 42px; 
            border-radius: 50%; 
            background: #f1f5f9; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            font-size: 1rem; 
            color: #64748b; 
            margin-right: 14px; 
            font-weight: 600; 
        }
        .student-item.active .avatar { 
            background: rgba(255, 255, 255, 0.2); 
            color: var(--white); 
        }
        
        .student-info { flex: 1; overflow: hidden; }
        .student-name { font-weight: 500; font-size: 0.92rem; color: #334155; }
        .student-item.active .student-name { color: var(--white); }
        
        .noti-dot { width: 10px; height: 10px; background-color: #ef4444; border-radius: 50%; margin-left: 10px; }
        .last-msg-preview { font-size: 0.78rem; color: #64748b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-top: 2px; }
        .student-item.active .last-msg-preview { color: rgba(255, 255, 255, 0.8); }
        .last-msg-preview.unread { color: var(--dark); font-weight: 600; }

        /* --- CHAT AREA CORE WINDOW --- */
        .chat-main { flex: 1; display: flex; flex-direction: column; background: var(--chat-bg); position: relative; min-height: 0; min-width: 0; }
        .chat-header { 
            padding: 16px 24px; 
            background: var(--white); 
            border-bottom: 1px solid var(--border); 
            display: flex; 
            align-items: center; 
        }
        .chat-header .avatar { 
            width: 40px; 
            height: 40px; 
            min-width: 40px; 
            background: #e2e8f0; 
            margin-right: 12px; 
            border-radius: 50%;
        }
        .chat-header h3 { font-size: 1rem; font-weight: 600; color: #0f172a; }

        /* --- CHAT TIMELINE MESSAGES --- */
        .chat-messages { flex: 1; padding: 24px; overflow-y: auto; display: flex; flex-direction: column; gap: 14px; background-color: #f8fafc; }
        .msg-wrapper { display: flex; flex-direction: column; max-width: 65%; }
        .msg-wrapper.sent { align-self: flex-end; align-items: flex-end; }
        .msg-wrapper.received { align-self: flex-start; align-items: flex-start; }
        
        .msg-sender-name { font-size: 0.75rem; color: #64748b; margin-bottom: 4px; margin-left: 4px; font-weight: 500; }
        
        .msg { 
            padding: 10px 16px; 
            border-radius: 18px; 
            font-size: 0.9rem; 
            line-height: 1.45; 
            position: relative; 
            box-shadow: 0 1px 3px rgba(0,0,0,0.02); 
            word-wrap: break-word; 
            width: 100%; 
        }
        .msg-wrapper.sent .msg { background: var(--gradient); color: var(--white); border-top-right-radius: 2px; }
        .msg-wrapper.received .msg { background: var(--white); color: var(--dark); border-top-left-radius: 2px; border: 1px solid var(--border); }
        .msg-time { font-size: 0.65rem; color: #94a3b8; float: right; margin-left: 15px; margin-top: 5px; }
        .msg-wrapper.sent .msg-time { color: rgba(255, 255, 255, 0.7); }

        /* --- ACTIONS INPUT BAR --- */
        .chat-input-area { padding: 16px 24px; background: var(--white); border-top: 1px solid var(--border); display: flex; gap: 12px; align-items: center; }
        .chat-input { 
            flex: 1; 
            padding: 12px 20px; 
            border: 1px solid #e2e8f0; 
            border-radius: 100px; 
            outline: none; 
            font-size: 0.9rem; 
            background: #f8fafc;
            transition: all 0.2s;
        }
        .chat-input:focus {
            background: var(--white);
            border-color: var(--primary);
        }
        .btn-send { 
            background: var(--gradient); 
            color: white; 
            border: none; 
            width: 42px; 
            height: 42px; 
            border-radius: 50%; 
            cursor: pointer; 
            font-size: 1.2rem; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            transition: all 0.2s ease; 
        }
        .btn-send:hover { transform: scale(1.05); opacity: 0.95; }
    </style>
</head>
<body>

    <div class="nav-wrapper">
        <nav class="top-nav">
            <div class="nav-title">
                <i class='bx bx-book-reader'></i> 
                <span><%= currentClass.getClassName() %> Q&A</span>
            </div>
            <a href="class_dashboard.jsp?classId=<%= classId %>" class="back-btn">
                <i class='bx bx-left-arrow-alt'></i> Workspace Hub
            </a>
        </nav>
    </div>

    <div class="app-container">
        
        <div class="sidebar">
            <div class="sidebar-header">
                <div class="search-container">
                    <i class='bx bx-search'></i>
                    <input type="text" id="searchInput" class="search-input" placeholder="Search people..." onkeyup="filterStudents()">
                </div>
            </div>
            
            <div class="student-list" id="studentList">
                
                <a href="class_qa.jsp?classId=<%= classId %>&studentId=-1" class="student-item <%= (targetUserId == -1) ? "active" : "" %>" style="<%= (targetUserId == -1) ? "" : "background: #f1f5f9;" %>">
                    <div class="avatar" style="background: <%= (targetUserId == -1) ? "rgba(255,255,255,0.2)" : "var(--primary)" %>; color: white;"><i class='bx bx-group'></i></div>
                    <div class="student-info">
                        <div class="student-name" style="<%= (targetUserId == -1) ? "" : "color: var(--primary); font-weight: 600;" %>">Class Group Chat</div>
                        <div class="last-msg-preview">Public assignments & announcements</div>
                    </div>
                </a>

                <% if (isStudent) { 
                    List<DirectMessage> edChat = msgDao.getConversation(classId, u.getUserId(), educatorId);
                    boolean unreadEd = false;
                    String edPreview = "Private chat with educator...";
                    if (!edChat.isEmpty()) {
                        DirectMessage lastMsg = edChat.get(edChat.size() - 1);
                        edPreview = lastMsg.getMessageBody();
                        if (lastMsg.getSenderId() == educatorId) {
                            Boolean isRead = (Boolean) session.getAttribute("read_chat_" + classId + "_" + educatorId);
                            if (isRead == null || !isRead) unreadEd = true;
                        }
                    }
                %>
                    <a href="class_qa.jsp?classId=<%= classId %>&studentId=<%= educatorId %>" class="student-item <%= (targetUserId == educatorId) ? "active" : "" %>">
                        <div class="avatar" style="background: <%= (targetUserId == educatorId) ? "rgba(255,255,255,0.2)" : "#10b981" %>; color: white;"><i class='bx bxs-graduation'></i></div>
                        <div class="student-info">
                            <div class="student-name" style="<%= (targetUserId == educatorId) ? "" : "color: #10b981; font-weight: 600;" %>"><%= educatorName %> (Educator)</div>
                            <div class="last-msg-preview <%= unreadEd ? "unread" : "" %>"><%= edPreview %></div>
                        </div>
                        <% if (unreadEd) { %><div class="noti-dot"></div><% } %>
                    </a>
                <% } %>

                <% if (!enrolledStudents.isEmpty()) {
                    for (User peer : enrolledStudents) {
                        if (peer.getUserId() == u.getUserId()) continue; // Skip yourself!
                        
                        String activeClass = (peer.getUserId() == targetUserId) ? "active" : "";
                        String peerName = (peer.getFullName() != null && !peer.getFullName().trim().isEmpty()) ? peer.getFullName() : "Unknown Student";
                        String initial = peerName.substring(0, 1).toUpperCase();
                        
                        List<DirectMessage> previewChat = msgDao.getConversation(classId, u.getUserId(), peer.getUserId());
                        boolean unread = false;
                        String previewText = "No messages yet";
                        
                        if (!previewChat.isEmpty()) {
                            DirectMessage lastMsg = previewChat.get(previewChat.size() - 1);
                            previewText = lastMsg.getMessageBody();
                            if (lastMsg.getSenderId() == peer.getUserId()) {
                                Boolean isRead = (Boolean) session.getAttribute("read_chat_" + classId + "_" + peer.getUserId());
                                if (isRead == null || !isRead) unread = true;
                            }
                        }
                %>
                    <a href="class_qa.jsp?classId=<%= classId %>&studentId=<%= peer.getUserId() %>" class="student-item <%= activeClass %>">
                        <div class="avatar"><%= initial %></div>
                        <div class="student-info">
                            <div class="student-name"><%= peerName %></div>
                            <div class="last-msg-preview <%= unread ? "unread" : "" %>"><%= previewText %></div>
                        </div>
                        <% if (unread) { %><div class="noti-dot" title="New Message"></div><% } %>
                    </a>
                <%  } 
                } %>
            </div>
        </div>

        <div class="chat-main">
            <div class="chat-header">
                <div class="avatar" style="display:flex; align-items:center; justify-content:center; background: #f1f5f9; color: var(--primary);">
                    <% if (targetUserId == -1) { %>
                        <i class='bx bx-group'></i>
                    <% } else if (targetUserId == educatorId && isStudent) { %>
                        <i class='bx bxs-graduation'></i>
                    <% } else { %>
                        <%= targetUserName.substring(0, 1).toUpperCase() %>
                    <% } %>
                </div>
                <div>
                    <h3><%= targetUserName %></h3>
                    <% if (targetUserId == -1) { %>
                        <span style="font-size: 0.75rem; color: #64748b;">Visible to everyone in <%= currentClass.getClassName() %></span>
                    <% } %>
                </div>
            </div>

            <div class="chat-messages" id="chatBox">
                <% if (chatHistory.isEmpty()) { %>
                    <div style="text-align: center; padding: 16px; background: #f1f5f9; color: #475569; border-radius: 16px; margin: auto; max-width: 360px; font-size: 0.85rem; border: 1px solid var(--border);">
                        <% if (targetUserId == -1) { %>
                            <i class='bx bx-info-circle' style='color: var(--primary); font-size: 1.1rem;'></i> <br><strong>Welcome to the Group Workspace Chat!</strong><br>Shared answers and questions are mirrored here.
                        <% } else { %>
                            <i class='bx bx-lock-alt' style='color: #10b981; font-size: 1.1rem;'></i> <br>Secure individual private conversation lane.
                        <% } %>
                    </div>
                <% } else {
                    for (DirectMessage m : chatHistory) {
                        boolean isSentByMe = (m.getSenderId() == u.getUserId());
                        String displayName = isSentByMe ? "You" : userNamesMap.getOrDefault(m.getSenderId(), "User " + m.getSenderId());
                %>
                    <div class="msg-wrapper <%= isSentByMe ? "sent" : "received" %>">
                        <% if (targetUserId == -1 && !isSentByMe) { %>
                            <div class="msg-sender-name"><%= displayName %></div>
                        <% } %>
                        <div class="msg">
                            <%= m.getMessageBody() %>
                            <span class="msg-time"><%= m.getSentAt().toString().substring(11, 16) %></span>
                        </div>
                    </div>
                <%  } 
                } %>
            </div>

            <form class="chat-input-area" action="SendMessageServlet" method="POST">
                <input type="hidden" name="classId" value="<%= classId %>">
                <input type="hidden" name="receiverId" value="<%= targetUserId %>">
                <input type="text" name="messageBody" class="chat-input" placeholder="Type a message..." required autocomplete="off" autofocus>
                <button type="submit" class="btn-send"><i class='bx bxs-send'></i></button>
            </form>
        </div>
    </div>

    <script>
        var chatBox = document.getElementById("chatBox");
        if (chatBox) chatBox.scrollTop = chatBox.scrollHeight;

        function filterStudents() {
            let input = document.getElementById('searchInput');
            let filter = input.value.toLowerCase();
            let ul = document.getElementById('studentList');
            let li = ul.getElementsByTagName('a');

            for (let i = 0; i < li.length; i++) {
                let nameDiv = li[i].getElementsByClassName('student-name')[0];
                if(nameDiv) {
                    let txtValue = nameDiv.textContent || nameDiv.innerText;
                    if (txtValue.toLowerCase().indexOf(filter) > -1) {
                        li[i].style.display = "";
                    } else {
                        li[i].style.display = "none";
                    }
                }
            }
        }
    </script>
</body>
</html>