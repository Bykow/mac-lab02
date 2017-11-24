import com.mysql.jdbc.MysqlErrorNumbers;

import java.sql.*;

/**
 * Created on 17.11.17 by Bykow
 */
public class TransferRunnable implements Runnable {
    private int compteFrom;
    private int compteTo;
    private double amount;
    private int iteration;
    private String transferName;
    private String username;
    private String dbName = "transactions";

    public TransferRunnable(int compteFrom, int compteTo, double amount, int iteration, String transferName, String username) throws SQLException {
        this.compteFrom = compteFrom;
        this.compteTo = compteTo;
        this.amount = amount;
        this.iteration = iteration;
        this.transferName = transferName;
        this.username = username;
    }

    public void run() {
        PreparedStatement stmt;
        int counter = 0;

        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/transactions", username, username)) {
            stmt = conn.prepareStatement("call " + dbName + "." + transferName + "(?,?,?)");

            stmt.setInt(1, compteFrom);
            stmt.setInt(2, compteTo);
            stmt.setDouble(3, amount);

            while (iteration > 0) {
                stmt.execute();
                iteration--;
            }
        } catch (SQLException e) {
            if (e.getSQLState().equals("40001")) {
                iteration++;
                counter++;
            }
            System.out.println("FUCKING");

        }

        System.out.println(username + ": " + counter + " interblocages");
    }
}

