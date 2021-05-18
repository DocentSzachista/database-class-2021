
# 
#	 DROP TABEL JEZELI ISTNIEJA
#
DROP TABLE IF EXISTS GROUP_MEMBERSHIP cascade;
DROP TABLE IF EXISTS  ATTENDANCE cascade;
DROP TABLE IF EXISTS LESSON cascade;
DROP TABLE IF EXISTS LESSON_GROUP cascade ;
DROP TABLE IF EXISTS USERS CASCADE;
DROP TABLE IF EXISTS USERTYPE cascade;
DROP TABLE IF EXISTS LOGGING cascade;
#
#    DROP WIDOKOW
#
DROP VIEW IF EXISTS DISPLAY_USERS;
DROP VIEW IF EXISTS DISPLAY_GROUPS;
DROP PROCEDURE IF EXISTS GET_GROUPS;
DROP PROCEDURE IF EXISTS GET_GROUPS_TEACHER;
DROP PROCEDURE IF EXISTS DISPLAY_ATT_FOR_LESSON;
DROP PROCEDURE IF EXISTS DISPLAY_GROUP_INFO_IF_IS_IN;
DROP PROCEDURE IF EXISTS DISPLAY_ATTENDANCE;
DROP PROCEDURE IF EXISTS DISPLAY_LESSON;
DROP PROCEDURE IF EXISTS DISPLAY_USER_INFO;
#
# Tables creation
#
CREATE TABLE USERTYPE (
	USER_TYPE_ID INT(6) NOT NULL UNIQUE AUTO_INCREMENT,
    USER_TYPE_NAME VARCHAR(32) NOT NULL,
    USER_TYPE_DESCRIPTION VARCHAR(200),
    PRIMARY KEY (USER_TYPE_ID)
);
CREATE TABLE USERS (
	USER_ID INT(6) NOT NULL UNIQUE  AUTO_INCREMENT,
	FIRSTNAME VARCHAR(40) NOT NULL,
	LASTNAME VARCHAR(40) NOT NULL,
    PHONE VARCHAR(20) NOT NULL,
    EMAIL VARCHAR(50) NOT NULL,
    USER_TYPE_ID INT(6) NOT NULL,
    PARENT_ID INT(6),
	PRIMARY KEY (USER_ID),
    CONSTRAINT FK_USERTYPE foreign key (USER_TYPE_ID)
    REFERENCES USERTYPE(USER_TYPE_ID) ON DELETE RESTRICT,
    CONSTRAINT FK_PARENT_ID FOREIGN KEY (PARENT_ID)
    REFERENCES USERS(USER_ID) ON DELETE NO ACTION,
    CONSTRAINT UScheckFK_USERTYPE_ID CHECK (USER_TYPE_ID > 0 ),
    CONSTRAINT UScheckPARENT_ID CHECK ( PARENT_ID > 0 )
);
CREATE TABLE LESSON_GROUP (
	GROUP_ID INT(6) NOT NULL UNIQUE  AUTO_INCREMENT,
    GROUP_NAME VARCHAR(30) NOT NULL,
    LESSONS_AMMOUNT INT(3) NOT NULL,
    GROUP_DESCRIPTION VARCHAR(200),
    TEACHER_ID INT(6) NULL,
    PRIMARY KEY (GROUP_ID),
    CONSTRAINT FK_TEACHER_ID FOREIGN KEY (TEACHER_ID)
    REFERENCES USERS(USER_ID), 
    CONSTRAINT LGcheckFKTEACHER_ID CHECK (TEACHER_ID > 0 )
);
CREATE TABLE GROUP_MEMBERSHIP (
	GROUP_MEMBERSHIP_ID INT(6) NOT NULL UNIQUE  AUTO_INCREMENT,
    USER_ID INT(6) NOT NULL,
    GROUP_ID INT(6) NOT NULL,
    PRIMARY KEY (GROUP_MEMBERSHIP_ID),
    CONSTRAINT FK_USER_IN_GROUP FOREIGN KEY (USER_ID)
    REFERENCES USERS(USER_ID),
	CONSTRAINT FK_ASSIGNED_GROUP FOREIGN KEY (GROUP_ID)
    REFERENCES LESSON_GROUP(GROUP_ID),
	CONSTRAINT GMcheckFKGROUP_ID CHECK (GROUP_ID >0),
	CONSTRAINT GMcheckFKUSER_ID CHECK (USER_ID >0)
);
CREATE TABLE LESSON (
	LESSON_ID INT(6) NOT NULL UNIQUE  AUTO_INCREMENT,
    GROUP_ID INT(6) NOT NULL,
	TOPIC VARCHAR(30),
    START_TIME DATETIME NOT NULL,
    END_TIME DATETIME NOT NULL,
	PRIMARY KEY (LESSON_ID),
    CONSTRAINT FK_LESSON_GROUP FOREIGN KEY (GROUP_ID)
    REFERENCES LESSON_GROUP(GROUP_ID),
	CONSTRAINT LEcheckFKGROUP_ID CHECK (GROUP_ID >0 )
);
CREATE TABLE ATTENDANCE (
	ATTENDANCE_ID INT(6) NOT NULL UNIQUE AUTO_INCREMENT,
    LESSON_ID INT(6) NOT NULL,
    STUDENT_ID INT(6) NOT NULL,
    ATTENDED BOOL NOT NULL,
    PRIMARY KEY (ATTENDANCE_ID),
    CONSTRAINT FK_LESSON_ATTENDANCE FOREIGN KEY (LESSON_ID)
    REFERENCES LESSON(LESSON_ID) ON DELETE CASCADE,
    CONSTRAINT FK_STUDENT_ATTENDANCE FOREIGN KEY (STUDENT_ID)
    REFERENCES USERS(USER_ID) ON DELETE CASCADE,
	CONSTRAINT ATcheckFKLESSON_ID CHECK (LESSON_ID >0 ),
	CONSTRAINT ATcheckFKSTUDENT_ID CHECK (STUDENT_ID >0 )
);

