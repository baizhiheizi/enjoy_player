; Inno Setup 6 — compile after a release build:
;   flutter build windows --release
;   iscc enjoy_player.iss
;
; Install Inno Setup from https://jrsoftware.org/isinfo.php
; Sync #define MyAppVersion from pubspec.yaml before release:
;   pwsh .github/scripts/sync_windows_installer_version.ps1

#define MyAppName "Enjoy Player"
#define MyAppPublisher "Enjoy"
#define MyAppExeName "enjoy_player.exe"
#define MyAppVersion "0.2.0"

[Setup]
AppId={{8F3C2B1A-9D8E-4F7C-A6B5-4D3C2B1A0F9E}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\build\windows\installer
OutputBaseFilename=EnjoyPlayerSetup-v{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
