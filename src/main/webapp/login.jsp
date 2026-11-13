<%@ page import="java.sql.*,java.security.*,javax.crypto.SecretKeyFactory,javax.crypto.spec.PBEKeySpec,java.util.Base64" %>
<%@ page import="com.studentapp.util.DBConnection" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<%!
    // Temporary credentials for the local coursework project.
    private static final String ADMIN_USERNAME = "admin";
    private static final String ADMIN_PASSWORD = "ChangeThisAdmin123!";

    private boolean verifyStudentPassword(String password, String stored)
            throws Exception {

        if (stored == null) return false;

        String[] parts = stored.split(":");
        if (parts.length != 2) return false;

        byte[] salt = Base64.getDecoder().decode(parts[0]);
        byte[] expected = Base64.getDecoder().decode(parts[1]);

        PBEKeySpec spec = new PBEKeySpec(
            password.toCharArray(), salt, 120000, 256
        );

        try {
            byte[] actual = SecretKeyFactory
                .getInstance("PBKDF2WithHmacSHA256")
                .generateSecret(spec)
                .getEncoded();

            return MessageDigest.isEqual(expected, actual);
        } finally {
            spec.clearPassword();
        }
    }
%>

<%
String error = null;

if ("POST".equalsIgnoreCase(request.getMethod())) {

    String username = request.getParameter("username");
    String password = request.getParameter("password");

    if (username == null || username.trim().isEmpty()
            || password == null || password.isEmpty()) {

        error = "Enter your roll number and password.";

    } else {
        username = username.trim();

        // Check the administrator account first.
        if (ADMIN_USERNAME.equals(username)
                && ADMIN_PASSWORD.equals(password)) {

            session.invalidate();
            session = request.getSession(true);

            session.setAttribute("role", "admin");
            session.setAttribute("username", ADMIN_USERNAME);

            response.sendRedirect("adminDashboard.jsp");
            return;

        } else {
            // Otherwise, authenticate as a student using Oracle.
            String sql =
                "SELECT FIRST_NAME, PASSWORD_HASH " +
                "FROM STUDENT_DETAILS WHERE ROLL_NUMBER = ?";

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(sql)) {

                ps.setString(1, username);

                try (ResultSet rs = ps.executeQuery()) {

                    if (rs.next()
                            && verifyStudentPassword(
                                password, rs.getString("PASSWORD_HASH"))) {

                        String firstName = rs.getString("FIRST_NAME");

                        session.invalidate();
                        session = request.getSession(true);

                        session.setAttribute("role", "student");
                        session.setAttribute("rollNumber", username);
                        session.setAttribute("firstName", firstName);

                        response.sendRedirect("profile.jsp");
                        return;
                    }
                }

                error = "Invalid username or password.";

            } catch (Exception e) {
                application.log("Login failed.", e);
                error = "Unable to log in right now. Please try again.";
            }
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CampusConnect Login</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: "Segoe UI", Arial, sans-serif;
            background: linear-gradient(135deg, #e0eaff, #f0e7ff, #dff7fa);
            color: #202944;
        }

        .login-card {
            width: 90%;
            max-width: 410px;
            padding: 38px;
            background: rgba(255,255,255,.92);
            border: 1px solid white;
            border-radius: 24px;
            box-shadow: 0 20px 55px rgba(60,75,130,.15);
            animation: appear .45s ease-out;
        }

        .logo {
            width: 62px;
            height: 62px;
            display: grid;
            place-items: center;
            margin: 0 auto 18px;
            border-radius: 18px;
            color: white;
            font-size: 28px;
            background: linear-gradient(135deg,#5b6df5,#9367e9);
        }

        h1 {
            margin: 0;
            text-align: center;
            font-size: 27px;
        }

        .subtitle {
            text-align: center;
            color: #778099;
            font-size: 14px;
            margin: 9px 0 26px;
        }

        label {
            display: block;
            margin: 17px 0 7px;
            font-size: 13px;
            font-weight: 600;
            color: #46516d;
        }

        input {
            width: 100%;
            padding: 13px 14px;
            border: 1px solid #dce2f0;
            border-radius: 11px;
            outline: none;
            background: #f9faff;
            font: inherit;
        }

        input:focus {
            border-color: #7379f5;
            box-shadow: 0 0 0 4px rgba(115,121,245,.13);
        }

        button {
            width: 100%;
            margin-top: 24px;
            padding: 14px;
            border: none;
            border-radius: 11px;
            background: linear-gradient(100deg,#596cf3,#8c64e8);
            color: white;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            transition: transform .2s, box-shadow .2s;
        }

        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 9px 20px rgba(103,103,230,.28);
        }

        .message {
            padding: 11px;
            margin: 14px 0;
            border-radius: 10px;
            text-align: center;
            font-size: 13px;
            background: #e8f8ee;
            color: #207447;
        }

        .error {
            background: #fff0f0;
            color: #b42335;
        }

        .footer {
            text-align: center;
            margin-top: 23px;
            font-size: 13px;
            color: #778099;
        }

        a {
            color: #625de4;
            text-decoration: none;
            font-weight: 600;
        }

        a:hover { text-decoration: underline; }

        @keyframes appear {
            from { opacity: 0; transform: translateY(12px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @media (max-width: 480px) {
            .login-card { padding: 28px 23px; }
        }
    </style>
</head>

<body>
    <main class="login-card">
        <div class="logo">✦</div>
        <h1>Welcome back</h1>
        <p class="subtitle">Sign in to CampusConnect</p>

        <% if ("1".equals(request.getParameter("registered"))) { %>
            <div class="message">
                Registration successful! Please log in.
            </div>
        <% } %>

        <% if ("1".equals(request.getParameter("logout"))) { %>
            <div class="message">
                You have logged out successfully.
            </div>
        <% } %>

        <% if (error != null) { %>
            <div class="message error"><%= error %></div>
        <% } %>

        <form action="login.jsp" method="post">
            <label for="username">Username / Roll Number</label>
            <input
                id="username"
                type="text"
                name="username"
                placeholder="Enter your roll number"
                autocomplete="username"
                required>

            <label for="password">Password</label>
            <input
                id="password"
                type="password"
                name="password"
                placeholder="Enter your password"
                autocomplete="current-password"
                required>

            <button type="submit">Sign In →</button>
        </form>

        <div class="footer">
            New student?
            <a href="signup.html">Create an account</a>
        </div>
    </main>
</body>
</html>