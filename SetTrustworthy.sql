--:setvar DBName test

set nocount on 
declare @SQL nvarchar(max)
declare @ist bit = 0
declare @owner varbinary(100) = 0x0
select	@ist = is_trustworthy_on ,
		@owner = owner_sid
from	sys.databases 
where	name = DB_NAME()

select DB_NAME(),@ist, @owner
if (@ist = 0)
BEGIN
	set @SQL = '	ALTER DATABASE [' + DB_NAME() + '] SET TRUSTWORTHY ON'
	print @sql
	exec sp_executeSQL @SQL
	print 'Changed trustworthy setting'
END
if (@owner != 0x01)
BEGIN
	set @SQL = 'ALTER AUTHORIZATION ON DATABASE::[' + DB_NAME() + '] TO '  + SUSER_SNAME(0x01)
	print @sql
	exec sp_executeSQL @SQL
	print 'Changed owner'
END
GO
declare @ist bit = 0
declare @owner varbinary(100) = 0x0
select	@ist = is_trustworthy_on ,
		@owner = owner_sid
from	sys.databases 
where	name = DB_NAME()

select DB_NAME(),@ist, @owner
