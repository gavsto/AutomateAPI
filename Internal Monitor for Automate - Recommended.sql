##################
# Monitor: GetControlSessionIDs*
# Interval: 300 seconds
# Alert Mode: Send Fail after Success
# Alert Template: Default - Do Nothing
# Alert Script: No script selected
#
# Targeted Groups:
# Global Monitor. No groups targeted.
#
# Last Modified by dwhite
##################
DELETE FROM Agents WHERE GUID='f5c71af8-5752-4b1e-aa87-2b8cfe45b68d';
INSERT INTO `Agents` (`AgentID`, `Name`,`LocID`,`ClientID`,`ComputerID`,`DriveID`,`CheckAction`,`AlertAction`,`AlertMessage`,`ContactID`,`interval`, `Where`, `What`, `DataOut`,`Comparor`,`DataIn`,`LastScan`, `LastFailed`,`FailCount`,`IDField`,`AlertStyle`,`Changed`, `Last_Date`,`Last_User`, `ReportCategory`,`TicketCategory`,`Flags`, `GUID`,`AgentDefaultGUID`,`WarningCount`, `DeviceId`)
VALUES (NULL,'GetControlSessionIDs*',0,0,0,'0',0,1,'%NAME% %STATUS% on %CLIENTNAME%\\%COMPUTERNAME% at %LOCATIONNAME% for %FIELDNAME% result %RESULT%.!!!%NAME% %STATUS% on %CLIENTNAME%\\%COMPUTERNAME% at %LOCATIONNAME% for %FIELDNAME% result %RESULT%.',0,300,'plugin_screenconnect_scinstalled','IsSCInstalled','',1,'1',NOW(),'1979-01-01 01:01:01',0,'plugin_screenconnect_scinstalled.SessionGUID',0,0,'2019-02-16 07:17:34',USER(),0,0,1,'f5c71af8-5752-4b1e-aa87-2b8cfe45b68d','',0,0);
