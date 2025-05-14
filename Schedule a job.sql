-- Create the Notifications table
CREATE TABLE Notifications (
    NotificationID INT AUTO_INCREMENT PRIMARY KEY,
    Message VARCHAR(255),
    ScheduledTime TIME,
    DayOfWeek VARCHAR(10),
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO Notifications (Message, ScheduledTime, DayOfWeek)
VALUES 
('Samosa Time? Do not be shy!', '09:00:00', 'Sunday'),
('Pyar ek bar nahi hota... par icecream roz khayi ja sakti hai!', '15:00:00', 'Saturday'),
('Hot outside? Let us have a coke', '13:00:00', 'Monday');

-- Select from table
SELECT * FROM Notifications;

-- Stored procedure to send today's notifications
DELIMITER $$

CREATE PROCEDURE sp_SendNotificationTemp()
BEGIN
    DECLARE v_Today VARCHAR(10);
    DECLARE v_CurrentTime TIME;

    SET v_Today = DAYNAME(CURDATE());
    SET v_CurrentTime = CURTIME();

    SELECT Message 
    FROM Notifications
    WHERE DayOfWeek = v_Today;
    -- AND ScheduledTime <= v_CurrentTime
    -- AND ScheduledTime >= SUBTIME(v_CurrentTime, '00:01:00');
END$$

DELIMITER ;

-- Call the procedure
CALL sp_SendNotificationTemp();