CREATE TABLE LOGGING(
	LOG_ID INT(6) NOT NULL UNIQUE AUTO_INCREMENT,
    TABLE_ASSERTED  VARCHAR (60) NOT NULL,
    EVENT_TYPE VARCHAR(15),
    SQL_COMMAND TEXT NOT NULL,
    EVENT_DATE DATETIME NOT NULL
);
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';

#
# VIEWS
#
CREATE VIEW display_users AS
SELECT FIRSTNAME, LASTNAME, PHONE, EMAIL, USER_TYPE_NAME
FROM USERS
NATURAL JOIN USERTYPE ; 
CREATE VIEW DISPLAY_GROUPS AS
SELECT GROUP_NAME, LESSONS_AMMOUNT, GROUP_DESCRIPTION, FIRSTNAME, LASTNAME, PHONE, EMAIL
FROM LESSON_GROUP
JOIN USERS ON LESSON_GROUP.TEACHER_ID = USERS.USER_ID;

#
# Procedura wyswietl info o uzytkowniku 
#
DELIMITER //
CREATE PROCEDURE  DISPLAY_USER_INFO(IN user_id INT )
BEGIN
		SELECT FIRSTNAME, LASTNAME, PHONE, EMAIL, USER_TYPE_NAME , PARENT.FIRSTNAME, PARENT.LASTNAME, PARENT.EMAIL, PARENT.PHONE
		FROM USERS
		NATURAL JOIN USERTYPE
		JOIN USERS AS PARENT ON USERS.PARENT_ID = PARENT.USER_ID
		WHERE USERS.USER_ID = user_id;
END //
DELIMETER ;
#
# Wyswietl lekcje dla danej grupy
#
DELIMITER //
CREATE PROCEDURE  DISPLAY_LESSON(IN wanted_group_id INT )
BEGIN
		SELECT TOPIC, START_TIME, END_TIME
        FROM LESSON
        WHERE GROUP_ID = wanted_group_id;
END //
DELIMETER ;

#
# Procedura wyswietlajaca obecnosci dla danej lekcji
#
DELIMITER //
CREATE PROCEDURE  DISPLAY_ATTENDANCE(IN lesson_id INT )
BEGIN
		SELECT FIRSTNAME, LASTNAME, ATTENDED
        FROM ATTENDANCE
        JOIN USERS USING (USER_ID)
        WHERE LESSON_ID = lesson_id;
