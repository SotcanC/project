DECLARE @sql NVARCHAR(MAX) = N'';
WITH login_CTE (name, type, sid)
As
(	Select name, type, sid from sys.database_principals 
	where type = 'S' 
	AND name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA','sys')
)
SELECT @sql = @sql + 'ALTER USER '+ a.name +' WITH LOGIN = '+ a.name + '; ' + CHAR(13) + CHAR(10)
FROM login_CTE a
LEFT JOIN sys.server_principals b ON a.sid = b.sid
LEFT JOIN sys.server_principals c ON c.name = a.name
WHERE b.name IS NULL
AND c.NAME IS NOT NULL;
IF (@SQL != '')
BEGIN
	PRINT @sql
	EXEC sp_ExecuteSQL @sql
END
ELSE
	PRINT 'No users need fixing'
GO