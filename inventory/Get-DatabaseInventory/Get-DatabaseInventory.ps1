<#
.Synopsis
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Get-DatabaseInventory Server1,Server2,[...];
.OUTPUTS
    ErrorLog
.NOTES
    General notes
.ROLE
    db_writer, db_reader
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
using namespace System.Collections;
using namespace System.IO;
using namespace Microsoft.SqlServer.Management.Smo;
function Get-DatabaseInventory
{
    [CmdletBinding(SupportsShouldProcess=$true,
                ConfirmImpact='High')]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ArrayList]$ServerSet
    )

    Begin
    {
        [void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo");
    }
    Process
    {
        Class InvenObj
        {
            [bool] $AutoClose;
            [bool] $AutoShrink;
            [bool] $CaseSensitive;
            [datetime] $CreateDate;
            [guid] $DatabaseGuid;
            [double] $DataSpaceUsage; #kb
            [string] $DefaultSchema;
            [int] $ID;
            [double] $IndexSpaceUsage; #kb
            [bool] $IsAccessible;
            [datetime] $LastBackupDate;
            [int] $MaxDop;
            [string] $Name;
            [int] $NbrTables;
            [int] $NbrViews;
            [int] $NbrStoredProcedures;
            [int] $NbrUserDefinedFunctions;
            [string] $Owner;
            [string] $Parent;
            [bool] $ReadOnly;
            [string] $RecoveryModel;
            [double] $Size; #mb
            [double] $SpaceAvailable; #kb
            [string] $State;
            [string] $Status;
            [bool] $TemporalHistoryRetentionEnabled;
            [string] $UserAccess;
            [string] $HashID;

            [string] GenerateHash([string] $p1)
            {
                $paramStream = [MemoryStream]::new();
                $streamWriter = [StreamWriter]::new($paramStream);
                $streamWriter.write($p1);
                $streamWriter.Flush();
                $paramStream.Position = 0;
                return Get-FileHash -InputStream $paramStream -Algorithm SHA256 | Select-Object -ExpandProperty Hash;
            }

            [decimal]ConvertUpUOM([double] $x)
            {
                return $result = switch($x)
                {
                    {$_ -gt 0}{[decimal]::Round($x/1024,3);break}
                    default {0}
                }
            }
        }

        Class InvenObjCollection
        {
            [ArrayList] $Databases;

            InvenObjCollection()
            {
                $this.Databases = [ArrayList]::new();
            }

            [void]AddDatabase([InvenObj] $mydb)
            {
                $this.Databases.Add($mydb);
            }
        }
        $dbObjectCollection = [InvenObjCollection]::new();

        foreach($d in $server.Databases | Where-Object {$_.Name -notin "master","tempdb","model","msdb"})
        {
            $countTbls = $d.Tables.Count;
            $countViews = $d.Views.Count;
            $countSprocs = $d.StoredProcedures.Count;
            $countUDT = $d.UserDefinedFunctions.Count;

            [Database]$database = $server.Databases.Item($d.Name);
            $dbObject = [InvenObj]::new();
            $dbObject.AutoClose = $d.AutoClose;
            $dbObject.AutoShrink = $d.AutoShrink;
            $dbObject.CaseSensitive = $d.CaseSensitive;
            $dbObject.CreateDate = $d.CreateDate;
            $dbObject.DatabaseGuid = $d.DatabaseGuid;
            $dbObject.DataSpaceUsage = $dbObject.ConvertUpUOM($d.DataSpaceUsage);
            $dbObject.DefaultSchema = $d.DefaultSchema;
            $dbObject.ID = $d.ID;
            $dbObject.IndexSpaceUsage = $dbObject.ConvertUpUOM($d.IndexSpaceUsage);
            $dbObject.IsAccessible = $d.IsAccessible;
            $dbObject.LastBackupDate = $d.LastBackupDate;
            $dbObject.MaxDop = $d.MaxDop;
            $dbObject.Name = $d.Name;
            $dbObject.NbrTables = $countTbls;
            $dbObject.NbrViews = $countViews;
            $dbObject.NbrStoredProcedures = $countViews;
            $dbObject.NbrUserDefinedFunctions = $countUDT;
            $dbObject.Owner = $d.Owner;
            $dbObject.Parent = $server.Name;
            $dbObject.ReadOnly = $d.ReadOnly;
            $dbObject.RecoveryModel = $d.RecoveryModel;
            $dbObject.Size = $d.Size;
            $dbObject.SpaceAvailable = $dbObject.ConvertUpUOM($d.SpaceAvailable);
            $dbObject.State = $d.State;
            $dbObject.Status = $d.Status;
            $dbObject.TemporalHistoryRetentionEnabled = $d.TemporalHistoryRetentionEnabled;
            $dbObject.UserAccess = $d.UserAccess;
            $dbObject.HashID = $dbObject.GenerateHash
            ($d.AutoClose,$d.AutoShrink,$d.CaseSensitive,$d.DataSpaceUsage,$d.DefaultSchema,$d.IndexSpaceUsage,$d.IsAccessible,$d.MaxDop,$d.Name,$countTbls,$countViews,$countSprocs,$countUDT,$d.ReadOnly,$d.Size,$d.SpaceAvailable,$d.State,$d.Status-join'')
            [void]$dbObjectCollection.AddDatabase($dbObject);
        }

        [Database]$ProgramWorks = $server.Databases.Item("ProgramWorks");
        foreach($i in $dbObjectCollection.Databases)
        {
            $query = @"
DECLARE @dt Inventory.PWDatabasesClass;
INSERT INTO @dt(AutoClose,AutoShrink,CaseSensitive,CreateDate,DatabaseGuid,DataSpaceUsage
,DefaultSchema,ID,IndexSpaceUsage,IsAccessible,LastBackupDate,MaxDop,Name,Owner,Parent,ReadOnly
,RecoveryModel,Size,SpaceAvailable,State,Status,TemporalHistoryRetentionEnabled,UserAccess,HashID)
	SELECT a.* FROM(
	VALUES('$($i.AutoClose)','$($i.AutoShrink)','$($i.CaseSensitive)'
,'$($i.CreateDate)','$($i.DatabaseGuid)',$($i.DataSpaceUsage)
,'$($i.DefaultSchema)',$($i.ID),$($i.IndexSpaceUsage),'$($i.IsAccessible)'
,'$($i.LastBackupDate)',$($i.MaxDop),'$($i.Name)'

--nbr elements;

,'$($i.Owner)','$($i.Parent)'
,'$($i.ReadOnly)','$($i.RecoveryModel)'
,$($i.Size),$($i.SpaceAvailable),'$($i.State)','$($i.Status)'
,'$($i.TemporalHistoryRetentionEnabled)','$($i.UserAccess)','$($i.HashID)')
) As a(AutoClose,AutoShrink,CaseSensitive,CreateDate,DatabaseGuid,DataSpaceUsage
,DefaultSchema,ID,IndexSpaceUsage,IsAccessible,LastBackupDate,MaxDop,Name,Owner,Parent,ReadOnly
,RecoveryModel,Size,SpaceAvailable,State,Status,TemporalHistoryRetentionEnabled,UserAccess,HashID)

UPDATE tt
SET tt.AutoClose = st.AutoClose
,tt.AutoShrink = st.AutoShrink
,tt.CaseSensitive = st.CaseSensitive
,tt.CreateDate = st.CreateDate
,tt.DatabaseGuid = st.DatabaseGuid
,tt.DataSpaceUsage = st.DataSpaceUsage
,tt.DefaultSchema = st.DefaultSchema
,tt.HashID = st.HashID
,tt.ID = st.ID
,tt.IndexSpaceUsage = st.IndexSpaceUsage
,tt.IsAccessible = st.IsAccessible
,tt.LastBackupDate = st.LastBackupDate
,tt.MaxDop = st.MaxDop
,tt.Name = st.Name
,tt.Owner = st.Owner
,tt.Parent = st.Parent
,tt.ReadOnly = st.ReadOnly
,tt.RecoveryModel = st.RecoveryModel
,tt.Size = st.Size
,tt.SpaceAvailable = st.SpaceAvailable
,tt.State = st.State
,tt.Status = st.Status
,tt.TemporalHistoryRetentionEnabled = st.TemporalHistoryRetentionEnabled
,tt.UserAccess = st.UserAccess
FROM Inventory.PWDatabases As tt
INNER JOIN @dt As st
ON st.DatabaseGuid = tt.DatabaseGuid AND (st.HashID != tt.HashID OR tt.HashID IS NULL);

INSERT INTO Inventory.PWDatabases(AutoClose,AutoShrink,CaseSensitive,CreateDate,DatabaseGuid,DataSpaceUsage
,DefaultSchema,ID,IndexSpaceUsage,IsAccessible,LastBackupDate,MaxDop,Name,Owner,Parent,ReadOnly
,RecoveryModel,Size,SpaceAvailable,State,Status,TemporalHistoryRetentionEnabled,UserAccess,HashID)
SELECT st.AutoClose,st.AutoShrink,st.CaseSensitive,st.CreateDate,st.DatabaseGuid,st.DataSpaceUsage
,st.DefaultSchema,st.ID,st.IndexSpaceUsage,st.IsAccessible,st.LastBackupDate,st.MaxDop,st.Name,st.Owner,st.Parent,st.ReadOnly
,st.RecoveryModel,st.Size,st.SpaceAvailable,st.State,st.Status,st.TemporalHistoryRetentionEnabled,st.UserAccess,st.HashID
FROM @dt As st
LEFT OUTER JOIN Inventory.PWDatabases As tt
ON tt.DatabaseGuid = st.DatabaseGuid
WHERE tt.DatabaseGuid IS NULL;
"@
            $ProgramWorks.ExecuteNonQuery($query);
            #delete
        }
    }
    End
    {
        #extended props
    }
}