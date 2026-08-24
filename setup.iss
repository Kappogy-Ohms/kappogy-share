[Setup]
AppId={{5D0B2287-2009-4A73-A332-902B734C7A39}
AppName=Kappogy Share
AppVersion=1.0.0
AppPublisher=Kappogy
DefaultDirName={autopf}\Kappogy Share
DefaultGroupName=Kappogy Share
AllowNoIcons=yes
; Require admin privileges to install to Program Files
PrivilegesRequired=admin
OutputDir=build\installer
OutputBaseFilename=Kappogy-Share-Setup-1.0.0
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\kappogy_share.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Note: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\Kappogy Share"; Filename: "{app}\kappogy_share.exe"
Name: "{group}\{cm:UninstallProgram,Kappogy Share}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Kappogy Share"; Filename: "{app}\kappogy_share.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\kappogy_share.exe"; Description: "{cm:LaunchProgram,Kappogy Share}"; Flags: nowait postinstall skipifsilent
