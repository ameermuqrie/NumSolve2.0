<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error | NumSolve</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Poppins', sans-serif; }
        body { 
            background-color: #f0f2f5; 
            color: #1e293b; 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            height: 100vh; 
        }
        .error-container { 
            background: white; 
            padding: 40px; 
            border-radius: 12px; 
            box-shadow: 0 10px 25px rgba(0,0,0,0.05); 
            text-align: center; 
            max-width: 500px; 
            width: 90%; 
            border-top: 5px solid #ef4444; 
        }
        .error-container i { 
            font-size: 5rem; 
            color: #ef4444; 
            margin-bottom: 20px; 
        }
        h1 { 
            font-size: 1.5rem; 
            margin-bottom: 10px; 
            font-weight: 600;
        }
        p { 
            color: #64748b; 
            margin-bottom: 25px; 
            line-height: 1.5;
        }
        .btn { 
            background: #3b82f6; 
            color: white; 
            padding: 10px 24px; 
            border-radius: 8px; 
            text-decoration: none; 
            font-weight: 500; 
            display: inline-block; 
            transition: 0.3s; 
            border: none;
            cursor: pointer;
        }
        .btn:hover { background: #2563eb; transform: translateY(-2px); }
    </style>
</head>
<body>
    <div class="error-container">
        <i class='bx bx-error-circle'></i>
        <h1>Oops! Something went wrong.</h1>
        <p>
            <% 
                String errorMsg = (String) request.getAttribute("errorMessage");
                if (errorMsg != null && !errorMsg.isEmpty()) {
                    out.print(errorMsg);
                } else {
                    out.print("We encountered an unexpected error or couldn't find the requested class data. Please make sure you are accessing this page correctly.");
                }
            %>
        </p>
        <a href="javascript:history.back()" class="btn">Go Back</a>
    </div>
</body>
</html>