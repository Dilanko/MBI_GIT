SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[query_history_vw] as

SELECT [SESSIONID]
      ,[PLANID]
      ,[DBNAME]
      ,[USERNAME]
      ,SQLTEXT
      ,[SUBMIT_TIME]
      ,[END_TIME]
      ,[ESTCOST]
      ,[ESTDISK]
      ,[ESTMEM]
      ,[SNIPPETS]
      ,[RESROWS]
      ,[RESBYTES]
      ,[HOSTNAME]
from query_history q
left outer join sqltext s on s.sqlhash = q.sqlhash
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create trigger IO_Trig_INS_query_history_vw on query_history_vw
INSTEAD OF INSERT
as
BEGIN
	insert into query_history (
	 [SESSIONID]
      ,[PLANID]
      ,[DBNAME]
		,[USERNAME]
		,sqlhash
      ,[SUBMIT_TIME]
      ,[END_TIME]
      ,[ESTCOST]
      ,[ESTDISK]
      ,[ESTMEM]
      ,[SNIPPETS]
      ,[RESROWS]
      ,[RESBYTES]
      ,[HOSTNAME]
	)
	select
		 [SESSIONID]
      ,[PLANID]
      ,[DBNAME]
      ,[USERNAME]
		,dbo.fn_hashbytesMAX(sqltext, 'md5')
      ,[SUBMIT_TIME]
      ,[END_TIME]
      ,[ESTCOST]
      ,[ESTDISK]
      ,[ESTMEM]
      ,[SNIPPETS]
      ,[RESROWS]
      ,[RESBYTES]
      ,[HOSTNAME]
	from inserted

  INSERT INTO sqltext
              (sqlhash,
               sqltext)
  SELECT dbo.Fn_hashbytesmax(sqltext, 'md5'),
         sqltext
  FROM   inserted  
  WHERE sqltext is not null
  and ( NOT EXISTS (SELECT *
                     FROM   sqltext s
                            JOIN inserted i
                              ON s.sqlhash = dbo.Fn_hashbytesmax(i.sqltext,'md5')) )
END






GO
