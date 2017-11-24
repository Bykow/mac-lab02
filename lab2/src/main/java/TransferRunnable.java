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
    private double soldeBefore;
    private double soldeAfter;

    public TransferRunnable(int compteFrom, int compteTo, double amount, int iteration, String transferName, String username) throws SQLException {
        this.compteFrom = compteFrom;
        this.compteTo = compteTo;
        this.amount = amount;
        this.iteration = iteration;
        this.transferName = transferName;
        this.username = username;

    }

    public void run() {
        PreparedStatement stmt = null;

        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/transactions", username, username)) {
            conn.setAutoCommit(false);
            stmt = conn.prepareStatement("call " + dbName + "." + transferName + "(?,?,?);");

            while (iteration > 0) {

                stmt.setInt(1, compteFrom);
                stmt.setInt(2, compteTo);
                stmt.setDouble(3, amount);

                stmt.executeUpdate();

                conn.commit();

                iteration--;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            if (stmt != null) {
                try {
                    stmt.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}

