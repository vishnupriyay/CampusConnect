
<%@ page import="java.sql.*,java.security.SecureRandom,java.security.spec.KeySpec,javax.crypto.SecretKeyFactory,javax.crypto.spec.PBEKeySpec,java.util.Base64" %>
<%@ page import="com.studentapp.util.DBConnection" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%!
    private String hashPassword(String password) throws Exception {
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);

        KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 120000, 256);
        byte[] hash = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
                .generateSecret(spec).getEncoded();

        return Base64.getEncoder().encodeToString(salt) + ":"
                + Base64.getEncoder().encodeToString(hash);
    }

    private String esc(Object value) {
        if (value == null) return "";
        return value.toString()
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;");
    }
%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");

    if (!"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String section = request.getParameter("section");
    if (!"courses".equals(section) && !"enrollments".equals(section)) {
        section = "students";
    }

    String message = "";
    String error = "";
    String action = request.getParameter("action");

    // Only POST requests may change database records.
    if ("POST".equalsIgnoreCase(request.getMethod()) && action != null) {
        try (Connection con = DBConnection.getConnection()) {

            if ("studentAdd".equals(action)) {
                String roll = request.getParameter("roll");
                String password = request.getParameter("password");
                String first = request.getParameter("first");
                String last = request.getParameter("last");
                String email = request.getParameter("email");

                if (roll == null || !roll.matches("24761A05[0-9]{2}")) {
                    throw new Exception("Roll number must match 24761A05 followed by two digits.");
                }
                if (password == null || password.length() < 8) {
                    throw new Exception("Password must contain at least 8 characters.");
                }
                if (first == null || first.trim().isEmpty()
                        || last == null || last.trim().isEmpty()
                        || email == null || email.trim().isEmpty()) {
                    throw new Exception("First name, last name, and email are required.");
                }

                String sql = "INSERT INTO STUDENT_DETAILS "
                    + "(ROLL_NUMBER,FIRST_NAME,LAST_NAME,PASSWORD_HASH,EMAIL,MOBILE,AGE,GENDER,ADDRESS,SEMESTER,STUDY_YEAR,SECTION,BRANCH) "
                    + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, roll.trim());
                    ps.setString(2, first.trim());
                    ps.setString(3, last.trim());
                    ps.setString(4, hashPassword(password));
                    ps.setString(5, email.trim());
                    ps.setString(6, request.getParameter("mobile"));
                    String age = request.getParameter("age");
                    if (age == null || age.trim().isEmpty()) ps.setNull(7, Types.NUMERIC);
                    else ps.setInt(7, Integer.parseInt(age));
                    ps.setString(8, request.getParameter("gender"));
                    ps.setString(9, request.getParameter("address"));

                    String semester = request.getParameter("semester");
                    if (semester == null || semester.trim().isEmpty()) ps.setNull(10, Types.NUMERIC);
                    else ps.setInt(10, Integer.parseInt(semester));

                    String year = request.getParameter("studyYear");
                    if (year == null || year.trim().isEmpty()) ps.setNull(11, Types.NUMERIC);
                    else ps.setInt(11, Integer.parseInt(year));

                    ps.setString(12, request.getParameter("studentSection"));
                    ps.setString(13, request.getParameter("branch"));
                    ps.executeUpdate();
                }
                message = "Student added successfully.";
                section = "students";
            }

            else if ("studentUpdate".equals(action)) {
                String roll = request.getParameter("roll");
                String first = request.getParameter("first");
                String last = request.getParameter("last");
                String email = request.getParameter("email");

                if (roll == null || !roll.matches("24761A05[0-9]{2}")) {
                    throw new Exception("Invalid roll number.");
                }
                if (first == null || first.trim().isEmpty()
                        || last == null || last.trim().isEmpty()
                        || email == null || email.trim().isEmpty()) {
                    throw new Exception("First name, last name, and email are required.");
                }

                String password = request.getParameter("password");
                String sql;

                if (password != null && !password.isEmpty()) {
                    if (password.length() < 8) {
                        throw new Exception("New password must contain at least 8 characters.");
                    }
                    sql = "UPDATE STUDENT_DETAILS SET FIRST_NAME=?,LAST_NAME=?,EMAIL=?,MOBILE=?,AGE=?,GENDER=?,ADDRESS=?,SEMESTER=?,STUDY_YEAR=?,SECTION=?,BRANCH=?,PASSWORD_HASH=? WHERE ROLL_NUMBER=?";
                } else {
                    sql = "UPDATE STUDENT_DETAILS SET FIRST_NAME=?,LAST_NAME=?,EMAIL=?,MOBILE=?,AGE=?,GENDER=?,ADDRESS=?,SEMESTER=?,STUDY_YEAR=?,SECTION=?,BRANCH=? WHERE ROLL_NUMBER=?";
                }

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, first.trim());
                    ps.setString(2, last.trim());
                    ps.setString(3, email.trim());
                    ps.setString(4, request.getParameter("mobile"));

                    String age = request.getParameter("age");
                    if (age == null || age.trim().isEmpty()) ps.setNull(5, Types.NUMERIC);
                    else ps.setInt(5, Integer.parseInt(age));

                    ps.setString(6, request.getParameter("gender"));
                    ps.setString(7, request.getParameter("address"));

                    String semester = request.getParameter("semester");
                    if (semester == null || semester.trim().isEmpty()) ps.setNull(8, Types.NUMERIC);
                    else ps.setInt(8, Integer.parseInt(semester));

                    String year = request.getParameter("studyYear");
                    if (year == null || year.trim().isEmpty()) ps.setNull(9, Types.NUMERIC);
                    else ps.setInt(9, Integer.parseInt(year));

                    ps.setString(10, request.getParameter("studentSection"));
                    ps.setString(11, request.getParameter("branch"));

                    if (password != null && !password.isEmpty()) {
                        ps.setString(12, hashPassword(password));
                        ps.setString(13, roll);
                    } else {
                        ps.setString(12, roll);
                    }

                    int changed = ps.executeUpdate();
                    if (changed == 0) throw new Exception("Student not found.");
                }

                message = "Student updated successfully.";
                section = "students";
            }

            else if ("studentDelete".equals(action)) {
                String roll = request.getParameter("roll");

                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM STUDENT_DETAILS WHERE ROLL_NUMBER=?")) {
                    ps.setString(1, roll);
                    int changed = ps.executeUpdate();
                    if (changed == 0) throw new Exception("Student not found.");
                }

                message = "Student deleted.";
                section = "students";
            }

            else if ("courseAdd".equals(action)) {
                String name = request.getParameter("courseName");
                if (name == null || name.trim().isEmpty()) {
                    throw new Exception("Course name is required.");
                }

                // Suitable for a small classroom project without a known sequence name.
                // For production, use a database sequence or identity column.
                try (Statement st = con.createStatement();
                     ResultSet rs = st.executeQuery(
                         "SELECT NVL(MAX(COURSE_ID),0)+1 FROM COURSES")) {
                    rs.next();
                    int id = rs.getInt(1);

                    try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO COURSES (COURSE_ID,COURSE_NAME,DESCRIPTION,DURATION,FEE,AVAILABLE_SEATS) VALUES (?,?,?,?,?,?)")) {
                        ps.setInt(1, id);
                        ps.setString(2, name.trim());
                        ps.setString(3, request.getParameter("description"));
                        ps.setString(4, request.getParameter("duration"));

                        String fee = request.getParameter("fee");
                        ps.setBigDecimal(5, new java.math.BigDecimal(
                            fee == null || fee.trim().isEmpty() ? "0" : fee));

                        String seats = request.getParameter("seats");
                        ps.setInt(6, Integer.parseInt(seats));
                        ps.executeUpdate();
                    }
                }

                message = "Course added successfully.";
                section = "courses";
            }

            else if ("courseUpdate".equals(action)) {
                int id = Integer.parseInt(request.getParameter("courseId"));
                String name = request.getParameter("courseName");
                if (name == null || name.trim().isEmpty()) {
                    throw new Exception("Course name is required.");
                }

                try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE COURSES SET COURSE_NAME=?,DESCRIPTION=?,DURATION=?,FEE=?,AVAILABLE_SEATS=? WHERE COURSE_ID=?")) {
                    ps.setString(1, name.trim());
                    ps.setString(2, request.getParameter("description"));
                    ps.setString(3, request.getParameter("duration"));

                    String fee = request.getParameter("fee");
                    ps.setBigDecimal(4, new java.math.BigDecimal(
                        fee == null || fee.trim().isEmpty() ? "0" : fee));

                    ps.setInt(5, Integer.parseInt(request.getParameter("seats")));
                    ps.setInt(6, id);

                    if (ps.executeUpdate() == 0) throw new Exception("Course not found.");
                }

                message = "Course updated successfully.";
                section = "courses";
            }

            else if ("courseDelete".equals(action)) {
                int id = Integer.parseInt(request.getParameter("courseId"));

                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM COURSES WHERE COURSE_ID=?")) {
                    ps.setInt(1, id);
                    if (ps.executeUpdate() == 0) throw new Exception("Course not found.");
                }

                message = "Course deleted.";
                section = "courses";
            }

            else if ("enrollmentAdd".equals(action)) {
                String roll = request.getParameter("roll");
                int courseId = Integer.parseInt(request.getParameter("courseId"));

                // Verify student and course, prevent duplicates, and enforce seat limit.
                con.setAutoCommit(false);
                try {
                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT ROLL_NUMBER FROM STUDENT_DETAILS WHERE ROLL_NUMBER=?")) {
                        ps.setString(1, roll);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) throw new Exception("Student roll number does not exist.");
                        }
                    }

                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT AVAILABLE_SEATS FROM COURSES WHERE COURSE_ID=? FOR UPDATE")) {
                        ps.setInt(1, courseId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) throw new Exception("Course does not exist.");
                            if (rs.getInt("AVAILABLE_SEATS") <= 0) {
                                throw new Exception("No seats are available.");
                            }
                        }
                    }

                    try (PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO STUDENT_COURSES (REGISTRATION_ID,ROLL_NUMBER,COURSE_ID,REGISTRATION_DATE) "
                            + "VALUES ((SELECT NVL(MAX(REGISTRATION_ID),0)+1 FROM STUDENT_COURSES),?,?,SYSDATE)")) {
                        ps.setString(1, roll);
                        ps.setInt(2, courseId);
                        ps.executeUpdate();
                    }

                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE COURSES SET AVAILABLE_SEATS=AVAILABLE_SEATS-1 WHERE COURSE_ID=?")) {
                        ps.setInt(1, courseId);
                        ps.executeUpdate();
                    }

                    con.commit();
                } catch (Exception ex) {
                    con.rollback();
                    throw ex;
                } finally {
                    con.setAutoCommit(true);
                }

                message = "Student enrolled successfully.";
                section = "enrollments";
            }

            else if ("enrollmentDelete".equals(action)) {
                int registrationId = Integer.parseInt(request.getParameter("registrationId"));

                con.setAutoCommit(false);
                try {
                    int courseId = -1;

                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT COURSE_ID FROM STUDENT_COURSES WHERE REGISTRATION_ID=? FOR UPDATE")) {
                        ps.setInt(1, registrationId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) throw new Exception("Registration not found.");
                            courseId = rs.getInt("COURSE_ID");
                        }
                    }

                    try (PreparedStatement ps = con.prepareStatement(
                            "DELETE FROM STUDENT_COURSES WHERE REGISTRATION_ID=?")) {
                        ps.setInt(1, registrationId);
                        ps.executeUpdate();
                    }

                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE COURSES SET AVAILABLE_SEATS=AVAILABLE_SEATS+1 WHERE COURSE_ID=?")) {
                        ps.setInt(1, courseId);
                        ps.executeUpdate();
                    }

                    con.commit();
                } catch (Exception ex) {
                    con.rollback();
                    throw ex;
                } finally {
                    con.setAutoCommit(true);
                }

                message = "Enrollment removed and seat restored.";
                section = "enrollments";
            }

            else {
                throw new Exception("Unknown action.");
            }

        } catch (Exception ex) {
            error = ex.getMessage() == null ? "The operation failed." : ex.getMessage();
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Admin Management | CampusConnect</title>
<style>
    * { box-sizing: border-box; }
    body {
        margin: 0; font-family: Arial, sans-serif;
        background: #f3f5fb; color: #20253a;
    }
    header {
        background: #222b5c; color: white; padding: 22px 5%;
        display: flex; justify-content: space-between; align-items: center;
        gap: 16px; flex-wrap: wrap;
    }
    header h1 { margin: 0; font-size: 24px; }
    header a { color: white; text-decoration: none; }
    main { max-width: 1200px; margin: 28px auto; padding: 0 18px 40px; }
    nav { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 22px; }
    nav a {
        text-decoration: none; padding: 11px 16px; border-radius: 10px;
        background: white; color: #28336e; font-weight: bold;
        border: 1px solid #dfe3f2;
    }
    nav a.active { background: #3949ab; color: white; }
    .panel {
        background: white; border-radius: 15px; padding: 22px;
        margin-bottom: 22px; box-shadow: 0 4px 18px #1b25500b;
        overflow-x: auto;
    }
    h2 { margin-top: 0; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(180px,1fr)); gap: 12px; }
    input, select, textarea {
        width: 100%; padding: 10px; border: 1px solid #d5d9e8;
        border-radius: 8px; font: inherit; background: white;
    }
    textarea { min-height: 70px; resize: vertical; }
    label { display: block; font-size: 13px; font-weight: bold; margin-bottom: 5px; }
    .field { margin-bottom: 12px; }
    button, .button {
        border: 0; padding: 10px 14px; border-radius: 8px;
        background: #3949ab; color: white; cursor: pointer;
        font-weight: bold; text-decoration: none; display: inline-block;
        td button {
    margin-bottom: 8px;
}

td form {
    margin-bottom: 8px;
}

td form button {
    margin-bottom: 0;
}
    }
    button.danger { background: #c62828; }
    button.secondary { background: #596174; }
    table { width: 100%; border-collapse: collapse; min-width: 700px; }
    th, td { text-align: left; padding: 11px; border-bottom: 1px solid #eceef5; vertical-align: top; }
    th { background: #f7f8fc; }
    .notice { padding: 12px 14px; border-radius: 9px; margin-bottom: 18px; }
    .success { background: #e5f7ec; color: #176b3a; }
    .failure { background: #ffebee; color: #a61c2b; }
    .inline-form { display: inline; }
    .small-input { min-width: 120px; }
    .muted { color: #68708a; font-size: 13px; }
</style>
</head>
<body>
<header>
    <h1>CampusConnect · Admin</h1>
    <div>
        <a href="adminDashboard.jsp">Dashboard</a>
        &nbsp; | &nbsp;
        <a href="logout.jsp">Logout</a>
    </div>
</header>

<main>
    <nav>
        <a class="<%= "students".equals(section) ? "active" : "" %>" href="adminManage.jsp?section=students">Students</a>
        <a class="<%= "courses".equals(section) ? "active" : "" %>" href="adminManage.jsp?section=courses">Courses</a>
        <a class="<%= "enrollments".equals(section) ? "active" : "" %>" href="adminManage.jsp?section=enrollments">Enrollments</a>
    </nav>

    <% if (!message.isEmpty()) { %>
        <div class="notice success"><%= esc(message) %></div>
    <% } %>
    <% if (!error.isEmpty()) { %>
        <div class="notice failure"><%= esc(error) %></div>
    <% } %>

    <% if ("students".equals(section)) { %>
    <section class="panel">
        <h2>Add Student</h2>
        <form method="post" action="adminManage.jsp?section=students">
            <input type="hidden" name="action" value="studentAdd">
            <div class="grid">
                <div class="field"><label>Roll Number *</label><input name="roll" required pattern="24761A05[0-9]{2}" placeholder="24761A0511"></div>
                <div class="field"><label>First Name *</label><input name="first" required></div>
                <div class="field"><label>Last Name *</label><input name="last" required></div>
                <div class="field"><label>Email *</label><input name="email" type="email" required></div>
                <div class="field"><label>Password *</label><input name="password" type="password" minlength="8" required></div>
                <div class="field"><label>Mobile</label><input name="mobile" maxlength="10"></div>
                <div class="field"><label>Age</label><input name="age" type="number" min="1" max="99"></div>
                <div class="field"><label>Gender</label><input name="gender"></div>
                <div class="field"><label>Semester</label><input name="semester" type="number" min="1" max="12"></div>
                <div class="field"><label>Study Year</label><input name="studyYear" type="number" min="1" max="6"></div>
                <div class="field"><label>Section</label><input name="studentSection"></div>
                <div class="field"><label>Branch</label><input name="branch"></div>
            </div>
            <div class="field"><label>Address</label><textarea name="address"></textarea></div>
            <button type="submit">Add Student</button>
        </form>
    </section>

    <section class="panel">
        <h2>Student Records</h2>
        <p class="muted">Edit a record below. Leave the password blank to keep the existing password.</p>
        <table>
            <tr><th>Student</th><th>Contact</th><th>Academic Details</th><th>Actions</th></tr>
            <%
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "SELECT ROLL_NUMBER,FIRST_NAME,LAST_NAME,EMAIL,MOBILE,AGE,GENDER,ADDRESS,SEMESTER,STUDY_YEAR,SECTION,BRANCH FROM STUDENT_DETAILS ORDER BY ROLL_NUMBER");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
            %>
            <tr>
                <td>
                    <form method="post" action="adminManage.jsp?section=students">
                        <input type="hidden" name="action" value="studentUpdate">
                        <input type="hidden" name="roll" value="<%= esc(rs.getString("ROLL_NUMBER")) %>">
                        <div class="field"><label>Roll</label><strong><%= esc(rs.getString("ROLL_NUMBER")) %></strong></div>
                        <div class="field"><label>First name</label><input name="first" required value="<%= esc(rs.getString("FIRST_NAME")) %>"></div>
                        <div class="field"><label>Last name</label><input name="last" required value="<%= esc(rs.getString("LAST_NAME")) %>"></div>
                        <div class="field"><label>New password (optional)</label><input name="password" type="password" minlength="8" autocomplete="new-password"></div>
                </td>
                <td>
                        <div class="field"><label>Email</label><input name="email" type="email" required value="<%= esc(rs.getString("EMAIL")) %>"></div>
                        <div class="field"><label>Mobile</label><input name="mobile" value="<%= esc(rs.getString("MOBILE")) %>"></div>
                        <div class="field"><label>Gender</label><input name="gender" value="<%= esc(rs.getString("GENDER")) %>"></div>
                        <div class="field"><label>Address</label><textarea name="address"><%= esc(rs.getString("ADDRESS")) %></textarea></div>
                </td>
                <td>
                        <div class="field"><label>Age</label><input name="age" type="number" min="1" max="99" value="<%= rs.getObject("AGE") == null ? "" : rs.getInt("AGE") %>"></div>
                        <div class="field"><label>Semester</label><input name="semester" type="number" min="1" max="12" value="<%= rs.getObject("SEMESTER") == null ? "" : rs.getInt("SEMESTER") %>"></div>
                        <div class="field"><label>Study Year</label><input name="studyYear" type="number" min="1" max="6" value="<%= rs.getObject("STUDY_YEAR") == null ? "" : rs.getInt("STUDY_YEAR") %>"></div>
                        <div class="field"><label>Section</label><input name="studentSection" value="<%= esc(rs.getString("SECTION")) %>"></div>
                        <div class="field"><label>Branch</label><input name="branch" value="<%= esc(rs.getString("BRANCH")) %>"></div>
                </td>
                <td>
                        <button type="submit">Save Changes</button>
                    </form>
                    <form class="inline-form" method="post" action="adminManage.jsp?section=students" onsubmit="return confirm('Delete this student? The database will reject deletion if enrollments still exist.');">
                        <input type="hidden" name="action" value="studentDelete">
                        <input type="hidden" name="roll" value="<%= esc(rs.getString("ROLL_NUMBER")) %>">
                        <button class="danger" type="submit">Delete</button>
                    </form>
                </td>
            </tr>
            <%      }
                } catch (Exception ex) {
                    out.println("<tr><td colspan='4'>Could not load students: " + esc(ex.getMessage()) + "</td></tr>");
                }
            %>
        </table>
    </section>

    <% } else if ("courses".equals(section)) { %>
    <section class="panel">
        <h2>Add Course</h2>
        <form method="post" action="adminManage.jsp?section=courses">
            <input type="hidden" name="action" value="courseAdd">
            <div class="grid">
                <div class="field"><label>Course Name *</label><input name="courseName" required></div>
                <div class="field"><label>Duration</label><input name="duration" placeholder="e.g. 8 weeks"></div>
                <div class="field"><label>Fee</label><input name="fee" type="number" min="0" step="0.01" value="0"></div>
                <div class="field"><label>Available Seats *</label><input name="seats" type="number" min="0" max="9999" required value="30"></div>
            </div>
            <div class="field"><label>Description</label><textarea name="description"></textarea></div>
            <button type="submit">Add Course</button>
        </form>
    </section>

    <section class="panel">
        <h2>Course Catalogue</h2>
        <table>
            <tr><th>ID</th><th>Course Details</th><th>Fee</th><th>Available Seats</th><th>Actions</th></tr>
            <%
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "SELECT COURSE_ID,COURSE_NAME,DESCRIPTION,DURATION,FEE,AVAILABLE_SEATS FROM COURSES ORDER BY COURSE_ID");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
            %>
            <tr>
                <td><%= rs.getInt("COURSE_ID") %></td>
                <td>
                    <form method="post" action="adminManage.jsp?section=courses">
                        <input type="hidden" name="action" value="courseUpdate">
                        <input type="hidden" name="courseId" value="<%= rs.getInt("COURSE_ID") %>">
                        <div class="field"><label>Name</label><input name="courseName" required value="<%= esc(rs.getString("COURSE_NAME")) %>"></div>
                        <div class="field"><label>Description</label><textarea name="description"><%= esc(rs.getString("DESCRIPTION")) %></textarea></div>
                        <div class="field"><label>Duration</label><input name="duration" value="<%= esc(rs.getString("DURATION")) %>"></div>
                </td>
                <td><input class="small-input" form="" disabled value="<%= rs.getBigDecimal("FEE") == null ? "0" : esc(rs.getBigDecimal("FEE")) %>">
                    <div class="muted">Edit fee below</div>
                    <input name="fee" type="number" min="0" step="0.01" required value="<%= rs.getBigDecimal("FEE") == null ? "0" : esc(rs.getBigDecimal("FEE")) %>">
                </td>
                <td><input name="seats" type="number" min="0" max="9999" required value="<%= rs.getInt("AVAILABLE_SEATS") %>"></td>
                <td>
                        <button type="submit">Save</button>
                    </form>
                    <form method="post" action="adminManage.jsp?section=courses" onsubmit="return confirm('Delete this course? Existing registrations may prevent deletion.');">
                        <input type="hidden" name="action" value="courseDelete">
                        <input type="hidden" name="courseId" value="<%= rs.getInt("COURSE_ID") %>">
                        <button class="danger" type="submit">Delete</button>
                    </form>
                </td>
            </tr>
            <%      }
                } catch (Exception ex) {
                    out.println("<tr><td colspan='5'>Could not load courses: " + esc(ex.getMessage()) + "</td></tr>");
                }
            %>
        </table>
        <p class="muted">When editing a course, ensure the seat count does not become lower than the number of students already enrolled.</p>
    </section>

    <% } else { %>
    <section class="panel">
        <h2>Assign a Student to a Course</h2>
        <form method="post" action="adminManage.jsp?section=enrollments">
            <input type="hidden" name="action" value="enrollmentAdd">
            <div class="grid">
                <div class="field">
                    <label>Student Roll Number *</label>
                    <input name="roll" required pattern="24761A05[0-9]{2}" placeholder="24761A0511">
                </div>
                <div class="field">
                    <label>Course *</label>
                    <select name="courseId" required>
                        <option value="">Select a course</option>
                        <%
                            try (Connection con = DBConnection.getConnection();
                                 PreparedStatement ps = con.prepareStatement(
                                     "SELECT COURSE_ID,COURSE_NAME,AVAILABLE_SEATS FROM COURSES ORDER BY COURSE_NAME");
                                 ResultSet rs = ps.executeQuery()) {
                                while (rs.next()) {
                        %>
                            <option value="<%= rs.getInt("COURSE_ID") %>">
                                <%= esc(rs.getString("COURSE_NAME")) %> — <%= rs.getInt("AVAILABLE_SEATS") %> seats left
                            </option>
                        <%      }
                            } catch (Exception ex) {
                                out.println("<option value=''>Unable to load courses</option>");
                            }
                        %>
                    </select>
                </div>
            </div>
            <button type="submit">Assign Course</button>
        </form>
    </section>

    <section class="panel">
        <h2>All Enrollments</h2>
        <table>
            <tr><th>Registration ID</th><th>Student</th><th>Course</th><th>Registration Date</th><th>Action</th></tr>
            <%
                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "SELECT sc.REGISTRATION_ID,sc.ROLL_NUMBER,sc.COURSE_ID,sc.REGISTRATION_DATE,"
                         + "s.FIRST_NAME,s.LAST_NAME,c.COURSE_NAME "
                         + "FROM STUDENT_COURSES sc "
                         + "JOIN STUDENT_DETAILS s ON s.ROLL_NUMBER=sc.ROLL_NUMBER "
                         + "JOIN COURSES c ON c.COURSE_ID=sc.COURSE_ID "
                         + "ORDER BY sc.REGISTRATION_DATE DESC,sc.REGISTRATION_ID DESC");
                     ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
            %>
            <tr>
                <td><%= rs.getInt("REGISTRATION_ID") %></td>
                <td><%= esc(rs.getString("ROLL_NUMBER")) %><br>
                    <%= esc(rs.getString("FIRST_NAME")) %> <%= esc(rs.getString("LAST_NAME")) %></td>
                <td><%= esc(rs.getString("COURSE_NAME")) %> (#<%= rs.getInt("COURSE_ID") %>)</td>
                <td><%= esc(rs.getTimestamp("REGISTRATION_DATE")) %></td>
                <td>
                    <form method="post" action="adminManage.jsp?section=enrollments" onsubmit="return confirm('Remove this enrollment and restore one seat?');">
                        <input type="hidden" name="action" value="enrollmentDelete">
                        <input type="hidden" name="registrationId" value="<%= rs.getInt("REGISTRATION_ID") %>">
                        <button class="danger" type="submit">Remove</button>
                    </form>
                </td>
            </tr>
            <%      }
                } catch (Exception ex) {
                    out.println("<tr><td colspan='5'>Could not load enrollments: " + esc(ex.getMessage()) + "</td></tr>");
                }
            %>
        </table>
    </section>
    <% } %>
</main>
</body>
</html>
