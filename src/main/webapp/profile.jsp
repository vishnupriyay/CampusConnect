
<%@ page import="java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet" %>
<%@ page import="com.studentapp.util.DBConnection" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<%
String rollNumber = (String) session.getAttribute("rollNumber");

if (rollNumber == null) {
    response.sendRedirect("login.jsp");
    return;
}

String firstName = "";
String lastName = "";
String email = "";
String branch = "";
int semester = 0;

String sql = "SELECT FIRST_NAME, LAST_NAME, EMAIL, BRANCH, SEMESTER " +
             "FROM STUDENT_DETAILS WHERE ROLL_NUMBER = ?";

try (Connection con = DBConnection.getConnection();
     PreparedStatement ps = con.prepareStatement(sql)) {

    ps.setString(1, rollNumber);

    try (ResultSet rs = ps.executeQuery()) {
        if (rs.next()) {
            firstName = rs.getString("FIRST_NAME");
            lastName = rs.getString("LAST_NAME");
            email = rs.getString("EMAIL");
            branch = rs.getString("BRANCH");
            semester = rs.getInt("SEMESTER");
        } else {
            session.invalidate();
            response.sendRedirect("login.jsp");
            return;
        }
    }
} catch (Exception e) {
    application.log("Unable to load student profile.", e);
    response.sendError(500, "Unable to load student profile.");
    return;
}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Student Profile</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            min-height: 100vh;
            font-family: "Segoe UI", Arial, sans-serif;
            background: #f4f6fc;
            color: #202944;
        }

        header {
            padding: 20px 7%;
            background: white;
            border-bottom: 1px solid #e8ebf4;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
        }

        .brand {
            font-size: 20px;
            font-weight: 800;
            letter-spacing: -0.5px;
        }

        .brand span {
            color: #7067e8;
        }

        .header-tag {
            color: #646e86;
            background: #f0efff;
            padding: 8px 13px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }

        main {
            max-width: 1000px;
            width: 90%;
            margin: 38px auto;
            animation: appear 0.5s ease-out;
        }

        .welcome {
            padding: 30px;
            border-radius: 22px;
            background: linear-gradient(120deg, #596cf3, #9069e8);
            color: white;
            box-shadow: 0 12px 30px rgba(89, 108, 243, 0.18);
        }

        .welcome p {
            margin: 0 0 9px;
            opacity: 0.85;
            font-size: 14px;
        }

        .welcome h1 {
            margin: 0;
            font-size: clamp(25px, 4vw, 34px);
            letter-spacing: -1px;
        }

        .welcome .roll {
            margin-top: 12px;
            font-size: 13px;
        }

        .section-title {
            margin: 30px 0 15px;
            font-size: 19px;
        }

        .profile-card {
            padding: 24px;
            background: white;
            border: 1px solid #e9ecf5;
            border-radius: 18px;
            box-shadow: 0 5px 20px rgba(30, 45, 90, 0.04);
        }

        .details {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 22px;
        }

        .detail-label {
            font-size: 12px;
            color: #858da2;
            margin-bottom: 6px;
        }

        .detail-value {
            font-size: 15px;
            font-weight: 600;
            overflow-wrap: anywhere;
        }

        .menu {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 16px;
        }

        .menu a {
            display: block;
            padding: 22px;
            border-radius: 17px;
            background: white;
            border: 1px solid #e9ecf5;
            color: #283451;
            text-decoration: none;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .menu a:hover {
            transform: translateY(-4px);
            box-shadow: 0 12px 26px rgba(40, 50, 100, 0.09);
        }

        .menu-icon {
            font-size: 25px;
            margin-bottom: 15px;
        }

        .menu strong {
            display: block;
            font-size: 15px;
            margin-bottom: 7px;
        }

        .menu small {
            display: block;
            color: #7b849a;
            line-height: 1.5;
        }

        .logout {
            color: #bd3f54 !important;
        }

        footer {
            text-align: center;
            padding: 25px;
            color: #9299ab;
            font-size: 12px;
        }

        @keyframes appear {
            from {
                opacity: 0;
                transform: translateY(10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        @media (max-width: 650px) {
            header {
                padding: 18px 5%;
            }

            main {
                margin-top: 24px;
            }

            .details {
                grid-template-columns: 1fr;
            }

            .menu {
                grid-template-columns: 1fr;
            }

            .welcome {
                padding: 24px;
            }
        }
    </style>
</head>

<body>

    <header>
        <div class="brand">Campus<span>Connect</span></div>
        <div class="header-tag">STUDENT PORTAL</div>
    </header>

    <main>
        <section class="welcome">
            <p>YOUR STUDENT DASHBOARD</p>
            <h1>Welcome, <%= firstName %> <%= lastName %>!</h1>
            <p class="roll">Roll Number: <%= rollNumber %></p>
        </section>

        <h2 class="section-title">Personal Information</h2>

        <section class="profile-card details">
            <div>
                <div class="detail-label">Full Name</div>
                <div class="detail-value"><%= firstName %> <%= lastName %></div>
            </div>

            <div>
                <div class="detail-label">Roll Number</div>
                <div class="detail-value"><%= rollNumber %></div>
            </div>

            <div>
                <div class="detail-label">Email Address</div>
                <div class="detail-value"><%= email %></div>
            </div>

            <div>
                <div class="detail-label">Branch</div>
                <div class="detail-value"><%= branch %></div>
            </div>

            <div>
                <div class="detail-label">Current Semester</div>
                <div class="detail-value"><%= semester %></div>
            </div>
        </section>

        <h2 class="section-title">Quick Links</h2>

        <section class="menu">
            <a href="courses.jsp">
                <div class="menu-icon">📚</div>
                <strong>Browse Courses</strong>
                <small>Explore available courses and register.</small>
            </a>

            <a href="myCourses.jsp">
                <div class="menu-icon">🎓</div>
                <strong>My Courses</strong>
                <small>View your registered courses.</small>
            </a>

            <a href="logout.jsp" class="logout">
                <div class="menu-icon">↪</div>
                <strong>Log Out</strong>
                <small>Securely end your session.</small>
            </a>
        </section>
    </main>

    <footer>Student Course Registration System</footer>

</body>
</html>
