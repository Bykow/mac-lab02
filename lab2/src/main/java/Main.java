import java.sql.SQLException;

/**
 * Created on 17.11.17 by Bykow
 */
public class Main {
    public static void main(String[] args) throws SQLException {
        int compteA = 1010;
        int compteB = 2020;
        double amount = 50;
        int iteration = 2000;
        String proces = "transfert1";



        Thread t1 = new Thread(new TransferRunnable(compteA, compteB, amount, iteration, proces, "u1"));

        Thread t2 = new Thread(new TransferRunnable(compteB, compteA, amount, iteration, proces, "u2"));

        t1.start();
        t2.start();
    }
}
