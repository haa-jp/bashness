CREATE PROCEDURE RefreshAllProducts  AS

EXECUTE RefreshProducts
EXECUTE RefreshProdImg
EXECUTE RefreshProdPrice
EXECUTE RefreshCategoryUses
GO




/*---------------------------
   RefreshProdImg 
----------------------------*/
CREATE PROCEDURE RefreshProdImg AS
DELETE FROM ProdImg

INSERT INTO ProdImg(itm_id,itm_img1,itm_img2)
SELECT i.itm_id, t.att_path, t.att_path2 
FROM ITEM i
INNER JOIN assignment a ON a.itm_id=i.itm_id
INNER JOIN attachment t ON t.att_id = a.att_id
WHERE t.att_type = 24

update ProdImg
SET itm_img1 = REPLACE(itm_img1, '//192.168.1.5/Attachments/', 'http://67.139.33.138/Attachments/attachments/'),
    itm_img2 = REPLACE(itm_img2, '//192.168.1.5/Attachments/', 'http://67.139.33.138/Attachments/attachments
WHERE itm_img1 LIKE '%192.168.1.5/Attachments/%' OR itm_img2 LIKE '%192.168.1.5/Attachments/%'

 /* select a.* from attach_text a WHERE a.att_text LIKE '%http://64.62.45.138/Attachments/RP%' */

/* change \ to / */
update ProdImg
SET itm_img1 = REPLACE(itm_img1, '\', '/'),
      itm_img2 = REPLACE(itm_img2, '\', '/')
GO



/*---------------------------
   RefreshProdPrice 
----------------------------*/
CREATE PROCEDURE RefreshProdPrice AS
DELETE FROM ProdPrice

INSERT INTO ProdPrice(itm_id, itm_retail, itm_dealer, itm_retail_web )
SELECT itm_id, itm_listprice5, itm_listprice1, itm_listprice5 * .8 
FROM item
INNER JOIN NWS_I5.S108C2BE.APLUS7FNW.ITBAL ON IBITNO = itm_num 
WHERE itm_webflag='N' AND itm_suspflag <> 'S' 
   AND IBWHID = '01'
GO



/*---------------------------
   RefreshProducts 
----------------------------*/
CREATE PROCEDURE dbo.RefreshProducts AS
DELETE FROM Products

INSERT INTO Products (itm_id, itm_name, itm_detail , itm_feat, itm_sku,itm_stock, itm_headline)

SELECT itm_id, i.itm_desc1 +  i.itm_desc2, description_catalog,description_features, itm_num, (IBOHQ1 - IBAQT1), description_headline FROM dbo.item i
INNER JOIN dbo.zproductinfo  ON  itm_num=ROITNO
INNER JOIN NWS_I5.S108C2BE.APLUS7FNW.ITBAL ON IBITNO = itm_num
/* WHERE  i.itm_webflag = 'N' AND i.itm_suspflag <> 'Y' AND IBWHID='01' */
WHERE IBWHID = '01'
PRINT 'Products Table Refreshed'

UPDATE Products  
SET Products.itm_discontinued='N' 
FROM Products 
INNER JOIN item on item.itm_id=Products.itm_id 
WHERE item.itm_webflag<>'Y' 
   AND item.itm_suspflag <> 'Y' 

UPDATE Products  
SET Products.itm_discontinued='Y' 
FROM Products INNER JOIN item on item.itm_id=Products.itm_id 
WHERE item.itm_webflag='Y' 
   OR item.itm_suspflag = 'Y'
GO



/*---------------------------
   Refresg CategoryUsers
----------------------------*/
CREATE PROCEDURE RefreshCategoryuses AS
DELETE FROM categoryuses

INSERT INTO categoryuses(ctg_id, cat_id, ctg_parent)
SELECT ctg_id, cat_id, ctg_parent  
FROM category

UPDATE categoryuses
SET ctg_nws_only = 'N'

UPDATE categoryuses
SET ctg_nws_only = 'Y'
WHERE ctg_id in (SELECT ctg_id FROM category WHERE substring(ctg_name, 1,3) = '**_')
GO

