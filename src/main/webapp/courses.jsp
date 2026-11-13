
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
    <title>Course Catalogue | CampusConnect</title>
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
        header a { color: white; text-decoration: none; margin-left: 16px; }
        main { max-width: 1100px; margin: 35px auto; padding: 0 20px; }
        .intro { margin-bottom: 24px; }
        .intro p { color: #68738b; }
        .search {
            width: 100%;
            max-width: 400px;
            padding: 12px;
            border: 1px solid #ccd3e0;
            border-radius: 8px;
            margin-bottom: 22px;
            font-size: 15px;
        }
        .courses {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        .course {
            background: white;
            padding: 22px;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(30, 45, 80, .07);
        }
        .course h3 { margin-top: 0; color: #273c75; }
        .description { color: #68738b; min-height: 42px; line-height: 1.5; }
        .details { line-height: 1.9; font-size: 14px; }
        .register {
            width: 100%;
            border: none;
            padding: 11px;
            border-radius: 7px;
            background: #273c75;
            color: white;
            font-size: 15px;
            cursor: pointer;
            margin-top: 10px;
        }
        .register:hover { background: #192a56; }
        .register:disabled { background: #aab2c5; cursor: not-allowed; }
        .message {
            background: #e6f7ed;
            color: #17683a;
            padding: 13px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .error { background: #fdeaea; color: #a32323; }
        .empty { background: white; padding: 25px; border-radius: 10px; }
        @media (max-width: 600px) {
            header { padding: 18px 5%; }
            header a { margin-left: 8px; }
        }
    </style>
</head>
<body>
<header>
    <h2>CampusConnect</h2>
    <nav>
        <a href="profile.jsp">Profile</a>
        <a href="myCourses.jsp">My Courses</a>
        <a href="logout.jsp">Logout</a>
    </nav>
</header>

<main>
    <div class="intro">
        <h1>Course Catalogue</h1>
        <p>Explore available courses and register for the ones you want to study.</p>
    </div>

    <%
        String status = request.getParameter("status");
        if ("success".equals(status)) {
    %>
        <div class="message">Registration successful!</div>
    <%
        } else if ("duplicate".equals(status)) {
    %>
        <div class="message error">You are already registered for this course.</div>
    <%
        } else if ("full".equals(status)) {
    %>
        <div class="message error">Sorry, this course has no available seats.</div>
    <%
        } else if ("error".equals(status)) {
    %>
        <div class="message error">Something went wrong. Please try again.</div>
    <%
        }
    %>

    <input type="text" id="searchBox" class="search"
           placeholder="Search courses by name..."
           oninput="filterCourses()">

    <div class="courses" id="courseList">
    <%
        boolean hasCourses = false;

        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");

            try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
                 PreparedStatement ps = con.prepareStatement(
                     "SELECT COURSE_ID, COURSE_NAME, DESCRIPTION, DURATION, FEE, AVAILABLE_SEATS " +
                     "FROM COURSES ORDER BY COURSE_ID");
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    hasCourses = true;
                    int courseId = rs.getInt("COURSE_ID");
                    String courseName = rs.getString("COURSE_NAME");
                    String description = rs.getString("DESCRIPTION");
                    String duration = rs.getString("DURATION");
                    double fee = rs.getDouble("FEE");
                    int seats = rs.getInt("AVAILABLE_SEATS");
    %>
        <div class="course">
            <h3><%= courseName %></h3>
            <p class="description"><%= description == null ? "" : description %></p>
            <div class="details">
                <div><strong>Duration:</strong> <%= duration %></div>
                <div><strong>Fee:</strong> ₹<%= String.format("%.2f", fee) %></div>
                <div><strong>Available seats:</strong> <%= seats %></div>
            </div>

            <form action="enroll.jsp" method="post">
                <input type="hidden" name="courseId" value="<%= courseId %>">
                <button class="register" type="submit"
                        <%= seats <= 0 ? "disabled" : "" %>>
                    <%= seats <= 0 ? "Course Full" : "Register" %>
                </button>
            </form>
        </div>
    <%
                }
            }
        } catch (Exception e) {
            application.log("Error loading course catalogue", e);
    %>
        <div class="empty">
            Unable to load courses right now. Please try again later.
        </div>
    <%
        }

        if (!hasCourses) {
    %>
        <div class="empty">No courses are available at the moment.</div>
    <%
        }
    %>
    </div>
</main>

<script>
function filterCourses() {
    const query = document.getElementById("searchBox").value.toLowerCase();
    document.querySelectorAll(".course").forEach(function(card) {
        card.style.display =
            card.querySelector("h3").textContent.toLowerCase().includes(query)
                ? "" : "none";
    });
}
</script>
</body>
</html>
