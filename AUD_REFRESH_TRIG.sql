DROP PROCEDURE IF EXISTS AUD_REFRESH_TRIG;
DELIMITER $$
CREATE PROCEDURE AUD_REFRESH_TRIG(IN tableName VARCHAR(255), IN onInsertTrig BOOLEAN, IN onUpdateTrig BOOLEAN)
BEGIN

/*Setup variables for framework*/
SET @dropPrefix := "DROP TRIGGER IF EXISTS ";
SET @createPrefix := "DELIMITER $$ CREATE TRIGGER ";
SET @insertTriggerName := CONCAT("TRG_AINSERT_",tableName);
SET @updateTriggerName := CONCAT("TRG_AUPDATE_",tableName);
SET @triggerEnd := " END $$ DELIMITER ;";

/*Error for bad configured SP*/
IF (!onInsertTrig and !onUpdateTrig) THEN
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "No trigger updates specified."; 
ELSEIF (select T.TABLE_ID from PCS_REF_TABLE T INNER JOIN PCS_REF_DATAPOINT D ON T.TABLE_ID = D.TABLE_ID WHERE ifnull(D.INACTIVE,FALSE) = FALSE and T.NAME = tableName LIMIT 1) IS NULL THEN 
/*Throws error if nothing to audit*/
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "No Table or Datapoint to Audit."; 
ELSE
	
/*Updates on insert trigger*/
	IF onInsertTrig THEN
		BEGIN
		DECLARE insertFinished INTEGER DEFAULT 0;
		DECLARE insertPart VARCHAR(1000);
		DECLARE insertWhole TEXT DEFAULT "";
		
		/* declare cursor for employee email */
		DEClARE insert_cursor CURSOR FOR  select INSERT_SQL from AUD_REFRESH__SQL_HELPER WHERE TABLE_NAME = tableName;

		/* declare NOT FOUND handler */
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET insertFinished = 1;
		OPEN insert_cursor;

		get_insert: LOOP

		FETCH insert_cursor INTO insertPart;

		/*Exists cursor*/
		IF insertFinished = 1 THEN  LEAVE get_insert; END IF;

		/* build email list */
		SET insertWhole = CONCAT(insertWhole," ",insertPart);

		END LOOP get_insert;
		CLOSE insert_cursor;

		/*Trigger create */
		SET @fullInsertTrigger := CONCAT(
			@dropPrefix,@insertTriggerName,
			"; ",
			@createPrefix,
			@insertTriggerName,
			" AFTER INSERT ON ",
			tableName,
			" FOR EACH ROW BEGIN ",
			insertWhole,
			@triggerEnd);
		SELECT @fullInsertTrigger;
		/*
		PREPARE alterIfNotExists FROM @fullInsertTrigger;
		EXECUTE alterIfNotExists;
		DEALLOCATE PREPARE alterIfNotExists;
		*/
		END;

	END IF;

/*Updates on update trigger */
	IF onUpdateTrig THEN
		BEGIN
		DECLARE updateFinished INTEGER DEFAULT 0;
		DECLARE updatePart VARCHAR(1000);
		DECLARE updateWhole TEXT DEFAULT "";
		
		/* declare cursor for employee email */
		DEClARE update_cursor CURSOR FOR  select UPDATE_SQL from AUD_REFRESH__SQL_HELPER WHERE TABLE_NAME = tableName;

		/* declare NOT FOUND handler */
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET updateFinished = 1;
		OPEN update_cursor;

		get_update: LOOP

		FETCH update_cursor INTO updatePart;

		/*Exists cursor*/
		IF updateFinished = 1 THEN  LEAVE get_update; END IF;

		/* build email list */
		SET updateWhole = CONCAT(updateWhole," ",updatePart);

		END LOOP get_update;
		CLOSE update_cursor;

		/*Trigger create */
		SET @fullUpdateTrigger := CONCAT(
			@dropPrefix,@updateTriggerName,
			"; ",
			@createPrefix,
			@updateTriggerName,
			" AFTER UPDATE ON ",
			tableName,
			" FOR EACH ROW BEGIN ",
			updateWhole,
			@triggerEnd);
		SELECT @fullUpdateTrigger;
		/*
		PREPARE alterIfNotExists FROM @fullUpdateTrigger;
		EXECUTE alterIfNotExists;
		DEALLOCATE PREPARE alterIfNotExists; 
		*/
		END;
	END IF;
	
END IF; 

END$$
DELIMITER ;