END //
DELIMETER ;
#
# Procedura do wyświetlania informacji na temat grupy jeżeli jest sie do niej zapisanym
#
DELIMITER //
CREATE PROCEDURE  DISPLAY_GROUP_INFO_IF_IS_IN(IN id INT )
BEGIN
		SELECT GROUP_NAME, GROUP_DESCRIPTION, AMMOUNT
        FROM LESSON_GROUP
        JOIN GROUP_MEMBERSHIP AS E USING (GROUP_ID)
        WHERE E.USER_ID=id OR LESSON_GROUP.TEACHER_ID = id;
END //
DELIMETER ;
#
# Procedura Wyswietl obecnosc ucznia dla danej lekcji
#
DELIMITER //
CREATE PROCEDURE  DISPLAY_ATT_FOR_LESSON(IN lesson INT, IN id INT )
BEGIN
		SELECT TOPIC, ATTENDED, START_TIME, END_TIME
        FROM ATTENDANCE
        NATURAL JOIN LESSON
        WHERE LESSON_ID = lesson AND USER_ID = id;
END //

DELIMITER ;
#
#  -- Procedura wyswietlenia grup do ktorych zapisany jest nauczyciel
#
DELIMITER //

CREATE PROCEDURE GET_GROUPS_TEACHER(IN id INT )
BEGIN
		SELECT GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT
        FROM LESSON_GROUP
        WHERE TEACHER_ID=id;
END //
DELIMITER ;

#
# procedura do Wyswietlenia grup w których uczen jest przypisany
#
DELIMITER //

CREATE PROCEDURE GET_GROUPS(IN id INT )
BEGIN
		SELECT GROUP_NAME, GROUP_DESCRIPTION, AMMOUNT
        FROM LESSON_GROUP
        JOIN GROUP_MEMBERSHIP AS E USING (GROUP_ID)
        WHERE E.USER_ID=id;
END //
DELIMITER ;


# 	Insertion of user-types
INSERT INTO USERTYPE (USER_TYPE_NAME, USER_TYPE_DESCRIPTION) VALUES("uczen", "Uczestnik zajec przeprowadzanych przez nauczyciela");
INSERT INTO USERTYPE (USER_TYPE_NAME, USER_TYPE_DESCRIPTION) VALUES("admin", "Administrator, który moderuje użytkowników aplikacji");
INSERT INTO USERTYPE (USER_TYPE_NAME, USER_TYPE_DESCRIPTION) VALUES("nauczyciel", "Przeprowadza zajecia w grupach utworzonych przez administratora");

# 	Insertion of users
#Teachers
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Waylon', 'Nowick', 'wnowick0@bluehost.com', '+358 235 145 8426', 3, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Norrie', 'Donnett', 'ndonnett1@canalblog.com', '+230 144 512 9942', 3, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Ginni', 'McEvay', 'gmcevay2@rakuten.co.jp', '+81 187 727 4916', 3, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Melamie', 'Freeman', 'mfreeman3@upenn.edu', '+63 649 105 3642', 3, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Staford', 'Slowey', 'sslowey4@macromedia.com', '+86 238 560 7508', 3, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Candide', 'Murkin', 'cmurkin5@elegantthemes.com', '+86 979 955 1876', 3, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Will', 'Farden', 'wfarden6@blogs.com', '+55 371 712 2162', 3, null);
#admin
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Lorens', 'Mecco', 'lmecco7@skype.com', '+7 891 186 7900', 2, null);

