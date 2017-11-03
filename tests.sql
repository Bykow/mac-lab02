call transactions.lire_compte(1010, @solde);
SELECT concat("Solde compte 1: ", @solde);

call transactions.lire_compte(2020, @solde);
SELECT concat("Solde compte 2: ", @solde);

call transactions.lire_compte(3030, @solde);

call transactions.depot_compte(1010, 1000);

call transactions.depot_compte(2020, 2500);

UPDATE compte SET solde = 99999
	WHERE id_compte = 1010;