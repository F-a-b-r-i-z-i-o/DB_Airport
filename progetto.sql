--cancellare schemi e tabelle omonime eventualmente presenti nella base di dati.
DROP SCHEMA IF EXISTS voli CASCADE;
CREATE SCHEMA voli;
SET search_path TO voli;
--La seconda per generare lo schema definendo vincoli opportuni.
CREATE TABLE nazione(
    nome VARCHAR(33) PRIMARY KEY,
    compagnia_bandiera VARCHAR(33) NOT NULL,
    continente VARCHAR(20) NOT NULL,
    UNIQUE(compagnia_bandiera)
);
CREATE TABLE citta(
    nome VARCHAR(33) PRIMARY KEY,
    numero_abitanti INTEGER NOT NULL,
    nazione VARCHAR(33) REFERENCES nazione(nome) ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE TABLE aeroporto(
    codice CHAR(3) PRIMARY KEY,
    nome VARCHAR(33),
    categoria VARCHAR(33),
    citta VARCHAR(33) NOT NULL REFERENCES citta(nome) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE(nome)
);
CREATE TABLE volo(
    codice CHAR(4) PRIMARY KEY, 
    orario_partenza TIME,
    aeroporto_partenza CHAR(3) NOT NULL REFERENCES aeroporto(codice) ON DELETE CASCADE ON UPDATE CASCADE,
    orario_arrivo TIME,
    aeroporto_arrivo CHAR(3) NOT NULL REFERENCES aeroporto(codice) ON DELETE CASCADE ON UPDATE CASCADE,
    compagnia VARCHAR(33) NOT NULL
);
CREATE TABLE sorvolo(
    codice CHAR(4) REFERENCES volo(codice) ON DELETE CASCADE ON UPDATE CASCADE,
    citta VARCHAR(33) REFERENCES citta(nome) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY(codice,citta)
);
CREATE TABLE compagnie(
    compagnia VARCHAR(33) PRIMARY KEY,
    num_voli INTEGER DEFAULT 0
);


/*Ho creato 2 trigger uno aggiungi ed uno elimina per aggiornare la colonna n_voli della tabella compagnie 
ogni qual volta viene inserito o cancellato un volo.
Ho verificato il funzionamento del trigger (aggiungi) andando a inserire il numero di compagnie presenti nella tabella volo
e il numero de rispettivi voli.
Per verificare il funzionamento del trigger rimuovi sono andato a rimuovere tutte le compagnie dalle quali non partiva nessun volo. 
*/
CREATE FUNCTION aggiungi() RETURNS TRIGGER AS $BODY$ 
DECLARE  
BEGIN
    UPDATE compagnie SET num_voli = num_voli + 1 WHERE compagnia = NEW.compagnia; 
    RETURN NEW;
END;
$BODY$ 

LANGUAGE PLPGSQL;
CREATE TRIGGER ta
BEFORE INSERT
ON  volo
FOR EACH ROW 
EXECUTE PROCEDURE aggiungi(); 




CREATE FUNCTION elimina() RETURNS TRIGGER AS $BODY$ 
DECLARE  
BEGIN
    UPDATE compagnie SET num_voli = num_voli - 1 WHERE compagnia = OLD.compagnia; 
    RETURN OLD;
END;
$BODY$ 
LANGUAGE PLPGSQL;

CREATE TRIGGER te
BEFORE DELETE
ON  volo
FOR EACH ROW 
EXECUTE PROCEDURE elimina(); 

/*In questo punto avrei potuto anche popolare il DB con un file esterno ed 
importando i valori da esso ma dovendo inserire poche tuple per relazione ho preferito inserire i valori manualmente.*/

--Popolazione tabella comapagnia per esecuzione trigger 
INSERT INTO compagnie(compagnia) VALUES 
('Alitalia'),
('Iberia'),
('KLM'),
('Air France');

--Popolazione tabella nazione
INSERT INTO nazione(nome, compagnia_bandiera, continente)VALUES
('Italia', 'Alitalia', 'Europa'),
('Spagna', 'Iberia', 'Europa'),
('Olanda', 'KLM', 'Europa'),
('Francia','Air France', 'Europa');
--Popolazione tabella citta'
INSERT INTO citta(nome, numero_abitanti, nazione)VALUES
('Roma', 282, 'Italia'),
('Siviglia', 100, 'Spagna'),
('Amsterdam', 382, 'Olanda'),
('Perugia', 50, 'Italia'),
('Parigi', 250, 'Spagna');
--Popolazione tabella aeroporto
INSERT INTO aeroporto(codice, nome, categoria, citta)VALUES
('CIA', 'Ciampino', 'Civile', 'Roma'),
('SVQ', 'Sevilla', 'Civile', 'Siviglia'),
('AMS', 'Shipol', 'Civile', 'Amsterdam'),
('PEG', 'S.Francesco', 'Civile','Perugia'),
('CDG', 'C. de Gauelle', 'Civile', 'Parigi');
--Popolazione tabella volo
INSERT INTO volo(codice, orario_partenza, aeroporto_partenza, orario_arrivo, aeroporto_arrivo, compagnia)VALUES
('1111', '00:00:30', 'AMS', '02:50:00', 'PEG', 'Alitalia'),
('1112', '09:00:30', 'SVQ', '12:30:00', 'PEG', 'Alitalia'),
('1113', '18:00:30', 'PEG', '21:50:00', 'AMS', 'Alitalia'),
('1114', '12:00:10', 'CIA', '14:35:00', 'AMS', 'Alitalia'),
('1115', '18:00:00', 'CDG', '20:05:00', 'CIA', 'Alitalia'),
('1116', '10:00:00', 'CIA', '12:15:00', 'CDG', 'Air France');
--Popolazione tabella sorvolo
INSERT INTO sorvolo(codice, citta)VALUES
('1111', 'Parigi'),
('1112', 'Roma'),
('1113', 'Parigi'), 
('1114', 'Parigi'),
('1115', 'Perugia'),
('1116', 'Perugia');

--Verifica funzionamento trigger
/*
Trigger Aggiungi. 
Per verificare il funzionamento del trigger aggiungi dopo aver inserito le compagnie e modificato la colonna n_voli, "stampo la tabella".

Trigger Rimuovi.
Per verificare il funzionamento del trigger rimuovi, dopo aver inseirito le compagnie e il numero di voli che corrispondo ad una determinata 
compagnia, scelgo di eliminare le compagnie che non possiedono nessun volo.
Successivamente "stampo l'eliminazione".
*/
SELECT * FROM compagnie;
DELETE FROM compagnie WHERE num_voli = 0;
SELECT * FROM compagnie;

--Determinare i voli che arrivano in un aeroporto situato a Perugia oppure partono da un aereoporto di Roma.
SELECT v.* FROM aeroporto AS a JOIN volo AS v ON v.aeroporto_arrivo = a.codice AND a.citta='Perugia' OR v.aeroporto_partenza = a.codice AND a.citta = 'Roma';
--2 Determinare i voli che non sorvolano alcuna citta’ italiana.
SELECT v.* FROM sorvolo AS s JOIN citta AS c ON s.citta = c.nome JOIN volo AS v ON v.codice = s.codice  WHERE NOT nazione='Italia';
--3 Determinare le compagnie aeree che hanno un volo in partenza da ogni aereoporto memorizzato nella BD.
SELECT compagnia FROM volo GROUP BY compagnia HAVING (COUNT(DISTINCT aeroporto_partenza)) = (SELECT(COUNT(aeroporto.codice))FROM aeroporto);




