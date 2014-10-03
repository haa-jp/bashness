/* Define Variables */
DECLARE @ATT_NAME	VARCHAR(200)
DECLARE @TODAY		DATETIME
DECLARE @ITM_ID		INT
DECLARE @ATT_ID		INT
DECLARE @COUNTER	INT
DECLARE @RECORD_EXISTS	INT
DECLARE @ATT_PATH	VARCHAR(200)
DECLARE @ATT_PATH2	VARCHAR(200)
DECLARE @IMAGE_NAME     VARCHAR(27)
DECLARE @SEQ		INT		-- #001
DECLARE @count		INT		-- #001

/* Set Global Variables */
SET @TODAY = getdate()

DECLARE cur CURSOR FOR

SELECT itm_id, image_name, att_name, att_path, att_path2 FROM zimages INNER JOIN item ON itm_num = image_name WHERE image_name IS NOT NULL

OPEN cur
FETCH NEXT FROM cur INTO @ITM_ID, @IMAGE_NAME, @ATT_NAME, @ATT_PATH, @ATT_PATH2

WHILE (@@FETCH_STATUS = 0)
BEGIN
	
	IF @IMAGE_NAME IS NOT NULL
	BEGIN

		SET @SEQ = 0	-- #001
		SET @SEQ = (SELECT MAX(seq_num) FROM assignment WHERE att_id = @att_id AND itm_id = @itm_id) + 10 -- #001

		
		SET @ATT_ID = NULL
		SET @ATT_ID = (SELECT att_id FROM attachment WHERE att_name = @ATT_NAME)
		IF  @ATT_ID IS NULL
			BEGIN
   				/* update counter and create an attachment and assignment record */	
				SET @COUNTER = NULL
   				SET @COUNTER = (SELECT ctr_attseq FROM counter WHERE ctr_id = 1)
				SET @COUNTER = @COUNTER + 1
				UPDATE counter SET ctr_attseq = @COUNTER WHERE ctr_id = 1
				SET @ATT_ID = @COUNTER
				
				/* create attachment record */
   				INSERT INTO attachment VALUES(@ATT_ID, @ATT_NAME, @ATT_PATH, @ATT_PATH2, '', @ATT_NAME, '', 1, 0, 24, @TODAY, @TODAY, 0)

-- BEGIN #001
-- If no existing image assignment for this item create as primary
--

				SET @count = 0
				SET @count = (select count(a.att_id) from assignment a
							INNER JOIN attachment b on a.att_id = b.att_id AND b.att_type = 24
							WHERE a.itm_id = @itm_id AND a.cat_id = 0 AND a.ctg_id = 0)
 				
				
				IF @count = 0 INSERT INTO assignment VALUES(0, 0, @ITM_ID, @ATT_ID, @seq, 1)			

-- 
-- Else see if a primary assignment exist create as non primary 
--
				ELSE 
				BEGIN 
					SET @count = 0
					SET @count = (SELECT COUNT(att_id) FROM assignment WHERE itm_id = @itm_id AND asn_primary = 1)
					IF @count <> 0 INSERT INTO assignment VALUES(0, 0, @ITM_ID, @ATT_ID, @seq, 0)
					ELSE INSERT INTO assignment VALUES(0, 0, @ITM_ID, @ATT_ID, @seq, 1)
				END
-- END #001

	
				/* update the item updated field for index build */
				UPDATE item SET itm_updated = @TODAY WHERE itm_id = @ITM_ID
				
 
   			END
	
			ELSE
   			BEGIN
   				/* update attachment path one and two in attachment table */
				UPDATE attachment SET att_path = @ATT_PATH, att_path2 = @ATT_PATH2 WHERE att_id = @ATT_ID


-- BEGIN #001
-- If no existing image assignment for this item create as primary
--

				SET @count = 0
				SET @count = (SELECT count(a.att_id) FROM assignment a
							INNER JOIN attachment b ON a.att_id = b.att_id AND b.att_type = 24
							WHERE a.itm_id = @itm_id AND a.cat_id = 0 AND a.ctg_id = 0)
 				
				
				IF @count = 0 INSERT INTO assignment VALUES(0, 0, @ITM_ID, @ATT_ID, @seq, 1)			

-- 
-- Else see if a primary assignment exist create as non primary 
--
				ELSE 
				BEGIN 
					SET @count = 0
					SET @count = (Select count(att_id) FROM assignment WHERE itm_id = @itm_id AND asn_primary = 1)
					IF @count <> 0
					BEGIN
						SET @RECORD_EXISTS = NULL
   						SET @RECORD_EXISTS = (SELECT att_id FROM assignment WHERE att_id = @ATT_ID AND cat_id = 0 AND ctg_id = 0 AND itm_id = @ITM_ID)
		   				IF @RECORD_EXISTS IS NULL INSERT INTO assignment VALUES(0, 0, @ITM_ID, @ATT_ID, @seq, 0)
					END
					ELSE
					BEGIN
   						SET @RECORD_EXISTS = (SELECT att_id FROM assignment WHERE att_id = @ATT_ID AND cat_id = 0 AND ctg_id = 0 AND itm_id = @ITM_ID)
		   				IF @RECORD_EXISTS IS NULL INSERT INTO assignment VALUES(0, 0, @ITM_ID, @ATT_ID, @seq, 1)
						ELSE UPDATE Assignment Set asn_primary = 1 WHERE itm_id = @itm_id AND att_id = @att_id AND cat_id = 0 AND ctg_id=0
					END

				END
-- END #001

				UPDATE item SET itm_updated = @TODAY WHERE itm_id = @ITM_ID
			END
	END

	FETCH NEXT FROM cur INTO @ITM_ID, @IMAGE_NAME, @ATT_NAME, @ATT_PATH, @ATT_PATH2

END		

CLOSE cur
DEALLOCATE cur


