
<%@ page import="java.sql.*,java.security.*,javax.crypto.SecretKeyFactory,javax.crypto.spec.PBEKeySpec,java.util.Base64" %>
<%@ page import="com.studentapp.util.DBConnection" %>
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>

<%!
    private String hashPassword(String password) throws Exception {
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[16];
        random.nextBytes(salt);

        PBEKeySpec spec = new PBEKeySpec(
            password.toCharArray(), salt, 120000, 256
        );

        try {
            byte[] hash = SecretKeyFactory
                .getInstance("PBKDF2WithHmacSHA256")
                .generateSecret(spec)
                .getEncoded();

            return Base64.getEncoder().encodeToString(salt) + ":"
                 + Base64.getEncoder().encodeToString(hash);
        } finally {
            spec.clearPassword();
        }
    }

    private String value(HttpServletRequest request, String name) {
        String v = request.getParameter(name);
        return v == null ? "" : v.trim();
    }
%>

<%
    request.setCharacterEncoding("UTF-8");

    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("signup.html");
        return;
    }

    String firstName = value(request, "firstName");
    String lastName  = value(request, "lastName");
    String rollNumber = value(request, "rollNumber");
    String password = request.getParameter("password");
    String confirmPassword = request.getParameter("confirmPassword");
    String ageText = value(request, "age");
    String gender = value(request, "gender");
    String mobile = value(request, "mobile");
    String email = value(request, "email");
    String address = value(request, "address");
    String semesterText = value(request, "semester");
    String yearText = value(request, "year");
    String section = value(request, "section");
    String branch = value(request, "branch");

    String error = null;
    int age = 0;
    int semester = 0;
    int studyYear = 0;

    if (firstName.isEmpty() || lastName.isEmpty()
            || rollNumber.isEmpty() || password == null
            || confirmPassword == null || ageText.isEmpty()
            || gender.isEmpty() || mobile.isEmpty()
            || email.isEmpty() || address.isEmpty()
            || semesterText.isEmpty() || yearText.isEmpty()
            || section.isEmpty() || branch.isEmpty()) {
        error = "Please complete all required fields.";
    } else if (!rollNumber.matches("24761A05[0-9]{2}")) {
        error = "Invalid roll number format.";
    } else if (!password.matches("^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{6,15}$")) {
        error = "Password must be 6–15 characters and contain uppercase, lowercase, a number and a special character.";
    } else if (!password.equals(confirmPassword)) {
        error = "Passwords do not match.";
    } else if (!mobile.matches("[0-9]{10}")) {
        error = "Enter a valid 10-digit mobile number.";
    } else {
        try {
            age = Integer.parseInt(ageText);
            semester = Integer.parseInt(semesterText);
            studyYear = Integer.parseInt(yearText);

            if (age < 16 || age > 30) {
                error = "Age must be between 16 and 30.";
            } else if (semester < 1 || semester > 8
                    || studyYear < 1 || studyYear > 4) {
                error = "Invalid semester or study year.";
            }
        } catch (NumberFormatException e) {
            error = "Enter valid numeric values for age, semester and year.";
        }
    }

    if (error == null) {
        String sql = "INSERT INTO STUDENT_DETAILS "
            + "(ROLL_NUMBER, FIRST_NAME, LAST_NAME, PASSWORD_HASH, "
            + "EMAIL, MOBILE, AGE, GENDER, ADDRESS, SEMESTER, "
            + "STUDY_YEAR, SECTION, BRANCH) "
            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, rollNumber);
            ps.setString(2, firstName);
            ps.setString(3, lastName);
            ps.setString(4, hashPassword(password));
            ps.setString(5, email);
            ps.setString(6, mobile);
            ps.setInt(7, age);
            ps.setString(8, gender);
            ps.setString(9, address);
            ps.setInt(10, semester);
            ps.setInt(11, studyYear);
            ps.setString(12, section);
            ps.setString(13, branch);

            ps.executeUpdate();

            response.sendRedirect("login.jsp?registered=1");
            return;

        } catch (SQLException e) {
            application.log("Student registration failed.", e);

            if (e.getErrorCode() == 1) {
                error = "That roll number is already registered.";
            } else {
                error = "Registration failed because of a database error. Check the server console.";
            }
        } catch (Exception e) {
            application.log("Password hashing or registration failed.", e);
            error = "Registration failed. Check the server console.";
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Registration Error | CampusConnect</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #eef6ff;
            display: grid;
            place-items: center;
            min-height: 100vh;
            margin: 0;
        }
        .card {
            background: white;
            padding: 28px;
            border-radius: 12px;
            box-shadow: 0 8px 25px rgba(38,83,130,.12);
            max-width: 420px;
            width: calc(100% - 60px);
            text-align: center;
        }
        .error { color: #b42335; }
        a { color: #1769aa; }
    </style>
</head>
<body>
    <div class="card">
        <h2>Registration Unsuccessful</h2>
        <p class="error"><%= error %></p>
        <p><a href="signup.html">Return to registration</a></p>
    </div>
</body>
</html>
