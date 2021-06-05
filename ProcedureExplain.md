# Example trigger in PL/SQL to save data about DML operations in log table 
```
CREATE OR REPLACE TRIGGER "Nazwa trigera" AFTER INSERT OR DELETE OR UPDATE
ON "Tabela której się tyczy" FOR EACH ROW
BEGIN
    IF INSERTING
        THEN
        INSERT INTO "Nazwa tabeli logów ("kolumny tabeli") VALUES("wartosci");
    END IF;
    IF DELETING
        THEN 
        "TO SAMO CO w IF INSERTING"
    END IF;
    IF UPDATING
        THEN
        "TO SAMO JAK WYZEJ"
    END IF;
END;
/
```
# If we want to insert whole statement 

If you want to save into a trigger for example whole insert statement you should use: 
  - :NEW.your_column_name  ; as a reference to value that is being inserted (usefull during using UPDATE, INSERT)
  - :OLD.your_column_name  ; as a reference to value that already exists in table and there are operations being made on it (You use it during DELETE, UPDATE clasues)
  - CAST("argument_to_be_casted" AS datatype_to_be_casted_to)
  - CONCAT(one_string , second_string) ; you want to concat everything to a single string 

**IMPORTANT** In PL/SQL CONCAT() takes only two arguments, but you can always nest functions so you may do sth like that
```
CONCAT( 'insert into usertype (user_type_id, user_type_name, user_type_description) values (',    <-- here is the first part of text 
CONCAT( CAST(:NEW.USER_TYPE_ID AS CHAR(2)),             <--- here is nested function
CONCAT(CAST(:NEW.USER_TYPE_NAME AS VARCHAR(40)),        <--- here is nested function in nested function
CONCAT(CAST(:NEW.USER_TYPE_DESCRIPTION AS VARCHAR(200)), ');'  ))))  <--- here is nested function in nested function in nested function 
and closing paranthesis as many as there are many nested functions
```
# Whole example Trigger
```
CREATE OR REPLACE TRIGGER DML_USERTYPE AFTER INSERT OR DELETE OR UPDATE
ON USERTYPE FOR EACH ROW
BEGIN
    IF INSERTING
        THEN
        INSERT INTO logging ( TABLE_ASSERTED, EVENT_TYPE, SQL_COMMAND , EVENT_DATE ) 
        VALUES ( 'USERTYPE', 'INSERT',  
        CONCAT( 'insert into usertype (user_type_id, user_type_name, user_type_description) values (', 
        CONCAT(CAST(:NEW.USER_TYPE_ID AS CHAR(2)), 
        CONCAT(CAST(:NEW.USER_TYPE_NAME AS VARCHAR(40)), 
        CONCAT(CAST(:NEW.USER_TYPE_DESCRIPTION AS VARCHAR(200)), ');'  ))))  , sysdate   );
    END IF;
    IF DELETING
        THEN 
        INSERT INTO logging ( TABLE_ASSERTED, EVENT_TYPE, SQL_COMMAND , EVENT_DATE ) 
        VALUES ( 'USERTYPE', 'DELETE', 
        CONCAT('DELETE FROM USERTYPE  WHERE USER_TYPE_ID=', 
        CONCAT(CAST(:OLD.USER_TYPE_ID AS CHAR(3)), ';' ))  , sysdate    );
    END IF;
    IF UPDATING
        THEN
        INSERT INTO logging ( TABLE_ASSERTED, EVENT_TYPE, SQL_COMMAND , EVENT_DATE) 
        VALUES ( 'USERTYPE', 'UPDATE',  
        CONCAT( 'UPDATED USERTYPE (user_type_id, user_type_name, user_type_description) values (', 
        CONCAT(CAST(:NEW.USER_TYPE_ID AS CHAR(2)), 
        CONCAT(CAST(:NEW.USER_TYPE_NAME AS VARCHAR(40)), 
        CONCAT(CAST(:NEW.USER_TYPE_DESCRIPTION AS VARCHAR(200)), ');'  )))) , sysdate    );
    END IF;
END;
/

```
# Conclusions about PL/SQL
<p>If you wish to make a table which holds data about changes made and you want it to hold whole queries/statements 
just better change your engine for example for MYSQL server.</p>
<p>Why should you? </p>
<p> If you want to do that in this way described as above you will make your life harder, because its easy to get yourself lost with all of these enclosings. 
AS you can see in the example, to add 3 columns into INSERT statement I had to create 4x nested CONCAT function, when in MYSQL workbench you could do it in one simple use of the same function
</p>
<h2> Fragment of trigger code in MYSQL WORKBENCH</h2>

```
   ( "USERTYPE", "INSERT", CONCAT(
   "INSERT INTO USERTYPE (USER_TYPE_ID, USER_TYPE_NAME, USER_TYPE_DESCRIPTION) VALUES(",
   CAST(NEW.USER_TYPE_ID AS CHAR), ",",
   CAST(NEW.USER_TYPE_NAME AS CHAR), ",", 
   CAST(NEW.USER_TYPE_DESCRIPTION AS CHAR)," );" ), curdate() );
```
Of course no language is perfect as mentioned mysql workbench doesn't allow you to create trigger one which will suit every case of DML operation in one declaration  of the trigger (or it allows that too but i was too dumb to find info how to do it ;), but that I leave for you to check )
