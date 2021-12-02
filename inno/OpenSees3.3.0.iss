; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "OpenSees"
#define MyAppVersion "3.3.0"
#define MyAppPublisher "University of California, Berkeley"
#include "environment.iss"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{0967D55B-E2ED-417A-8549-2EF4379B1685}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={commonpf64}\OpenSees
DisableWelcomePage=no
DisableDirPage=no
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename={#MyAppName}-{#MyAppVersion}-Setup
OutputDir=../build
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\src\OpenSees3.3.0-x64.exe\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs
Source: "..\COPYRIGHT"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

; This run command creates a link to the full Tcl library
[Run]
Filename: "{cmd}"; Parameters: "/C mklink /D ""{app}\lib"" ""{code:GetActiveTclPath}\lib"""

[Tasks]
Name: envPath; Description: "Add to PATH variable" 

[UninstallDelete]
Type: filesandordirs; Name: "{app}\lib"

[Code]
// This code checks to see if the correct version of Tcl is installed (ActiveTcl), and gets the location
const
  ActiveTclKey = 'SOFTWARE\Wow6432Node\ActiveState\ActiveTcl';
var
  ActiveTclPath: string;

function InitializeSetup(): Boolean;
var
  ActiveTclVersion: string;
  PackedVersion: Int64;
  MajorVersion: Word;
  MinorVersion: Word;
  RevisionNumber: Word;
  BuildNumber: Word;
begin
  if RegQueryStringValue(HKLM,ActiveTclKey,'CurrentVersion',ActiveTclVersion) then
  begin
    StrToVersion(ActiveTclVersion,PackedVersion);
    UnpackVersionComponents(PackedVersion,MajorVersion,MinorVersion,RevisionNumber,BuildNumber);
    // only compare patch level (don't worry about build number)
    if (MajorVersion = 8) and (MinorVersion = 6) and (RevisionNumber = 10) then
    begin
      Result := True;
      RegQueryStringValue(HKLM,ActiveTclKey + '\' + ActiveTclVersion,'',ActiveTclPath);
    end
    else
    begin
      Result := False;
      MsgBox('Requires ActiveTcl 8.6.10 from activestate.com', mbError, MB_OK);
    end;
  end
  else
  begin
    Result := False;
    MsgBox('Requires ActiveTcl 8.6.10 from activestate.com', mbError, MB_OK);
  end;
end;

function GetActiveTclPath(Param: string): string;
begin
  Result:= ActiveTclPath;
end;

// code below by Wojciech Mleczek, adds and removes from path.
// https://stackoverflow.com/a/46609047
procedure CurStepChanged(CurStep: TSetupStep);
begin
    if (CurStep = ssPostInstall) and IsTaskSelected('envPath')
    then EnvAddPath(ExpandConstant('{app}') +'\bin');
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
    if CurUninstallStep = usPostUninstall
    then EnvRemovePath(ExpandConstant('{app}') +'\bin');
end;


