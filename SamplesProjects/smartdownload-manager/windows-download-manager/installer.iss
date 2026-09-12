; SmartDownload Manager - Inno Setup Script
; Generates Windows setup installer with Registry and Chrome Native Messaging registration

#define MyAppName "SmartDownload Manager"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "SmartDownload Software Inc."
#define MyAppURL "https://smartdownload.app"
#define MyAppExeName "SmartDownloadManager.exe"

[Setup]
AppId={{9B7E3011-80C4-4B28-898A-E70E2856E3B9}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=output
OutputBaseFilename=SmartDownloadManager_Setup_v1.0.0
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "startup"; Description: "Start SmartDownload Manager with Windows"; GroupDescription: "Startup Options:"

[Files]
Source: "dist\SmartDownloadManager\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "native-messaging\com.smartdownload.manager.json"; DestDir: "{app}\native-messaging"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Register Native Messaging Host in Windows Registry for Google Chrome
Root: HKCU; Subkey: "Software\Google\Chrome\NativeMessagingHosts\com.smartdownload.manager"; ValueType: string; ValueData: "{app}\native-messaging\com.smartdownload.manager.json"; Flags: uninsdeletekey
; Register for Microsoft Edge
Root: HKCU; Subkey: "Software\Microsoft\Edge\NativeMessagingHosts\com.smartdownload.manager"; ValueType: string; ValueData: "{app}\native-messaging\com.smartdownload.manager.json"; Flags: uninsdeletekey
; Auto-start with Windows
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "SmartDownloadManager"; ValueData: """{app}\{#MyAppExeName}"" --background"; Flags: uninsdeletevalue; Tasks: startup

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
