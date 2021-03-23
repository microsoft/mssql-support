/*
Login - the name of the login for which you want to check permissions.
GrantOrDeny - 0: show only DENY; 1: show only GRANT; NULL: show both (default)

The stored proc will attempt to impersonate the provide login for the purpose of
enumerating Windows groups to which that login belongs. If unable to complete 
impersonation, an error will be raised and execution will continue. 

Example:
The below will get only DENY info for login 'MyDomain\bob' and groups/roles 
to which 'MyDomain\bob' is a member.

EXEC sp_GetPermsInfo @Login = 'MyDomain\bob', @GrantOrDeny = 0
*/
CREATE OR ALTER PROCEDURE sp_GetPermsInfo (@Login SYSNAME, @GrantOrDeny BIT = NULL)
AS BEGIN

       SET NOCOUNT ON;

       DECLARE 
           @LoginPrinID INT
         , @SID VARBINARY(32)
         , @CurDB SYSNAME
         , @QueryText NVARCHAR(1024)
         , @Err VARCHAR(512)
       --Do nothing if login doesn't exist
       IF(NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @Login))
       BEGIN
              SET @Err = 'No login found with name: ' + @Login
              RAISERROR(@Err, 15, 1)
              RETURN -1
       END

       --By creating this even if not needed (as opposed to single variable if not Win Login), 
       --we avoid having to do a ton of additional scripting for conditional logic later
       CREATE TABLE #LoginAndGroupInfo
       (
                [name] SYSNAME
              , [principal_id] INT
              , [sid] VARBINARY(64)
       )


       BEGIN TRY
              EXECUTE AS LOGIN = @Login

              --@Login member of any Windows group listed that isn't @Login itself
              INSERT INTO #LoginAndGroupInfo([name], [principal_id], [sid])
              SELECT DISTINCT p.[name], p.[principal_id], p.[sid]
              FROM sys.server_principals p
                     LEFT JOIN [sys].[login_token] t ON t.[sid] = p.[sid]
              WHERE (t.[principal_id] IS NULL AND p.[name] = @Login)
                     OR t.[name] = @Login
                     OR (t.[principal_id] > 0 AND t.[type] = 'WINDOWS GROUP');
       END TRY
       BEGIN CATCH
              --If we can't impersonate, we won't get any Windows groups info, but still need to get login...
              INSERT INTO #LoginAndGroupInfo([name], [principal_id], [sid])
              SELECT [name], [principal_id], [sid]
              FROM [sys].[server_principals]
              WHERE [name] = @Login

              SET @Err = 'Unable to impersonate login ' + @Login + '. Results may be incomplete.';
              RAISERROR(@Err, 15, 1);
              GOTO Post_Impersonation_Attempt;
       END CATCH


       Post_Impersonation_Attempt:

       REVERT;


       --Get Server Role Membership Info
       SELECT l.name [Login], p.name [ServerRole]
       INTO #ServerRoleMemberships
       FROM [sys].[server_principals] p
              JOIN [sys].[server_role_members] m ON m.[role_principal_id] = p.[principal_id]
              JOIN #LoginAndGroupInfo l ON l.[principal_id] = m.[member_principal_id]
       
	   --Always check public
	   INSERT INTO #ServerRoleMemberships(Login, ServerRole)
	   SELECT @Login, 'Public'
       
       --Get Server Permission Info
       SELECT 
                l.[name]
              , [class_desc] [Class]
              , [permission_name] [Permission]
              , [state_desc] [State]
       INTO #ServerPerms
       FROM [sys].[server_permissions] p
              JOIN #LoginAndGroupInfo l ON l.[principal_id] = p.[grantee_principal_id]

	   --Also for server roles of which this login is a member
	   INSERT INTO #ServerPerms([name], [Class], [Permission], [State])
	   SELECT p.[name], m.[class_desc], m.[permission_name], m.[state_desc]
	   FROM [sys].[server_permissions] m
		JOIN [sys].[server_principals] p ON p.[principal_id] = m.[grantee_principal_id]
		JOIN #ServerRoleMemberships r ON r.[ServerRole] = p.[name]


       --Get List of Databases
       SELECT [name]
       INTO #Databases
       FROM [sys].[databases]


       --Setup for loop to get DB info
       CREATE TABLE #DBRoleMembership
       (
                [Database] SYSNAME
              , [Login] SYSNAME
              , [User] SYSNAME
              , [DBRole] SYSNAME
       )

       CREATE TABLE #DBPerms
       (
                [Database] SYSNAME
              , [Login] SYSNAME
              , [User] SYSNAME
              , [Class] NVARCHAR(50)
              , [Permission] NVARCHAR(256)
              , [State] NVARCHAR(16)
       )


       --Loop over all databases, getting DB Role & permissions info from each
       SELECT TOP(1) @CurDB = [name]
       FROM #Databases

       WHILE(@CurDB IS NOT NULL)
       BEGIN
              SET @QueryText = 'INSERT INTO #DBRoleMembership ([Database], [Login], [User], [DBRole])' + CHAR(10)
                     + 'SELECT ''' + @CurDB + ''', l.[name], u.[name], r.[name]' + CHAR(10)
                     + 'FROM ['+@CurDB+'].[sys].[database_principals] u' + CHAR(10)
                     + '    JOIN ['+@CurDB+'].[sys].[database_role_members] m ON m.[member_principal_id] = u.[principal_id]' + CHAR(10)
                     + '    JOIN ['+@CurDB+'].[sys].[database_principals] r ON r.[principal_id] = m.[role_principal_id]' + CHAR(10)
                     + '    JOIN #LoginAndGroupInfo l ON l.[sid] = u.[sid];' + CHAR(10) + CHAR(10)
					 --Always include public
					 + 'INSERT INTO #DBRoleMembership ([Database], [Login], [User], [DBRole])'
					 + 'SELECT ''' + @CurDB + ''', ''' + @Login + ''', ''N\A'', ''public''' + CHAR(10)

              EXEC(@QueryText)

              SET @QueryText = 'INSERT INTO #DBPerms([Database], [Login], [User], [Class], [Permission], [State])' + CHAR(10)
                     + 'SELECT ''' + @CurDB + ''', l.[name], u.[name], p.[class_desc], p.[permission_name], p.[state_desc]' + CHAR(10)
                     + 'FROM ['+@CurDB+'].[sys].[database_principals] u' + CHAR(10)
                     + '    JOIN ['+@CurDB+'].[sys].[database_permissions] p ON u.[principal_id] = p.[grantee_principal_id]' + CHAR(10)
                     + '    JOIN #LoginAndGroupInfo l ON l.[sid] = u.[sid]' + CHAR(10)

              EXEC(@QueryText)

			  --Include permissions for roles
			  SET @QueryText = 'INSERT INTO #DBPerms([Database], [Login], [User], [Class], [Permission], [State])' + CHAR(10)
                     + 'SELECT ''' + @CurDB + ''', l.[Login], u.[name], p.[class_desc], p.[permission_name], p.[state_desc]' + CHAR(10)
                     + 'FROM ['+@CurDB+'].[sys].[database_principals] u' + CHAR(10)
                     + '    JOIN ['+@CurDB+'].[sys].[database_permissions] p ON u.[principal_id] = p.[grantee_principal_id]' + CHAR(10)
                     + '    JOIN #DBRoleMembership l ON l.[DBRole] = u.[name]' + CHAR(10)

              EXEC(@QueryText)

              DELETE FROM #Databases 
              WHERE [name] = @CurDB

              SET @CurDB = NULL

              SELECT TOP(1) @CurDB = [name]
              FROM #Databases
       END

       --From here down it's just printing the results.
       IF (EXISTS(SELECT 1 FROM #ServerPerms WHERE [State] = 'DENY')
              OR EXISTS(SELECT 1 FROM #DBPerms WHERE [State] = 'DENY'))
			AND (@GrantOrDeny <> 1 OR @GrantOrDeny IS NULL)
       BEGIN
              SELECT DISTINCT '**** SERVER PERMISSION: ' + [Permission] COLLATE SQL_Latin1_General_CP1_CI_AS  + ' HAS BEEN DENIED****'
              FROM #ServerPerms
              WHERE [State] = 'DENY'
              UNION ALL 
              SELECT DISTINCT '**** DATABASE PERMISSION: ' + [Permission] COLLATE SQL_Latin1_General_CP1_CI_AS + ' HAS BEEN DENIED****'
              FROM #DBPerms
              WHERE [State] = 'DENY'
              
       END

       IF EXISTS (SELECT 1 FROM #DBRoleMembership WHERE [DBRole] LIKE '%DENY%')
		AND (@GrantOrDeny <> 1 OR @GrantOrDeny IS NULL)
       BEGIN
              SELECT '**** IS MEMBER OF ' + [DBRole] + ' IN DATABASE ' + [Database] + '****'
              FROM #DBRoleMembership 
              WHERE [DBRole] LIKE '%DENY%'
       END

       IF EXISTS(SELECT 1 FROM #ServerRoleMemberships)
       BEGIN
              SELECT '' [Server Role Membership:]
              SELECT *
              FROM #ServerRoleMemberships
              ORDER BY [ServerRole]
       END
       ELSE BEGIN
              SELECT 'Not a member of any server roles'
       END

       IF EXISTS(SELECT 1 FROM #ServerPerms)
       BEGIN
              SELECT '' [Explicit Server Permissions:]
              SELECT *
              FROM #ServerPerms 
			  WHERE [State] LIKE 
				CASE 
					WHEN @GrantOrDeny = 0 THEN 'DENY' 
					WHEN @GrantOrDeny = 1 THEN 'GRANT'
					ELSE '%' 
				END
              ORDER BY [State], [Class], [Permission]
       END
       ELSE BEGIN
              SELECT 'No explicit server permissions set'
       END

       IF EXISTS(SELECT 1 FROM #DBRoleMembership)
       BEGIN
              SELECT '' [Database Role Memberships:]
              SELECT DISTINCT *
              FROM #DBRoleMembership
              ORDER BY [Database], [User], [DBRole]
       END
       ELSE BEGIN
              SELECT 'Not mapped to any user which is a member of a database role'
       END

       IF EXISTS(SELECT 1 FROM #DBPerms)
       BEGIN
              SELECT '' [Explicit Database Permissions:]
              SELECT DISTINCT *
              FROM #DBPerms
			  WHERE [State] LIKE 
			  	CASE 
					WHEN @GrantOrDeny = 0 THEN 'DENY' 
					WHEN @GrantOrDeny = 1 THEN 'GRANT'
					ELSE '%' 
				END
              ORDER BY [Database], [State], [Class], [Permission]
       END
       ELSE BEGIN
              SELECT 'Not mapped to any user with explicit database permissions set'
       END
END
