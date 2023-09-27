DELIMITER //
CREATE OR REPLACE PROCEDURE droplike(IN pattern VARCHAR(255))
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE tableName VARCHAR(255);
    DECLARE cur CURSOR FOR SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name LIKE pattern;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO tableName;
        IF done THEN
            LEAVE read_loop;
        END IF;
        SET @sql = CONCAT('DROP TABLE ', tableName);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    CLOSE cur;
END //
DELIMITER ;

use matomo;

DELETE FROM matomo_log_visit;
DELETE FROM matomo_log_link_visit_action;
DELETE FROM matomo_log_conversion;
DELETE FROM matomo_log_conversion_item;

call droplike('matomo_archive_numeric_%');
call droplike('matomo_archive_blob_%');