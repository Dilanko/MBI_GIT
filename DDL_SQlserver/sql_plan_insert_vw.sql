SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE view [dbo].[sql_plan_insert_vw] as

SELECT
		[collection_time]
      ,[server_name]
      ,[session_id]
	  ,plan_xml
  FROM [dbo].[active_query_raw] a
  left outer join sql_plan sp on sp.plan_hash = a.plan_hash













GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE trigger [dbo].[IO_Trig_INS_sql_plan_insert_vw] on [dbo].[sql_plan_insert_vw]
INSTEAD OF INSERT
as
BEGIN
	update active_query_raw	
		set plan_hash = dbo.Fn_hashbytesmax(convert(varchar(max),i.plan_xml), 'md5')
	from active_query_raw a
	inner join inserted i on a.collection_time = i.collection_time and a.server_name = i.server_name and a.session_id = i.session_id

  INSERT INTO sql_plan
              (plan_hash,
               plan_xml)
  SELECT dbo.Fn_hashbytesmax(convert(varchar(max),plan_xml), 'md5'), plan_xml
  FROM   inserted i
  WHERE 
  NOT EXISTS (SELECT *
                     FROM   sql_plan s
                     WHERE s.plan_hash = dbo.Fn_hashbytesmax(convert(varchar(max),i.plan_xml), 'md5'))
END

GO
