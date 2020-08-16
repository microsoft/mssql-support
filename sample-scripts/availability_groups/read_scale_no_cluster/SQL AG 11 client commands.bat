START SQLCMD -U TestLogin -S ag-node001,2433 -d db1 -K ReadOnly -q"print '' select cast(@@servername as char(50)) as server_name, cast(suser_name() as char(50)) as login_name"

START SQLCMD -U TestLogin -S ag-node001,2433 -d db1 -K ReadOnly -q"print '' select cast(@@servername as char(50)) as server_name, cast(suser_name() as char(50)) as login_name"