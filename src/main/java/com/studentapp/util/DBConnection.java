package com.studentapp.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    private static final String URL =
            "jdbc:oracle:thin:@localhost:1521:xe";

    private static final String USERNAME = "system";
    private static final String PASSWORD = "manager";

    public static Connection getConnection() throws SQLException {

        try {
            oracle.jdbc.driver.OracleDriver driver =
                    new oracle.jdbc.driver.OracleDriver();

            DriverManager.registerDriver(driver);

        } catch (SQLException e) {
            throw e;
        }

        return DriverManager.getConnection(
                URL, USERNAME, PASSWORD
        );
    }
}