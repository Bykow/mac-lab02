DROP SCHEMA IF EXISTS transactions;
CREATE SCHEMA transactions;

USE transactions;

CREATE TABLE client (
	id_client int(11) NOT NULL AUTO_INCREMENT,
    nom varchar(30),
	PRIMARY KEY (id_client)
);

CREATE TABLE compte (
  id_compte int(11) NOT NULL AUTO_INCREMENT,
  numero varchar(30) UNIQUE,
  solde float DEFAULT 0,
  min_autorise float DEFAULT 0,
  max_retrait_journalier float DEFAULT 1000,
  blocage boolean DEFAULT FALSE,
  PRIMARY KEY (id_compte)
);

CREATE TABLE compte_client(
	id_client int(11),
    id_compte int(11),
    proprietaire boolean DEFAULT FALSE,
	droit_lecture_ecriture int(11) DEFAULT 2,
    PRIMARY KEY (id_client, id_compte),
    FOREIGN KEY (id_client) REFERENCES client(id_client),
    FOREIGN KEY (id_compte) REFERENCES compte(id_compte)
);

CREATE TABLE journal(
	id_log int(11) NOT NULL AUTO_INCREMENT,
    date_heure TIMESTAMP,
    id_client int (11),
    id_compte int (11),
    type_operation tinyint(4),
    autorisation tinyint(4),
    etat_compte_initial float DEFAULT 0,
    etat_compte_resultat float DEFAULT 0,
    PRIMARY KEY (id_log)
);


DELIMITER //
CREATE TRIGGER suppression_compte
BEFORE DELETE ON compte FOR EACH ROW
BEGIN
	IF (solde > 0.0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PAS POSSIBLE, SOLDE SUPERIEUR A 0!';
	else
		INSERT into journal(date_heure, id_compte, type_operation, autorisation)
        VALUES (NOW(), OLD.id_compte, 2, 5);
	END IF;
END //
DELIMITER ;

DELIMITER //
DROP PROCEDURE IF EXISTS lire_compte //
CREATE PROCEDURE lire_compte(in numero_compte int(11), out etat float)
BEGIN
	
    DECLARE username varchar(30);
    DECLARE id_username int(11);
	DECLARE id_compte_depot int(11);
    DECLARE droits int(11);
    
    SELECT SUBSTRING_INDEX(user(), '@', 1) into username;
    
    SELECT id_client into id_username
    FROM client 
		WHERE client.nom = username;
        
	SELECT id_compte into id_compte_depot
    FROM compte
		WHERE numero_compte = numero;
        
	SELECT droit_lecture_ecriture into droits
    FROM compte_client
		WHERE id_compte = id_compte_depot AND id_client = id_username;
			 
    IF (droits >= 1) THEN
		SELECT solde into etat
		FROM compte 
			WHERE id_compte = id_compte_depot;
		
        INSERT into journal(date_heure, id_client, id_compte, type_operation, autorisation)
			VALUES(NOW(), id_username, id_compte_depot, 0, 0);
	ELSE
		INSERT into journal(date_heure, id_client, id_compte, type_operation, autorisation)
			VALUES(NOW(), id_username, id_compte_depot, 0, 3);
            
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PAS POSSIBLE, PAS LES DROITS!';
	END IF;
END //
DELIMITER ;

DELIMITER //
DROP PROCEDURE IF EXISTS depot_compte //
CREATE PROCEDURE depot_compte(in numero_compte int(11), in depot float)
BEGIN
	
    DECLARE username varchar(30);
    DECLARE id_username int(11);
    DECLARE id_compte_depot int(11);
    DECLARE droits int(11);
    DECLARE solde_curr float;
    
    SELECT SUBSTRING_INDEX(user(), '@', 1) into username;
    
    SELECT id_client into id_username
    FROM client 
		WHERE client.nom = username;
        
	SELECT id_compte into id_compte_depot
    FROM compte
		WHERE numero_compte = numero;

	SELECT droit_lecture_ecriture into droits
    FROM compte_client
		WHERE id_username = id_client AND id_compte = id_compte_depot;
     
	SELECT solde into solde_curr
	FROM compte
		WHERE id_compte = id_compte_depot;
             
    IF (droits >= 2.0) THEN
		
        INSERT into journal(date_heure, id_client, id_compte, type_operation, autorisation, etat_compte_initial, etat_compte_resultat)
			VALUES(NOW(), id_username, id_compte_depot, 1, 0, solde_curr, solde_curr + depot);
            
		UPDATE compte
			SET solde = depot + solde
			WHERE id_compte = id_compte_depot;

	ELSE
		INSERT into journal(date_heure, id_client, id_compte, type_operation, autorisation, etat_compte_initial, etat_compte_resultat)
			VALUES(NOW(), id_username, id_compte_depot, 1, 4, solde_curr, solde_curr);
            
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PAS POSSIBLE, PAS LES DROITS!';
	END IF;
END //
DELIMITER ;


CREATE USER IF NOT EXISTS 'admin1234'@'localhost' IDENTIFIED BY 'nimda';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost';

CREATE USER IF NOT EXISTS 'u1'@'%' IDENTIFIED BY 'u1';
CREATE USER IF NOT EXISTS 'u2'@'%' IDENTIFIED BY 'u2';
CREATE USER IF NOT EXISTS 'u3'@'%' IDENTIFIED BY 'u3';

INSERT into client(nom) VALUES ('u1');
INSERT into client(nom) VALUES ('u2');
INSERT into client(nom) VALUES ('u3');

INSERT into compte(numero, solde) VALUES (1010, 10000);
INSERT into compte(numero, solde) VALUES (2020, 50000);
INSERT into compte(numero, solde) VALUES (3030, 100000);

INSERT into compte_client(id_client, id_compte, proprietaire, droit_lecture_ecriture) VALUES (1,1,true,2);
INSERT into compte_client(id_client, id_compte, proprietaire, droit_lecture_ecriture) VALUES (2,2,true,2);
INSERT into compte_client(id_client, id_compte, proprietaire, droit_lecture_ecriture) VALUES (1,2,false,1);
INSERT into compte_client(id_client, id_compte, proprietaire, droit_lecture_ecriture) VALUES (2,3,false,0);

GRANT EXECUTE ON PROCEDURE transactions.lire_compte TO 'u1'@'%';
GRANT EXECUTE ON PROCEDURE transactions.depot_compte TO 'u1'@'%';
GRANT EXECUTE ON PROCEDURE transactions.lire_compte TO 'u2'@'%';
GRANT EXECUTE ON PROCEDURE transactions.depot_compte TO 'u2'@'%';
GRANT EXECUTE ON PROCEDURE transactions.lire_compte TO 'u3'@'%';
GRANT EXECUTE ON PROCEDURE transactions.depot_compte TO 'u3'@'%';