#Students and parents
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Marisa', 'Attenborrow', 'mattenborrow8@meetup.com', '+86 184 560 9830', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Janna', 'Richfield', 'jrichfield9@disqus.com', '+223 247 152 1392', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Adrienne', 'Gerardin', 'agerardina@dagondesign.com', '+86 630 706 3606', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Amelita', 'Gaskal', 'agaskalb@salon.com', '+46 710 336 5847', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Hamlin', 'Rozanski', 'hrozanskic@admin.ch', '+84 532 827 5431', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Layla', 'Argile', 'largiled@tiny.cc', '+55 597 555 9877', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Eba', 'Gilley', 'egilleye@blogtalkradio.com', '+355 834 209 3015', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Phillipp', 'Gallant', 'pgallantf@sitemeter.com', '+51 902 666 5615', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Bern', 'Pharro', 'bpharrog@wikispaces.com', '+94 580 196 0427', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Tiffani', 'Pelchat', 'tpelchath@facebook.com', '+81 164 480 5838', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Erin', 'Briiginshaw', 'ebriiginshawi@washingtonpost.com', '+992 520 198 1647', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Colin', 'Stallworth', 'cstallworthj@indiegogo.com', '+57 501 674 7424', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Xena', 'Sail', 'xsailk@pcworld.com', '+7 422 320 9873', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Nancee', 'Halsey', 'nhalseyl@va.gov', '+62 550 912 7099', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Micaela', 'Munslow', 'mmunslowm@mlb.com', '+46 282 627 6148', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Averell', 'Mellanby', 'amellanbyn@wix.com', '+62 429 535 0993', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Bayard', 'Gile', 'bgileo@dedecms.com', '+351 497 270 9087', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Krishna', 'Colby', 'kcolbyp@jalbum.net', '+358 267 625 5310', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Tymothy', 'Bjerkan', 'tbjerkanq@vistaprint.com', '+34 106 656 9751', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Yolanda', 'Kirsch', 'ykirschr@imdb.com', '+351 905 628 7545', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Beatrisa', 'Baird', 'bbairds@cdc.gov', '+54 341 298 6255', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Jada', 'Chomicki', 'jchomickit@pen.io', '+27 354 819 4429', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Ainslee', 'Worstall', 'aworstallu@berkeley.edu', '+63 396 270 4249', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Quinta', 'Fladgate', 'qfladgatev@moonfruit.com', '+62 801 271 1822', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Shandy', 'Enefer', 'seneferw@dailymail.co.uk', '+62 310 482 0157', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Jacinta', 'MacLise', 'jmaclisex@techcrunch.com', '+235 636 620 9693', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Knox', 'Mulryan', 'kmulryany@sphinn.com', '+62 125 923 3989', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Hailee', 'MacKenney', 'hmackenneyz@amazon.de', '+86 874 781 1393', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Sander', 'Josephov', 'sjosephov10@nifty.com', '+57 524 732 3251', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Rusty', 'Allcorn', 'rallcorn11@histats.com', '+62 162 158 1530', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Conny', 'Soanes', 'csoanes12@histats.com', '+351 919 200 7532', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Dorian', 'Willimont', 'dwillimont13@pcworld.com', '+86 317 379 0359', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Ryley', 'Tutt', 'rtutt14@imgur.com', '+48 531 639 3342', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Anni', 'Geelan', 'ageelan15@columbia.edu', '+33 326 587 6037', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Netti', 'Sergant', 'nsergant16@buzzfeed.com', '+62 919 852 9068', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Celestina', 'Mansour', 'cmansour17@homestead.com', '+63 558 935 6406', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Gray', 'Helks', 'ghelks18@ucoz.com', '+351 698 214 8465', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Kyla', 'Willars', 'kwillars19@nhs.uk', '+387 526 548 9941', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Brandon', 'Comrie', 'bcomrie1a@163.com', '+52 651 220 8700', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Ruthe', 'Arstingall', 'rarstingall1b@hostgator.com', '+86 390 400 9316', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Didi', 'Cardero', 'dcardero1c@intel.com', '+86 909 479 4392', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Tobin', 'Legendre', 'tlegendre1d@zimbio.com', '+86 335 567 3876', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Wenda', 'Issacof', 'wissacof1e@meetup.com', '+63 355 526 9485', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Egor', 'Klimochkin', 'eklimochkin1f@e-recht24.de', '+358 232 314 8465', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Gerti', 'Burdett', 'gburdett1g@feedburner.com', '+86 849 796 6750', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Craggie', 'Voelker', 'cvoelker1h@howstuffworks.com', '+81 227 374 9246', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Pyotr', 'Hakey', 'phakey1i@chronoengine.com', '+62 779 869 1271', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Nerti', 'Rabbitts', 'nrabbitts1j@diigo.com', '+374 509 313 0788', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Benedict', 'Emmison', 'bemmison1k@blogger.com', '+27 514 344 4935', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Zechariah', 'Sweett', 'zsweett1l@soundcloud.com', '+55 435 111 7749', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Michele', 'Norcliffe', 'mnorcliffe1m@tinypic.com', '+52 265 806 1528', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Eulalie', 'Condie', 'econdie1n@mail.ru', '+1 553 770 6672', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Sherilyn', 'Forker', 'sforker1o@comsenz.com', '+7 669 697 7825', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Weider', 'Remon', 'wremon1p@360.cn', '+256 996 569 7325', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Venus', 'Girkin', 'vgirkin1q@amazonaws.com', '+253 554 512 1773', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Clemmie', 'Yitzowitz', 'cyitzowitz1r@multiply.com', '+7 186 416 7425', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Vern', 'Rivaland', 'vrivaland1s@trellian.com', '+86 967 617 1274', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Petronille', 'Duggon', 'pduggon1t@themeforest.net', '+62 477 333 9188', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Gregory', 'Taysbil', 'gtaysbil1u@usnews.com', '+55 476 587 3646', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Marne', 'Baughan', 'mbaughan1v@examiner.com', '+62 216 512 8516', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Don', 'MacFarland', 'dmacfarland1w@wufoo.com', '+53 894 454 4715', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Chantal', 'Matthius', 'cmatthius1x@sohu.com', '+387 921 626 8486', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Berke', 'Hapke', 'bhapke1y@ihg.com', '+502 966 549 5556', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Sanson', 'Dowber', 'sdowber1z@acquirethisname.com', '+502 565 458 9205', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Leonhard', 'Vanner', 'lvanner20@lycos.com', '+62 359 957 4445', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Evered', 'Bibb', 'ebibb21@mozilla.com', '+63 946 349 8018', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Tonnie', 'Vivien', 'tvivien22@amazon.com', '+62 698 257 8471', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Fraze', 'Slator', 'fslator23@reuters.com', '+359 829 653 2303', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Mallory', 'Dibbs', 'mdibbs24@yolasite.com', '+62 158 995 5649', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Christabel', 'Cock', 'ccock25@mozilla.com', '+86 920 226 8924', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Cyrille', 'Leftley', 'cleftley26@hugedomains.com', '+992 128 274 9303', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Krissie', 'Rumbold', 'krumbold27@sfgate.com', '+84 580 363 2383', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Karyn', 'Oxby', 'koxby28@youku.com', '+7 532 316 9683', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Delphinia', 'Stoodale', 'dstoodale29@woothemes.com', '+7 401 136 5996', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Octavia', 'Daugherty', 'odaugherty2a@cnbc.com', '+234 160 384 5248', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Drucill', 'Cudbird', 'dcudbird2b@deliciousdays.com', '+420 716 151 5306', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Goldia', 'Heinschke', 'gheinschke2c@prlog.org', '+225 451 974 8129', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('April', 'Carthew', 'acarthew2d@auda.org.au', '+1 540 241 2569', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Fawnia', 'Colisbe', 'fcolisbe2e@addtoany.com', '+216 338 892 6686', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Davita', 'Dunstan', 'ddunstan2f@gnu.org', '+970 817 121 9502', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Corly', 'McCloughen', 'cmccloughen2g@quantcast.com', '+58 756 226 6952', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Terence', 'Harness', 'tharness2h@myspace.com', '+63 717 302 0363', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Guglielma', 'Osbiston', 'gosbiston2i@merriam-webster.com', '+55 473 449 7313', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Ellynn', 'Higgan', 'ehiggan2j@archive.org', '+963 685 277 2229', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Violette', 'Emes', 'vemes2k@whitehouse.gov', '+62 448 353 8219', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Rosabella', 'Reynolds', 'rreynolds2l@admin.ch', '+253 926 302 8423', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Juliane', 'Pitkethly', 'jpitkethly2m@paypal.com', '+62 241 749 1888', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Josey', 'Veness', 'jveness2n@bigcartel.com', '+86 318 622 0610', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Teddy', 'Firpi', 'tfirpi2o@wikipedia.org', '+7 980 309 4383', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Rodie', 'Clemens', 'rclemens2p@apache.org', '+48 174 617 6355', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Fredek', 'Asple', 'fasple2q@guardian.co.uk', '+62 807 367 9539', 1, null);
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('Frans', 'Ors', 'fors2r@ft.com', '+256 338 185 2787', 1, null);
#	Insertion of Groups

insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('ANGIELSKI B2', 'nec dui luctus rutrum nulla tellus in sagittis dui vel nisl duis ac nibh fusce lacus', 0, 1);
insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('ANGIELSKI B1', 'orci luctus et ultrices posuere cubilia curae nulla dapibus dolor vel est donec odio justo sollicitudin ut suscipit a feugiat et eros vestibulum ac est lacinia nisi venenatis tristique fusce', 0, 2);
insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('ANGIELSKI C1', 'nulla elit ac nulla sed vel enim sit amet nunc viverra dapibus nulla suscipit ligula in lacus curabitur at ipsum ac tellus semper interdum mauris ullamcorper purus sit', 0, 2);
insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('ANGIELSKI C2', 'interdum in ante vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae duis faucibus accumsan odio curabitur convallis duis consequat dui nec nisi volutpat', 0, 2);
insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('NIEMIECKI A0', 'interdum mauris non ligula pellentesque ultrices phasellus id sapien in sapien iaculis congue vivamus metus arcu adipiscing molestie hendrerit at vulputate vitae nisl aenean lectus', 0, 3);
insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('NIEMIECKI A1', 'nullam molestie nibh in lectus pellentesque at nulla suspendisse potenti cras in purus eu magna vulputate luctus cum sociis natoque penatibus et magnis dis', 0, 1);
insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('pede', 'risus semper porta volutpat quam pede lobortis ligula sit amet eleifend pede libero quis orci nullam molestie nibh in lectus pellentesque at', 0, 1);
insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('duis', 'nisl aenean lectus pellentesque eget nunc donec quis orci eget orci vehicula condimentum curabitur in libero ut massa volutpat convallis morbi odio odio elementum eu interdum', 0, 3);
insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('lobortis', 'ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae donec pharetra magna vestibulum aliquet', 0, 2);
insert into LESSON_GROUP (GROUP_NAME, GROUP_DESCRIPTION, LESSONS_AMMOUNT, TEACHER_ID) values ('diam vitae', 'tincidunt in leo maecenas pulvinar lobortis est phasellus sit amet erat nulla tempus vivamus', 0, 3);

