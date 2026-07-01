<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="dao.ComputationDAO, model.Computation, model.User" %>
<%
    response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
    User u = (User) session.getAttribute("user");
    if (u == null) { 
        response.sendRedirect("login.jsp"); 
        return; 
    }

    String compIdStr = request.getParameter("id");
    Computation comp = null;
    
    if (compIdStr != null && !compIdStr.isEmpty()) {
        int compId = Integer.parseInt(compIdStr);
        ComputationDAO dao = new ComputationDAO();
        comp = dao.getComputationById(compId, u.getUserId());
    }

    if (comp == null) {
        response.sendRedirect("computations.jsp?error=notfound");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Computation Report | NumSolve</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
    <link href='https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css' rel='stylesheet'>
    
    <script src="https://cdnjs.cloudflare.com/ajax/libs/mathjs/11.8.0/math.js"></script>
    <script src="https://cdn.plot.ly/plotly-2.24.1.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>

    <style>
        body { font-family: 'Poppins', sans-serif; background-color: #f4f6f9; color: #2c3e50; padding: 40px; }
        .report-wrapper { max-width: 900px; margin: 0 auto; }
        .report-container { background: #fff; padding: 40px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); margin-bottom: 20px;}
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #e2e8f0; padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { font-size: 1.8rem; margin: 0; color: #4e73df; }
        
        .data-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 20px; margin-bottom: 30px; }
        .data-box { background: #f8fafc; padding: 15px; border-radius: 8px; border: 1px solid #e2e8f0; text-align: center; }
        .data-label { font-size: 0.75rem; color: #64748b; text-transform: uppercase; font-weight: 600; margin-bottom: 5px; }
        .data-value { font-size: 1.2rem; font-weight: 600; color: #8b5cf6; word-break: break-word;}
        
        .section-title { font-size: 1.2rem; font-weight: 600; margin-top: 30px; margin-bottom: 15px; border-bottom: 2px solid #f1f5f9; padding-bottom: 10px;}
        
        /* Table Styles for renderOutput */
        .math-box { background: #e0f2fe; padding: 15px; border-left: 4px solid #0ea5e9; margin-bottom: 20px; border-radius: 4px; font-family: monospace; font-size: 0.95rem; line-height: 1.6;}
        table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 0.9rem; }
        th, td { border: 1px solid #e2e8f0; padding: 10px; text-align: center; }
        th { background-color: #f8fafc; color: #475569; }
        
        .btn-group { display: flex; gap: 15px; justify-content: flex-end; }
        .btn { padding: 10px 20px; border-radius: 6px; border: none; cursor: pointer; font-family: inherit; font-weight: 500; display: inline-flex; align-items: center; gap: 8px; text-decoration: none; }
        .btn-back { background: #e2e8f0; color: #475569; }
        .btn-csv { background: #10b981; color: white; } /* Green for CSV */
        .btn-pdf { background: #ef4444; color: white; } /* Red for PDF */
        
        /* Utility for PDF export */
        .hidden { display: none !important; }
        
        @media print { .btn-group { display: none; } body { background: white; padding: 0;} .report-container { box-shadow: none; padding: 0;} }
    </style>
</head>
<body onload="rebuildVisuals()">

    <div class="report-wrapper">
        <div class="report-container" id="reportArea">
            <div class="header">
                <div>
                    <h1><%= comp.getDisplayTitle() %></h1>
                    <p style="margin: 5px 0 0 0; color: #64748b;">Method ID: <strong><%= comp.getMethodId() %></strong> | Date: <%= comp.getComputationDate() %></p>
                    <p style="margin: 5px 0 0 0; font-family: monospace; background: #f1f5f9; padding: 5px; border-radius: 4px; display: inline-block;">Inputs: <%= comp.getDisplayInputData() %></p>
                </div>
                <div><i class='bx bxs-calculator' style="font-size: 3rem; color: #cbd5e1;"></i></div>
            </div>

            <div class="data-grid">
                <div class="data-box" style="border-color: #10b981; background: #ecfdf5;">
                    <div class="data-label">Final Answer</div>
                    <div class="data-value" style="color: #059669; font-size: 1.4rem;"><%= comp.getResult() != null ? comp.getResult() : "N/A" %></div>
                </div>
                <div class="data-box">
                    <div class="data-label">Iterations</div>
                    <div class="data-value"><%= comp.getIteration() != null ? comp.getIteration() : "-" %></div>
                </div>
                <div class="data-box">
                    <div class="data-label">Final Error</div>
                    <div class="data-value"><%= comp.getErrorValue() != null ? comp.getErrorValue() : "N/A" %></div>
                </div>
            </div>

            <div class="section-title">Step-by-Step Calculation Details</div>
            <div id="calculationDetails" style="overflow-x: auto;">
                <p style="color: #94a3b8; text-align: center;">Rebuilding table data...</p>
            </div>

            <div class="section-title">Graphical Visualization</div>
            <div id="graph" style="height: 400px; width: 100%; border: 1px solid #e2e8f0; border-radius: 8px; background: #f8fafc;"></div>
        </div>

        <div class="btn-group" id="actionToolbar">
            <a href="computations.jsp" class="btn btn-back"><i class='bx bx-arrow-back'></i> Back to List</a>
            <button onclick="exportCSV()" class="btn btn-csv"><i class='bx bx-table'></i> Save CSV</button>
            <button onclick="exportPDF()" class="btn btn-pdf"><i class='bx bxs-file-pdf'></i> Save PDF</button>
        </div>
    </div>

    <script>
        // Global variable to hold CSV data
        window.latestCSVData = [];

        // --- HELPER FUNCTIONS FROM SOLVER.JSP ---
        function generateCurve(eqStr, minX, maxX, step = 0.1) {
            let xVals = [], yVals = [];
            let f = (x) => math.evaluate(eqStr, { x: x });
            if (maxX <= minX) { maxX = minX + 10; minX = minX - 10; } 
            if (step <= 0 || (maxX - minX) / step > 5000) step = Math.max((maxX - minX) / 1000, 0.01);
            for (let x = minX; x <= maxX; x += step) {
                xVals.push(x); yVals.push(f(x));
            }
            return { x: xVals, y: yVals };
        }

        function renderOutput(formula, sample, headers, rows) {
            let html = '<div class="math-box">' + formula + '<br><br><b>Sample First Step:</b><br>' + sample + '</div>';
            if (headers && headers.length > 0) {
                html += '<table><thead><tr>';
                headers.forEach(h => html += '<th>' + h + '</th>');
                html += '</tr></thead><tbody>';
                rows.forEach(row => {
                    html += '<tr>';
                    row.forEach(cell => html += '<td>' + cell + '</td>');
                    html += '</tr>';
                });
                html += '</tbody></table>';
            }
            document.getElementById("calculationDetails").innerHTML = html;
        }

        // --- EXPORT FUNCTIONS ---
        function exportPDF() {
            window.scrollTo(0, 0); 
            const element = document.getElementById('reportArea');
            const toolbar = document.getElementById('actionToolbar');
            
            if(toolbar) toolbar.classList.add('hidden');
            
            const opt = {
                margin:       0.3,
                filename:     'NumSolve_Report.pdf',
                image:        { type: 'jpeg', quality: 0.98 },
                html2canvas:  { scale: 2, useCORS: true, scrollY: 0 },
                jsPDF:        { unit: 'in', format: 'letter', orientation: 'portrait' }
            };
            
            html2pdf().set(opt).from(element).save().then(() => {
                if(toolbar) toolbar.classList.remove('hidden');
            }).catch(err => {
                alert("Error generating PDF: " + err);
                if(toolbar) toolbar.classList.remove('hidden');
            });
        }

        function exportCSV() {
            if (!window.latestCSVData || window.latestCSVData.length === 0) {
                alert("No table data available to export.");
                return;
            }
            
            let csvContent = window.latestCSVData.map(e => e.join(",")).join("\n");
            let blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            let url = URL.createObjectURL(blob);
            
            var link = document.createElement("a");
            link.setAttribute("href", url);
            link.setAttribute("download", "NumSolve_Data.csv");
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        // --- MAIN REBUILD ENGINE ---
        function rebuildVisuals() {
            const method = "<%= comp.getMethodId() %>";
            const inputStr = "<%= comp.getInputData() != null ? comp.getInputData().replace("\"", "\\\"") : "" %>";
            
            // 1. Parse DB string into dictionary map
            const params = {};
            inputStr.split(';').forEach(part => {
                let eqIndex = part.indexOf('=');
                if (eqIndex === -1) return;
                let key = part.substring(0, eqIndex).trim();
                let val = part.substring(eqIndex + 1).trim();
                params[key] = val;
            });

            // Clean up Arrays if they exist (Interpolation)
            if(params['X']) params['X'] = params['X'].replace(/[\[\]]/g, '');
            if(params['Y']) params['Y'] = params['Y'].replace(/[\[\]]/g, '');

            let traces = []; let tableData = []; let tableHeaders = []; 
            let formula = "", sampleCalc = "";
            let iter = 0; // Local counter for rebuild loops

            try {
                // Determine equation if applicable
                let eqStr = params['f(x)'] || params['dy/dx'];
                let f, f_xy;
                if(eqStr) {
                    f = (x) => math.evaluate(eqStr, { x: x });
                    f_xy = (x, y) => math.evaluate(eqStr, { x: x, y: y });
                }

                // 2. Engine Logic Matrix
                if (method === "M001" || method === "M010") {
                    let a = parseFloat(params['a']), b = parseFloat(params['b']);
                    let a_init = a, b_init = b;
                    let tol = parseFloat(params['tol'] || params['tolerance'] || 0.001);
                    
                    formula = method === "M001" ? "<b>Formula:</b> c = (a + b) / 2" : "<b>Formula:</b> c = a - [ f(a) * (b - a) ] / [ f(b) - f(a) ]";
                    sampleCalc = method === "M001" ? 
                        "c = (" + a + " + " + b + ") / 2 = <b>" + ((a+b)/2).toFixed(5) + "</b>" : 
                        "c = " + a + " - [ " + f(a).toFixed(4) + " * (" + b + " - " + a + ") ] / [ " + f(b).toFixed(4) + " - " + f(a).toFixed(4) + " ]";
                    
                    tableHeaders = ['Iter', 'a', 'b', 'c', 'f(c)', 'Error'];

                    let c = a, c_old = a, error = 100;
                    while (error > tol && iter < 100) {
                        iter++;
                        c = (method === "M001") ? (a + b) / 2 : a - (f(a) * (b - a)) / (f(b) - f(a));
                        error = Math.abs(c - c_old);
                        tableData.push([iter, a.toFixed(5), b.toFixed(5), c.toFixed(5), f(c).toFixed(5), iter===1?"-":error.toFixed(5)]);
                        if (f(c) === 0) break;
                        if (f(c) * f(a) < 0) b = c; else a = c;
                        c_old = c;
                    }
                    
                    let curve = generateCurve(eqStr, Math.min(a_init, b_init) - 1, Math.max(a_init, b_init) + 1);
                    traces.push({ x: curve.x, y: curve.y, mode: 'lines', name: 'f(x)', line: {color: '#6366f1', width: 3} });
                    traces.push({ x: [a_init, b_init], y: [f(a_init), f(b_init)], mode: 'markers', name: 'Interval Points', marker: {size: 10, color: '#1e293b'} });
                    traces.push({ x: [c], y: [0], mode: 'markers', name: 'Root', marker: {size: 15, color: '#ec4899', symbol: 'star'} });

                } else if (method === "M002") { // Newton
                    let x0 = parseFloat(params['x0']);
                    let x0_init = x0;
                    let tol = parseFloat(params['tol'] || params['tolerance'] || 0.001);
                    
                    formula = "<b>Formula:</b> x_{i+1} = x_i - [ f(x_i) / f'(x_i) ]";
                    const df = (x) => math.evaluate(math.derivative(eqStr, 'x').toString(), { x: x });
                    sampleCalc = "x_1 = " + x0 + " - [ " + f(x0).toFixed(5) + " / " + df(x0).toFixed(5) + " ] = <b>" + (x0 - (f(x0)/df(x0))).toFixed(5) + "</b>";
                    tableHeaders = ['Iter', 'x_i', 'f(x_i)', "f'(x_i)", 'x_{i+1}', 'Error'];
                    
                    let error = 100;
                    while (error > tol && iter < 100) {
                        iter++; let d = df(x0);
                        if(d === 0) break;
                        let x1 = x0 - (f(x0) / d);
                        error = Math.abs(x1 - x0);
                        tableData.push([iter, x0.toFixed(5), f(x0).toFixed(5), d.toFixed(5), x1.toFixed(5), error.toFixed(5)]);
                        x0 = x1;
                    }

                    let curve = generateCurve(eqStr, Math.min(x0_init, x0) - 1, Math.max(x0_init, x0) + 1);
                    traces.push({ x: curve.x, y: curve.y, mode: 'lines', name: 'f(x)', line: {color: '#6366f1', width: 3} });
                    traces.push({ x: [x0_init], y: [f(x0_init)], mode: 'markers', name: 'Initial Guess', marker: {size: 12, color: '#f59e0b'} });
                    traces.push({ x: [x0], y: [0], mode: 'markers', name: 'Root', marker: {size: 15, color: '#ec4899', symbol: 'star'} });

                } else if (method === "M003") { // Secant
                    let x0 = parseFloat(params['x0']), x1 = parseFloat(params['x1']);
                    let x0_init = x0, x1_init = x1;
                    let tol = parseFloat(params['tol'] || params['tolerance'] || 0.001);
                    
                    formula = "<b>Formula:</b> x_{i+1} = x_i - [ f(x_i) * (x_i - x_{i-1}) ] / [ f(x_i) - f(x_{i-1}) ]";
                    sampleCalc = "x_2 = " + x1 + " - [ " + f(x1).toFixed(5) + " * (" + x1 + " - " + x0 + ") ] / [ " + f(x1).toFixed(5) + " - (" + f(x0).toFixed(5) + ") ]";
                    tableHeaders = ['Iter', 'x_{i-1}', 'x_i', 'x_{i+1}', 'Error'];
                    
                    let error = 100;
                    while (error > tol && iter < 100) {
                        iter++; 
                        if (f(x1) - f(x0) === 0) break;
                        let x2 = x1 - (f(x1) * (x1 - x0)) / (f(x1) - f(x0));
                        error = Math.abs(x2 - x1);
                        tableData.push([iter, x0.toFixed(5), x1.toFixed(5), x2.toFixed(5), error.toFixed(5)]);
                        x0 = x1; x1 = x2;
                    }

                    let curve = generateCurve(eqStr, Math.min(x0_init, x1_init, x1) - 1, Math.max(x0_init, x1_init, x1) + 1);
                    traces.push({ x: curve.x, y: curve.y, mode: 'lines', name: 'f(x)', line: {color: '#6366f1', width: 3} });
                    traces.push({ x: [x0_init, x1_init], y: [f(x0_init), f(x1_init)], mode: 'markers', name: 'Initial Guesses', marker: {size: 12, color: '#f59e0b'} });
                    traces.push({ x: [x1], y: [0], mode: 'markers', name: 'Root', marker: {size: 15, color: '#ec4899', symbol: 'star'} });

                } else if (method === "M011" || method === "M004") { // Interpolation
                    let xs = params['X'].split(',').map(Number);
                    let ys = params['Y'].split(',').map(Number);
                    let targetX = parseFloat(params['Target'] || params['target']);
                    
                    let curveX = [], curveY = [], result = 0; 
                    
                    if(method === "M011") { // Lagrange
                        formula = "<b>Formula:</b> L(x) = sum( y_i * prod((x - x_j)/(x_i - x_j)) )";
                        sampleCalc = "Calculating L(x) polynomials mapping exactly to provided points.";
                        for (let i = 0; i < xs.length; i++) {
                            let term = ys[i];
                            for (let j = 0; j < xs.length; j++) { if (i !== j) term *= (targetX - xs[j]) / (xs[i] - xs[j]); }
                            result += term;
                        }
                        for(let x = Math.min(...xs)-1; x <= Math.max(...xs)+1; x += 0.1) {
                            curveX.push(x); let cy = 0;
                            for (let i = 0; i < xs.length; i++) {
                                let term = ys[i];
                                for (let j = 0; j < xs.length; j++) { if (i !== j) term *= (x - xs[j]) / (xs[i] - xs[j]); }
                                cy += term;
                            }
                            curveY.push(cy);
                        }
                        traces.push({ x: curveX, y: curveY, mode: 'lines', name: 'Lagrange', line: {color: '#8b5cf6', shape: 'spline'} });
                    } else { // Linear Spline
                        formula = "<b>Formula:</b> y = y_i + [ (y_{i+1} - y_i) / (x_{i+1} - x_i) ] * (x - x_i)";
                        sampleCalc = "Target mapped linearly between nearest data points.";
                        for (let i = 0; i < xs.length - 1; i++) {
                            if (targetX >= xs[i] && targetX <= xs[i+1]) { 
                                result = ys[i] + ((ys[i+1] - ys[i]) / (xs[i+1] - xs[i])) * (targetX - xs[i]); 
                                break; 
                            }
                        }
                        traces.push({ x: xs, y: ys, mode: 'lines', name: 'Linear Spline', line: {color: '#8b5cf6'} });
                    }
                    traces.push({ x: xs, y: ys, mode: 'markers', name: 'Data', marker: {size: 12, color: '#10b981'} });
                    traces.push({ x: [targetX], y: [result], mode: 'markers', name: 'Result', marker: {size: 18, color: '#f43f5e', symbol: 'diamond'} });
                    tableHeaders = ['Parameter', 'Value'];
                    tableData = [['Data Points', xs.length], ['Target X', targetX], ['Result Y', result.toFixed(5)]];

                } else if (method === "M012") { // Diff
                    let x0 = parseFloat(params['x']);
                    let h = 0.0001; 
                    let result = (f(x0 + h) - f(x0 - h)) / (2 * h);
                    formula = "<b>Formula:</b> f'(x) ≈ [ f(x + h) - f(x - h) ] / 2h";
                    sampleCalc = "f'(" + x0 + ") ≈ [ f(" + (x0 + h) + ") - f(" + (x0 - h) + ") ] / (2 * " + h + ") = <b>" + result.toFixed(5) + "</b>";
                    
                    let curve = generateCurve(eqStr, x0 - 4, x0 + 4);
                    let y0 = f(x0);
                    let tanX = [x0 - 2, x0 + 2];
                    let tanY = [result * (tanX[0] - x0) + y0, result * (tanX[1] - x0) + y0];

                    traces.push({ x: curve.x, y: curve.y, mode: 'lines', name: 'f(x)', line: {color: '#6366f1', width: 3} });
                    traces.push({ x: tanX, y: tanY, mode: 'lines', name: "Tangent", line: {color: '#ef4444', dash: 'dashdot'} });
                    traces.push({ x: [x0], y: [y0], mode: 'markers', name: 'Point', marker: {size: 14, color: '#f59e0b'} });
                    tableHeaders = ['Parameter', 'Value'];
                    tableData = [['Function', eqStr], ['Point', x0], ['Calculated Slope', result.toFixed(6)]];
                
                } else if (method === "M009") { // Error Analysis
                    // 1. Extract parameters from the saved string
                    let trueVal = parseFloat(params['True'] || params['true']);
                    let approxVal = parseFloat(params['Approx'] || params['approx']);
                    
                    // 2. Re-calculate metrics
                    let absError = Math.abs(trueVal - approxVal);
                    let relError = trueVal !== 0 ? absError / Math.abs(trueVal) : 0;
                    let percError = relError * 100;
                    
                    // 3. Setup text displays
                    formula = "<b>Formulas:</b><br>Absolute Error (E_a) = |True - Approx|<br>Relative Error (E_r) = |True - Approx| / |True|<br>Percentage Error = E_r * 100%";
                    sampleCalc = "E_a = |" + trueVal + " - " + approxVal + "| = <b>" + absError.toFixed(6) + "</b>";
                    
                    // 4. Populate the data table
                    tableHeaders = ['Metric', 'Value'];
                    tableData = [
                        ['True Value', trueVal],
                        ['Approximate Value', approxVal],
                        ['Absolute Error', absError.toFixed(6)],
                        ['Relative Error', relError.toFixed(6)],
                        ['Percentage Error', percError.toFixed(4) + "%"]
                    ];
                    
                    // 5. Build the Bar Chart trace
                    traces.push({ 
                        x: ['True Value', 'Approx Value'], 
                        y: [trueVal, approxVal], 
                        type: 'bar', 
                        marker: {color: ['#10b981', '#f43f5e']} 
                    });
                    
                } else if (method === "M005" || method === "M006" || method === "M007") { // Integration
                    let a = parseFloat(params['a']), b = parseFloat(params['b']);
                    let n = parseInt(params['n']);
                    let h = (b - a) / n; let sum = 0, result = 0;
                    
                    let curve = generateCurve(eqStr, a - 0.5, b + 0.5, (b-a)/100);
                    traces.push({ x: curve.x, y: curve.y, mode: 'lines', name: 'f(x)', line: {color: '#6366f1', width: 3} });

                    if (method === "M005") { // Trap
                        formula = "<b>Formula:</b> I = (h/2) * [ f(x0) + 2*f(x1) + ... + f(xn) ]";
                        sampleCalc = "I ≈ (" + h.toFixed(4) + " / 2) * [ f(" + a + ") + 2*f(" + (a+h) + ") + ... ]";
                        sum = f(a) + f(b); 
                        for (let i = 1; i < n; i++) sum += 2 * f(a + i * h);
                        result = (h / 2) * sum;

                        let trapX = [a], trapY = [0];
                        for(let i=0; i<=n; i++){ 
                            let xi = a + i*h; trapX.push(xi); trapY.push(f(xi)); 
                        }
                        trapX.push(b); trapY.push(0);
                        traces.push({ x: trapX, y: trapY, fill: 'toself', name: 'Trapezoids', fillcolor: 'rgba(236, 72, 153, 0.3)', line: {color: '#ec4899'} });
                    } else if (method === "M006") { // Midpoint
                        formula = "<b>Formula:</b> I = h * sum( f(x_mid) )";
                        sampleCalc = "I ≈ " + h.toFixed(4) + " * [ f(" + (a + 0.5*h) + ") + ... ]";
                        let rectX = [], rectY = [];
                        for (let i = 0; i < n; i++) { 
                            let x_start = a + i * h, x_end = a + (i + 1) * h, xmid = a + (i + 0.5) * h; 
                            let ymid = f(xmid); sum += ymid; 
                            rectX.push(x_start, x_start, x_end, x_end, null); 
                            rectY.push(0, ymid, ymid, 0, null);
                        }
                        result = h * sum;
                        traces.push({ x: rectX, y: rectY, fill: 'toself', name: 'Midpoint Rects', fillcolor: 'rgba(16, 185, 129, 0.3)', line: {color: '#10b981'} });
                    } else if (method === "M007") { // Simpson
                        formula = "<b>Formula:</b> I = (h/3) * [ f(x0) + 4*f(x1) + 2*f(x2) + ... + f(xn) ]";
                        sampleCalc = "I ≈ (" + h.toFixed(4) + " / 3) * [ f(" + a + ") + 4*f(" + (a+h) + ") + ... ]";
                        sum = f(a) + f(b); 
                        for (let i = 1; i < n; i++) sum += (i % 2 === 0 ? 2 : 4) * f(a + i * h);
                        result = (h / 3) * sum;
                        let areaCurve = generateCurve(eqStr, a, b, (b-a)/100); 
                        traces.push({ x: areaCurve.x, y: areaCurve.y, fill: 'tozeroy', name: 'Simpson Area', fillcolor: 'rgba(139, 92, 246, 0.3)', line: {color: 'transparent'} });
                    }
                    tableHeaders = ['Parameter', 'Value'];
                    tableData = [['Limits', "[ " + a + ", " + b + " ]"], ['Segments (n)', n], ['Step (h)', h.toFixed(5)], ['Integral', result.toFixed(6)]];

                } else if (method === "M008") { // Euler ODE
                    let x0 = parseFloat(params['x0']), y0 = parseFloat(params['y0']);
                    let h = parseFloat(params['h']), target = parseFloat(params['target'] || params['Target']);
                    
                    formula = "<b>Formula:</b> y_{i+1} = y_i + h * f(x_i, y_i)";
                    sampleCalc = "y_1 = " + y0 + " + (" + h + ") * f(" + x0 + ", " + y0 + ") = <b>" + (y0 + h * f_xy(x0,y0)).toFixed(4) + "</b>";
                    tableHeaders = ['Step (i)', 'x_i', 'y_i', 'f(x_i, y_i)', 'y_{i+1}'];
                    
                    let steps = Math.round((target - x0) / h);
                    let xArr = [x0], yArr = [y0]; let x = x0, y = y0;

                    for (let i = 1; i <= steps; i++) {
                        let slope = f_xy(x, y);
                        let nextY = y + h * slope;
                        tableData.push([i-1, x.toFixed(4), y.toFixed(4), slope.toFixed(4), nextY.toFixed(4)]);
                        x = x + h; y = nextY;
                        xArr.push(x); yArr.push(y);
                    }
                    traces.push({ x: xArr, y: yArr, mode: 'lines+markers', name: 'Euler Path', line: {color: '#4f46e5'}, marker: {size: 10} });
                    traces.push({ x: [x], y: [y], mode: 'markers', name: 'Target', marker: {size: 18, color: '#ef4444', symbol: 'star'} });
                }

                // 3. Save Data for CSV Export
                if (tableHeaders.length > 0) {
                    window.latestCSVData = [tableHeaders, ...tableData];
                }

                // 4. Final Outputs
                renderOutput(formula, sampleCalc, tableHeaders, tableData);
                
                Plotly.newPlot('graph', traces, { 
                    hovermode: 'closest', plot_bgcolor: '#f8fafc', paper_bgcolor: '#ffffff',
                    xaxis: { gridcolor: '#e2e8f0', zerolinecolor: '#cbd5e1' }, yaxis: { gridcolor: '#e2e8f0', zerolinecolor: '#cbd5e1' },
                    margin: { t: 20, b: 40, l: 40, r: 20 }
                });

            } catch (err) {
                document.getElementById('calculationDetails').innerHTML = 
                    "<div style='padding: 15px; background: #fee2e2; color: #b91c1c; border-radius: 6px; border: 1px solid #f87171;'>" +
                    "<b>Error Rebuilding Math:</b> " + err.message + "</div>";
                document.getElementById('graph').innerHTML = "";
            }
        }
    </script>
</body>
</html>