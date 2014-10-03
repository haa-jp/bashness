/* Define Variables */

DECLARE @itm_num         varchar(27)
DECLARE @att_text        varchar(4000)
DECLARE @att_name        varchar(200)
DECLARE @date            datetime
DECLARE @itm_id          int
DECLARE @att_id          int
DECLARE @exists          int


/* Set Global Variables */
SET @date = getdate()

/* Update attach_text if exist */
DECLARE cur CURSOR FOR 

SELECT i.itm_id, m.item_number, m.html_desc
FROM nws_groups.dbo.master_items AS m
INNER JOIN cms.dbo.item AS i ON i.itm_num = m.item_number
WHERE m.item_number IS NOT NULL

OPEN cur

FETCH NEXT FROM cur INTO @itm_id, @itm_num, @att_text

WHILE (@@FETCH_STATUS = 0) 

BEGIN 

                IF @att_text IS NOT NULL 

                BEGIN

                                SET @att_id = NULL

                                SET @att_id = (SELECT att_id FROM cms.dbo.attachment WHERE att_name = LTRIM(RTRIM(@itm_num)) + '_' + 'Keyword' + '.txt' AND att_type = 26)

                                IF  @att_id IS NULL

                                BEGIN
          
                                                /* create */        
                                                SET @att_name = LTRIM(RTRIM(@itm_num)) + '_' + 'Keyword' + '.txt'
                                                SET @att_id = (SELECT ctr_attseq FROM cms.dbo.counter WHERE ctr_id = 1) + 1
                                                UPDATE cms.dbo.counter SET ctr_attseq = @att_id WHERE ctr_id = 1

                                                INSERT INTO cms.dbo.attachment VALUES(@att_id,@att_name,'','','',@att_name,'',0,0,26,@date,@date,0)                                

                                                INSERT INTO cms.dbo.attach_text VALUES(@att_id,@att_text,1)

                                                INSERT INTO cms.dbo.assignment VALUES(0,0,@itm_id,@att_id,10,0)                                              

                

                                END

                                ELSE

                                BEGIN

                                                SET @exists = NULL

                                                SET @exists = (SELECT att_id FROM cms.dbo.attach_text WHERE att_id = @att_id AND att_seq = 1)

                                                IF @exists IS NULL

                                                begin

                                                                INSERT INTO cms.dbo.attach_text VALUES(@att_id,@att_text,1)

                                                                SET @exists = NULL

                                                                SET @exists = (SELECT att_id FROM cms.dbo.assignment WHERE cat_id = 0 AND ctg_id = 0 AND itm_id = @itm_id AND att_id = @att_id)

                                                                IF @exists IS NULL INSERT INTO  cms.dbo.assignment VALUES(0,0,@itm_id,@att_id,10,0)                                                                           

                                                END

                                                ELSE /* update attach_text check for assignment */

                                                BEGIN

                                                                update cms.dbo.attach_text SET att_text = @att_text WHERE att_id = @att_id AND att_seq = 1

                                                                SET @exists = NULL

                                                                SET @exists = (SELECT @att_id FROM cms.dbo.assignment WHERE cat_id = 0 AND ctg_id = 0 AND att_id = @att_id AND itm_id = @itm_id)

                                                                IF @exists IS NULL INSERT INTO cms.dbo.assignment VALUES(0,0,@itm_id,@att_id,10,0)             

                                                END

                                END

 

                                                

                                /* update the item updated field for index build */

                                UPDATE cms.dbo.item SET itm_updated = @date WHERE itm_id = @itm_id

 

                END

 
                FETCH NEXT FROM cur INTO @itm_id, @itm_num, @att_text

END 

CLOSE cur 

DEALLOCATE cur