# 	GROUP_ MEMBERSHIPS
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (11, 5);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (84, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (80, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (46, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (70, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (93, 9);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (92, 1);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (9, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (85, 9);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (59, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (13, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (23, 1);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (100, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (71, 8);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (59, 9);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (62, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (76, 1);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (56, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (88, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (16, 7);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (33, 4);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (61, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (70, 8);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (12, 8);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (46, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (73, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (94, 5);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (53, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (39, 1);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (32, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (30, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (56, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (87, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (30, 9);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (96, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (27, 8);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (91, 5);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (96, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (40, 9);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (72, 9);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (57, 5);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (84, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (14, 5);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (10, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (63, 7);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (44, 8);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (52, 9);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (89, 7);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (33, 9);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (64, 4);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (30, 4);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (91, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (11, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (61, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (93, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (19, 4);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (92, 5);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (66, 7);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (47, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (55, 1);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (90, 7);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (23, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (68, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (56, 4);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (76, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (92, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (39, 1);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (41, 8);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (30, 9);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (79, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (75, 7);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (86, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (40, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (52, 8);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (87, 10);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (74, 1);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (38, 5);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (74, 5);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (10, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (32, 7);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (75, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (77, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (99, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (54, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (49, 8);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (18, 3);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (69, 4);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (19, 2);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (76, 6);
insert into GROUP_MEMBERSHIP (USER_ID, GROUP_ID) values (50, 6);

#  CALL GET_GROUPS_TEACHER(1);

/*
*
*Sekcja na akcje UPDATE/ DELETE I WIDOKI
*
*/
UPDATE USERS SET FIRSTNAME = "Damian" WHERE USER_ID=1;
UPDATE USERTYPE SET USER_TYPE_NAME = "Administrator" WHERE USER_TYPE_ID = 2;
insert into users (FIRSTNAME, LASTNAME, EMAIL, PHONE, USER_TYPE_ID, PARENT_ID) values ('JAN', 'KOWALSKI', 'lmecco7@skype.com', '+7 891 186 7900', 2, null);
DELETE FROM USERS WHERE USER_ID =101 ;
INSERT INTO USERTYPE (USER_TYPE_NAME, USER_TYPE_DESCRIPTION) VALUES("nauczyciel", "Przeprowadza zajecia w grupach utworzonych przez administratora");
DELETE FROM USERTYPE WHERE user_type_id = 4;