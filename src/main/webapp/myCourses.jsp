
<%@ page import="java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String rollNumber = (String) session.getAttribute("rollNumber");

    if (rollNumber == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String dbUrl = "jdbc:oracle:thin:@localhost:1521:xe";
    String dbUser = "system";
    String dbPassword = "manager";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Courses | CampusConnect</title>
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f3f5fb;
            color: #25304a;
        }
        header {
            background: #273c75;
            color: white;
            padding: 20px 7%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }
        header h2 { margin: 0; }
        header a {
            color: white;
            text-decoration: none;
            margin-left: 16px;
        }
        main {
            max-width: 1000px;
            margin: 35px auto;
            padding: 0 20px;
        }
        .intro p { color: #68738b; }
        .table-wrapper {
            background: white;
            border-radius: 12px;
            padding: 20px;
            overflow-x: auto;
            box-shadow: 0 4px 15px rgba(30, 45, 80, .07);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 550px;
        }
        th, td {
            text-align: left;
            padding: 14px 12px;
            border-bottom: 1px solid #e5e9f2;
        }
        th {
            background: #edf1fb;
            color: #273c75;
        }
        .empty {
            background: white;
            padding: 25px;
            border-radius: 10px;
            line-height: 1.6;
        }
        .button {
            display: inline-block;
            margin-top: 20px;
            padding: 11px 18px;
            background: #273c75;
            color: white;
            text-decoration: none;
            border-radius: 7px;
        }
        .button:hover { background: #192a56; }
        @media (max-width: 600px) {
            header { padding: 18px 5%; }
        }
    </style>
</head>
<body>
<header>
    <h2>CampusConnect</h2>
    <nav>
        <a href="profile.jsp">Profile</a>
        <a href="courses.jsp">Course Catalogue</a>
        <a href="logout.jsp">Logout</a>
    </nav>
</header>

<main>
    <div class="intro">
        <h1>My Courses</h1>
        <p>View the courses you have successfully registered for.</p>
    </div>

    <div class="table-wrapper">
        <table>
            <thead>
                <tr>
                    <th>Course Name</th>
                    <th>Duration</th>
                    <th>Fee</th>
                    <th>Registration Date</th>
                </tr>
            </thead>
            <tbody>
            <%
                boolean found = false;

                try {
                    Class.forName("oracle.jdbc.driver.OracleDriver");

                    try (Connection con = DriverManager.getConnection(
                                dbUrl, dbUser, dbPassword);
                         PreparedStatement ps = con.prepareStatement(
                                "SELECT c.COURSE_NAME, c.DURATION, c.FEE, " +
                                "sc.REGISTRATION_DATE " +
                                "FROM STUDENT_COURSES sc " +
                                "JOIN COURSES c ON sc.COURSE_ID = c.COURSE_ID " +
                                "WHERE sc.ROLL_NUMBER = ? " +
                                "ORDER BY sc.REGISTRATION_DATE DESC")) {

                        ps.setString(1, rollNumber);

                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) {
                                found = true;
            %>
                <tr>
                    <td><%= rs.getString("COURSE_NAME") %></td>
                    <td><%= rs.getString("DURATION") %></td>
                    <td>₹<%= String.format("%.2f", rs.getDouble("FEE")) %></td>
                    <td><%= rs.getDate("REGISTRATION_DATE") %></td>
                </tr>
            <%
                            }
                        }
                    }
                } catch (Exception e) {
                    application.log("Error loading registered courses", e);
            %>
                <tr>
                    <td colspan="4">
                        Unable to load your courses right now. Please try again.
                    </td>
                </tr>
            <%
                }

                if (!found) {
            %>
                <tr>
                    <td colspan="4">You haven't registered for any courses yet.</td>
                </tr>
            <%
                }
            %>
            </tbody>
        </table>
    </div>

    <a class="button" href="courses.jsp">Browse More Courses</a>
</main>
</body>
</html>
