package dao;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBConnection {

    private static final String URL ="jdbc:mysql://localhost:3306/s72433_numsolve";
    private static final String DRIVER = "com.mysql.cj.jdbc.Driver";
    private static final String USER = "s72433";
    private static final String PASS = "jOCNoLu5m02i";

    public static Connection getConnection() {
        try {
            Class.forName(DRIVER);
            return DriverManager.getConnection(URL, USER, PASS);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}
