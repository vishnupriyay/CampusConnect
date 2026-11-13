<%@ page contentType="text/html;charset=UTF-8" %>
<%
    String role = (String) session.getAttribute("role");

    if (!"admin".equals(role)) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Admin Dashboard | CampusConnect</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            min-height: 100vh;
            font-family: "Segoe UI", Arial, sans-serif;
            color: #202944;
            background: linear-gradient(135deg, #e0eaff, #f0e7ff, #dff7fa);
        }

        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
            padding: 22px 6%;
            background: rgba(255, 255, 255, 0.92);
            box-shadow: 0 4px 20px rgba(60, 75, 130, 0.08);
        }

        .brand {
            font-size: 22px;
            font-weight: 800;
        }

        .brand span {
            color: #6b63e8;
        }

        .logout {
            padding: 10px 17px;
            border-radius: 10px;
            background: #fff0f0;
            color: #b42335;
            text-decoration: none;
            font-weight: 700;
        }

        main {
            max-width: 1100px;
            margin: 0 auto;
            padding: 45px 22px;
        }

        .welcome {
            padding: 32px;
            border-radius: 22px;
            color: white;
            background: linear-gradient(120deg, #596cf3, #9367e9);
            box-shadow: 0 15px 35px rgba(103, 103, 230, 0.2);
        }

        .welcome h1 {
            margin: 0 0 10px;
            font-size: clamp(26px, 4vw, 36px);
        }

        .welcome p {
            margin: 0;
            line-height: 1.6;
            opacity: 0.92;
        }

        .section-title {
            margin: 35px 0 18px;
            font-size: 22px;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
            gap: 20px;
        }

        .card {
            display: block;
            padding: 25px;
            border-radius: 18px;
            background: rgba(255, 255, 255, 0.94);
            border: 1px solid white;
            box-shadow: 0 10px 28px rgba(60, 75, 130, 0.08);
            text-decoration: none;
            color: inherit;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .card:hover {
            transform: translateY(-4px);
            box-shadow: 0 15px 32px rgba(60, 75, 130, 0.14);
        }

        .icon {
            display: grid;
            place-items: center;
            width: 48px;
            height: 48px;
            margin-bottom: 16px;
            border-radius: 14px;
            background: #eeedff;
            font-size: 24px;
        }

        .card h3 {
            margin: 0 0 8px;
        }

        .card p {
            margin: 0;
            color: #778099;
            font-size: 14px;
            line-height: 1.6;
        }

        .note {
            margin-top: 28px;
            color: #626d86;
            font-size: 13px;
        }

        @media (max-width: 480px) {
            header {
                padding: 18px 5%;
            }

            main {
                padding: 28px 16px;
            }

            .welcome {
                padding: 25px;
            }
        }
    </style>
</head>

<body>
    <header>
        <div class="brand">Campus<span>Connect</span> · Admin</div>
        <a class="logout" href="logout.jsp">Log out</a>
    </header>

    <main>
        <section class="welcome">
            <h1>Admin Dashboard</h1>
            <p>
                Manage student records, courses, and course registrations
                from one place.
            </p>
        </section>

        <h2 class="section-title">Management</h2>

        <section class="grid">
           <a class="card" href="adminManage.jsp?section=students">
                <div class="icon">👥</div>
                <h3>Manage Students</h3>
                <p>View, add, edit, and delete student records.</p>
            </a>

            <a class="card" href="adminManage.jsp?section=courses">
                <div class="icon">📚</div>
                <h3>Manage Courses</h3>
                <p>View, add, edit, and delete course information.</p>
            </a>

            <a class="card" href="adminManage.jsp?section=enrollments">
                <div class="icon">📝</div>
                <h3>Course Registrations</h3>
                <p>View enrollments and manage student-course assignments.</p>
            </a>
        </section>

        <p class="note">
            Admin access is restricted to authenticated administrator sessions.
        </p>
    </main>
</body>
</html>