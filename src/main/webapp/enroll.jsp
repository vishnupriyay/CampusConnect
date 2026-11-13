
<%@ page import="java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
request.setCharacterEncoding("UTF-8");

String rollNumber = (String) session.getAttribute("rollNumber");

if (rollNumber == null) {
    response.sendRedirect("login.jsp");
} else if (!"POST".equalsIgnoreCase(request.getMethod())) {
    response.sendRedirect("courses.jsp");
} else {
    String courseIdText = request.getParameter("courseId");
    int courseId = -1;

    try {
        courseId = Integer.parseInt(courseIdText);
    } catch (NumberFormatException e) {
        courseId = -1;
    }

    if (courseId <= 0) {
        response.sendRedirect("courses.jsp?status=error");
    } else {
        String dbUrl = "jdbc:oracle:thin:@localhost:1521:xe";
        String dbUser = "system";
        String dbPassword = "manager";

        String status = "error";
        Connection con = null;

        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            con = DriverManager.getConnection(dbUrl, dbUser, dbPassword);
            con.setAutoCommit(false);

            int seats = -1;

            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT AVAILABLE_SEATS FROM COURSES WHERE COURSE_ID = ? FOR UPDATE")) {
                ps.setInt(1, courseId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        seats = rs.getInt("AVAILABLE_SEATS");
                    }
                }
            }

            if (seats < 0) {
                status = "error";
                con.rollback();
            } else {
                boolean alreadyRegistered = false;

                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT 1 FROM STUDENT_COURSES WHERE ROLL_NUMBER = ? AND COURSE_ID = ?")) {
                    ps.setString(1, rollNumber);
                    ps.setInt(2, courseId);

                    try (ResultSet rs = ps.executeQuery()) {
                        alreadyRegistered = rs.next();
                    }
                }

                if (alreadyRegistered) {
                    status = "duplicate";
                    con.rollback();
                } else if (seats == 0) {
                    status = "full";
                    con.rollback();
                } else {
                    try (PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO STUDENT_COURSES " +
                            "(REGISTRATION_ID, ROLL_NUMBER, COURSE_ID, REGISTRATION_DATE) " +
                            "VALUES (STUDENT_COURSES_SEQ.NEXTVAL, ?, ?, SYSDATE)")) {
                        ps.setString(1, rollNumber);
                        ps.setInt(2, courseId);
                        ps.executeUpdate();
                    }

                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE COURSES SET AVAILABLE_SEATS = AVAILABLE_SEATS - 1 " +
                            "WHERE COURSE_ID = ? AND AVAILABLE_SEATS > 0")) {
                        ps.setInt(1, courseId);

                        if (ps.executeUpdate() == 1) {
                            con.commit();
                            status = "success";
                        } else {
                            con.rollback();
                            status = "full";
                        }
                    }
                }
            }

        } catch (SQLException e) {
            if (con != null) {
                try {
                    con.rollback();
                } catch (SQLException rollbackError) {
                    application.log("Registration rollback failed", rollbackError);
                }
            }

            application.log("Course registration failed", e);

            if (e.getErrorCode() == 1) {
                status = "duplicate";
            } else {
                status = "error";
            }

        } catch (Exception e) {
            if (con != null) {
                try {
                    con.rollback();
                } catch (SQLException rollbackError) {
                    application.log("Registration rollback failed", rollbackError);
                }
            }

            application.log("Unexpected course registration error", e);
            status = "error";

        } finally {
            if (con != null) {
                try {
                    con.close();
                } catch (SQLException e) {
                    application.log("Database connection close failed", e);
                }
            }
        }

        response.sendRedirect("courses.jsp?status=" + status);
    }
}
%>
