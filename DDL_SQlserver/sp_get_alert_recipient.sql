SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure sp_get_alert_recipient (@target_server nvarchar (128))
as

SELECT email_name 
FROM   target_server_alert_recipient 
WHERE  target_name = @target_server 
UNION 
SELECT email_name 
FROM   target_server_alert_recipient tgt1 
       INNER JOIN target_server ts 
               ON ts.environment = tgt1.target_name 
                  AND ts.server_name = @target_server 
WHERE  NOT EXISTS (SELECT 1 
                   FROM   target_server_alert_recipient 
                   WHERE  target_name = @target_server)   
GO
