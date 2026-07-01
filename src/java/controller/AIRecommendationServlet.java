package controller;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import org.json.JSONArray;
import org.json.JSONObject;

@WebServlet("/aiRecommend")
public class AIRecommendationServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // 🔴 put your key here OR later move to env
    private static final String API_KEY = "AQ.Ab8RN6K7zljp8kXkiZfMfXeOvCJP0ZtmTY1beujf-P-VorDmGQ";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String userQuestion = request.getParameter("question");

        if (userQuestion == null || userQuestion.trim().isEmpty()) {
            out.print(error("No input provided. Please enter a math problem."));
            return;
        }

        try {
            // ================= 1. PROMPT (IMPROVED STYLE) =================
            String prompt = 
                  "You are an expert in Numerical Methods.\n"
                + "Analyze the following user question and choose the ONE best method from this list:\n"
                + "[M001 Bisection, M002 Newton-Raphson, M003 Secant, M004 False Position, "
                + "M005 Trapezoidal, M006 Simpson, M007 Lagrange, M008 Euler, M012 Derivative Approximation]\n\n"
                + "Return ONLY a valid JSON object in this exact format:\n"
                + "{\n"
                + "  \"methodId\": \"M006\",\n"
                + "  \"methodName\": \"Simpson's Rule\",\n"
                + "  \"reason\": \"Provide a clear, engaging, 2-3 sentence explanation of WHY this method is best for their specific problem.\"\n"
                + "}\n\n"
                + "User Question: " + userQuestion;

            // ================= 2. BUILD GEMINI REQUEST SAFELY =================
            JSONObject textPart = new JSONObject().put("text", prompt);
            JSONObject partsObj = new JSONObject().put("parts", new JSONArray().put(textPart));
            
            JSONObject requestBody = new JSONObject();
            requestBody.put("contents", new JSONArray().put(partsObj));

            // Force Gemini to output pure JSON (No markdown backticks allowed!)
            JSONObject genConfig = new JSONObject();
            genConfig.put("responseMimeType", "application/json");
            requestBody.put("generationConfig", genConfig);

            String body = requestBody.toString();

            // ================= 3. HTTP CONNECTION =================
            URL url = new URL("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + API_KEY);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setDoOutput(true);

            // try-with-resources automatically closes the OutputStream
            try (OutputStream os = conn.getOutputStream()) {
                os.write(body.getBytes("UTF-8"));
            }

            // ================= 4. READ RESPONSE =================
            StringBuilder sb = new StringBuilder();
            int responseCode = conn.getResponseCode();
            
            if (responseCode == HttpURLConnection.HTTP_OK) {
                // try-with-resources automatically closes the BufferedReader
                try (BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"))) {
                    String line;
                    while ((line = br.readLine()) != null) {
                        sb.append(line);
                    }
                }
            } else {
                throw new IOException("HTTP Error code from Gemini API: " + responseCode);
            }

            // ================= 5. PARSE GEMINI =================
            JSONObject json = new JSONObject(sb.toString());
            
            // Because of responseMimeType, this text is guaranteed to be clean JSON
            String text = json.getJSONArray("candidates")
                    .getJSONObject(0)
                    .getJSONObject("content")
                    .getJSONArray("parts")
                    .getJSONObject(0)
                    .getString("text");

            // ================= 6. PARSE AI JSON =================
            JSONObject ai;
            try {
                ai = new JSONObject(text.trim());
            } catch (Exception e) {
                fallback(out, "Failed to parse JSON. Raw text: " + text);
                return;
            }

            // ================= 7. SEND FINAL RESULT TO FRONTEND =================
            JSONObject result = new JSONObject();
            result.put("methodId", ai.optString("methodId", "M001"));
            result.put("methodName", ai.optString("methodName", "Bisection Method"));
            result.put("reason", ai.optString("reason", "The AI determined this is the best method to use."));

            out.print(result.toString());

        } catch (Exception e) {
            e.printStackTrace();
            out.print(error("AI service error: " + e.getMessage()));
        }
    }

    // ================= HELPERS =================

    private String error(String msg) {
        return "{"
                + "\"methodId\":\"M001\","
                + "\"methodName\":\"Bisection Method\","
                + "\"reason\":\"" + msg + "\""
                + "}";
    }

    private void fallback(PrintWriter out, String raw) {
        JSONObject obj = new JSONObject();
        obj.put("methodId", "M001");
        obj.put("methodName", "Bisection Method");
        obj.put("reason", raw);
        out.print(obj.toString());
    }
}