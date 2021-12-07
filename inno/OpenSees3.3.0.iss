; OpenSees Installer Inno Setup Script
; Written by Alex Baker

#define MyAppName "OpenSees"
#define MyAppVersion "3.3.0"
#define MyAppPublisher "University of California, Berkeley"
#include "environment.iss"

[Setup]
AppId={{0967D55B-E2ED-417A-8549-2EF4379B1685}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppCopyright=Copyright @ 1999-2020 The Regents of the University of California (The Regents). All Rights Reserved.
VersionInfoVersion={#MyAppVersion}.0
DefaultDirName={code:GetTclPath}\{#MyAppName}-{#MyAppVersion}
DisableWelcomePage=no
DisableDirPage=yes
UsePreviousAppDir=no
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename={#MyAppName}-{#MyAppVersion}-Setup
OutputDir=..\build
LicenseFile=..\COPYRIGHT.txt
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ChangesEnvironment=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Dirs]
Name: "{app}\bin"
; create empty lib directory. this can be used for version-specific packages.
Name: "{app}\lib"

[Files]
Source: "..\src\OpenSees3.3.0-x64.exe\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs
Source: "..\COPYRIGHT.txt"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Run]
Filename: "{cmd}"; Parameters: "/C start """" ""{app}""" 

; on uninstall, delete the batch file created in code section, and folders if empty.
[UninstallDelete]
Type: files; Name: "{app}\OpenSees.bat"
Type: dirifempty; Name: "{app}\bin"
Type: dirifempty; Name: "{app}\lib"
Type: dirifempty; Name: "{app}"

[Tasks]
Name: envPath; Description: "Add to PATH variable" 

[Code]
// This code checks to see if the correct version of Tcl is installed (ActiveTcl), and gets the location
const
  ActiveTclRegKey = 'SOFTWARE\Wow6432Node\ActiveState\ActiveTcl';
  ReqTclVersion = '8.6.10';
var
  TclPath: string;

function InitializeSetup(): Boolean;
var
  // Version string to compare against required.
  TclVersion: AnsiString;
  // Variables for getting version from registry
  ActiveTclVersionArray: TArrayOfString;
  i: Integer;
  ActiveTclVersion: String;
  PackedVersion: Int64;
  MajorVersion: Word;
  MinorVersion: Word;
  RevisionNumber: Word;
  BuildNumber: Word;
  // Variables for getting version from tclsh.exe 
  TmpInFile: String;
  TmpOutFile: String;
  ExitCode: Integer;
begin
  // initialize result
  Result := False;
  // Get list of all ActiveTcl versions, and find if one matches.
  if RegGetSubkeyNames(HKLM,ActiveTclRegKey,ActiveTclVersionArray) then
  begin
    for i := 0 to GetArrayLength(ActiveTclVersionArray)-1 do 
    begin
      ActiveTclVersion := ActiveTclVersionArray[i];
      // unpack version number and compare patch level
      StrToVersion(ActiveTclVersion,PackedVersion);
      UnpackVersionComponents(PackedVersion,MajorVersion,MinorVersion,RevisionNumber,BuildNumber);
      TclVersion := IntToStr(MajorVersion) + '.' + IntToStr(MinorVersion) + '.' + IntToStr(RevisionNumber);
      // check to see if patch level matches
      if (CompareStr(TclVersion,ReqTclVersion) = 0) then
      begin
        Result := RegQueryStringValue(HKLM,ActiveTclRegKey + '\' + ActiveTclVersion,'',TclPath);
        break;
      end;
    end;
  end;
  // either ActiveTcl is not installed or the required version is missing/corrupted. Go manual.
  if (Result = False) and BrowseForFolder('Locate Tcl ' + ReqTclVersion + ' Installation', TclPath, False) then
  begin
    // verify directory by running "info patchlevel" in Tclsh
    TmpInFile := ExpandConstant('{tmp}\TclVersion.tcl');
    TmpOutFile := ExpandConstant('{tmp}\TclVersion.log');
    SaveStringToFile(TmpInFile,'puts -nonewline [info patchlevel]',false);
    Exec(ExpandConstant('{cmd}'),'/C ""' + TclPath + '\bin\tclsh.exe" "' + TmpInFile + '" > "' + TmpOutFile + '""', '', SW_HIDE, ewWaitUntilTerminated, ExitCode)
    if (ExitCode = 0) and LoadStringFromFile(TmpOutFile, TclVersion) then
    begin
      // check to see if patch level matches
      if (CompareStr(TclVersion,ReqTclVersion) = 0) then
        Result := True
      else MsgBox('Wrong Tcl version (' + TclVersion + '). Need Tcl ' + ReqTclVersion, mbError, MB_OK)
    end
    else MsgBox('Valid tclsh.exe not found in "' + TclPath + '\bin"', mbError, MB_OK);
    DeleteFile(TmpInFile);
    DeleteFile(TmpOutFile);
  end;
end;

function GetTclPath(Param: string): string;
begin
  Result:= TclPath;
end;

// Code for adding/removing from path by Wojciech Mleczek
// https://stackoverflow.com/a/46609047
procedure CurStepChanged(CurStep: TSetupStep);
begin
    if (CurStep = ssPostInstall) then 
    begin
      // Create batch file for easy access to executable.
      SaveStringToFile(ExpandConstant('{app}\OpenSees.bat'),ExpandConstant('{app}\bin\OpenSees.exe'),false);
      if WizardIsTaskSelected('envPath') then EnvAddPath(ExpandConstant('{app}\bin')); 
    end
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
    if CurUninstallStep = usPostUninstall then EnvRemovePath(ExpandConstant('{app}\bin'));
end;



