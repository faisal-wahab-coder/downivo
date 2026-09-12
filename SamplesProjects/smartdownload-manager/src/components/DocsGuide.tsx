import React, { useState } from 'react';
import { 
  BookOpen, 
  Terminal, 
  Copy, 
  Check, 
  ShieldCheck, 
  Layers, 
  Globe, 
  HardDrive, 
  Play,
  AlertTriangle,
  HelpCircle,
  Sparkles
} from 'lucide-react';

export const DocsGuide: React.FC = () => {
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'steps' | 'troubleshooting'>('steps');

  const copyCode = (id: string, text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const steps = [
    {
      id: 'step1',
      title: 'Step 1: Set Up Python 3 & PySide6 Windows Environment',
      description: 'Clone or extract the project ZIP on your Windows workstation and install dependencies (or simply run setup.bat):',
      command: `cd windows-download-manager

# Option A: Using Windows Python Launcher (recommended if 'python' isn't in PATH):
py -m venv venv
.\\venv\\Scripts\\Activate.ps1
pip install -r requirements.txt

# Option B: Or simply double-click / run:
.\\setup.bat`,
    },
    {
      id: 'step2',
      title: 'Step 2: Launch SmartDownload Manager GUI',
      description: 'Run the PySide6 desktop application with single-instance lock and system tray:',
      command: `# Inside activated virtual environment:
python main.py

# Or 1-click launcher:
.\\run.bat`,
    },
    {
      id: 'step3',
      title: 'Step 3: Install Chrome Extension (Manifest V3)',
      description: 'Load the unpacked extension in Google Chrome or Microsoft Edge:',
      command: `# 1. Open Google Chrome and navigate to: chrome://extensions
# 2. Toggle "Developer mode" ON (top right corner)
# 3. Click "Load unpacked"
# 4. Select the "chrome-extension" folder from this project`,
    },
    {
      id: 'step4',
      title: 'Step 4: Register Native Messaging Host in Windows Registry',
      description: 'Run the registry script to allow Chrome to communicate with Python host:',
      command: `.\\native-messaging\\install_host.bat

# Or run via PowerShell Administrator:
New-Item -Path "HKCU:\\Software\\Google\\Chrome\\NativeMessagingHosts\\com.smartdownload.manager" -Force
Set-ItemProperty -Path "HKCU:\\Software\\Google\\Chrome\\NativeMessagingHosts\\com.smartdownload.manager" -Name "(Default)" -Value "$PWD\\native-messaging\\com.smartdownload.manager.json"`,
    },
    {
      id: 'step5',
      title: 'Step 5: Run Automated Tests',
      description: 'Execute unit and integration tests for multi-thread chunking and range headers:',
      command: `python -m unittest discover tests -v`,
    },
    {
      id: 'step6',
      title: 'Step 6: Build Final Standalone Windows .EXE',
      description: 'Compile into a high-performance, single-file portable SmartDownloadManager.exe using PyInstaller:',
      command: `# Option A: Run the 1-click Windows build script:
cd windows-download-manager
.\\build_exe.bat

# Option B: Run Python builder directly (creates dist/SmartDownloadManager.exe):
python build_exe.py

# Option C: Direct PyInstaller one-file command:
pyinstaller --name="SmartDownloadManager" --onefile --windowed --icon="assets/icon.ico" main.py`,
    },
    {
      id: 'step7',
      title: 'Step 7: Category Folders in Downloads (Auto-Organization)',
      description: 'SmartDownload automatically creates and sorts completed files into Videos, Music, Documents, Images, Programs, and Archives folders inside your Downloads directory:',
      command: `# Create standard category folders in your Windows Downloads folder via PowerShell:
$dl = "$HOME\\Downloads"
"Videos", "Music", "Documents", "Images", "Programs", "Archives", "Other" | ForEach-Object {
    New-Item -ItemType Directory -Force -Path (Join-Path $dl $_)
}

# Or in the Web UI: Click "Settings" (gear icon) > "Categories" tab > click "Create Category Folders on Disk Now"`,
    },
  ];

  const troubleshoots = [
    {
      id: 'err-not-recognized',
      title: "Error: The term 'python' is not recognized as the name of a cmdlet...",
      cause: "Python is installed on Windows, but was not added to the Windows System PATH environment variable, or you should use the official Windows Python launcher `py`.",
      solutions: [
        {
          label: "Solution 1: Use the Windows Python Launcher ('py')",
          code: `py -m venv venv\n.\\venv\\Scripts\\Activate.ps1\npip install -r requirements.txt`
        },
        {
          label: "Solution 2: Use the included automated 1-click script",
          code: `.\\setup.bat`
        },
        {
          label: "Solution 3: Locate Python and invoke it directly",
          code: `# Test standard installation paths:\n& "$env:LOCALAPPDATA\\Programs\\Python\\Python312\\python.exe" -m venv venv\n\n# Or for Python 3.11:\n& "$env:LOCALAPPDATA\\Programs\\Python\\Python311\\python.exe" -m venv venv`
        },
        {
          label: "Solution 4: Install Python 3.12 via Windows Package Manager (winget)",
          code: `winget install Python.Python.3.12 --override "/passive PrependPath=1"`
        }
      ]
    },
    {
      id: 'err-execution-policy',
      title: "Error: File Activate.ps1 cannot be loaded because running scripts is disabled...",
      cause: "PowerShell default execution policy restricts unsigned local scripts.",
      solutions: [
        {
          label: "Fix: Allow local script execution for current PowerShell session",
          code: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass\n.\\venv\\Scripts\\Activate.ps1`
        }
      ]
    }
  ];

  return (
    <div id="docs-guide" className="flex-1 bg-[#141416] p-5 overflow-y-auto select-none text-xs text-zinc-200">
      <div className="max-w-4xl mx-auto space-y-5">
        {/* Header */}
        <div className="bg-[#1f1f23] border border-zinc-700 p-4 rounded-xl flex items-center justify-between">
          <div className="flex items-center gap-3.5">
            <div className="w-10 h-10 rounded-lg bg-sky-500/20 text-sky-400 border border-sky-500/30 flex items-center justify-center">
              <BookOpen className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-zinc-100">
                SmartDownload Manager Deployment & PowerShell Guide
              </h2>
              <p className="text-xs text-zinc-400 mt-0.5">
                Windows setup, PowerShell commands, Chrome extension pairing, and troubleshooting.
              </p>
            </div>
          </div>

          {/* Navigation Toggle */}
          <div className="flex bg-zinc-900 border border-zinc-800 p-1 rounded-lg">
            <button
              onClick={() => setActiveTab('steps')}
              className={`px-3 py-1.5 rounded-md font-medium text-xs transition-colors ${
                activeTab === 'steps' ? 'bg-sky-600 text-white' : 'text-zinc-400 hover:text-zinc-200'
              }`}
            >
              Setup Steps
            </button>
            <button
              onClick={() => setActiveTab('troubleshooting')}
              className={`flex items-center gap-1 px-3 py-1.5 rounded-md font-medium text-xs transition-colors ${
                activeTab === 'troubleshooting' ? 'bg-amber-600 text-white' : 'text-zinc-400 hover:text-amber-400'
              }`}
            >
              <AlertTriangle className="w-3.5 h-3.5" />
              <span>Troubleshooting</span>
            </button>
          </div>
        </div>

        {/* TAB: SETUP STEPS */}
        {activeTab === 'steps' && (
          <div className="space-y-4">
            {steps.map((step, idx) => (
              <div key={step.id} className="bg-[#1a1a1e] border border-zinc-800 rounded-xl p-4 space-y-2">
                <div className="flex items-center justify-between">
                  <h3 className="font-bold text-sm text-zinc-100 flex items-center gap-2">
                    <span className="w-5 h-5 rounded-full bg-sky-600/30 text-sky-400 border border-sky-500/40 text-xs flex items-center justify-center font-mono">
                      {idx + 1}
                    </span>
                    <span>{step.title}</span>
                  </h3>

                  <button
                    onClick={() => copyCode(step.id, step.command)}
                    className="flex items-center gap-1.5 px-2.5 py-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded text-xs transition-colors"
                  >
                    {copiedId === step.id ? (
                      <>
                        <Check className="w-3.5 h-3.5 text-emerald-400" />
                        <span className="text-emerald-400">Copied!</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3.5 h-3.5" />
                        <span>Copy</span>
                      </>
                    )}
                  </button>
                </div>

                <p className="text-xs text-zinc-400">{step.description}</p>

                <div className="bg-[#0f0f12] border border-zinc-800 rounded-lg p-3 font-mono text-[11px] text-sky-300 select-text overflow-x-auto leading-relaxed">
                  <pre>{step.command}</pre>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* TAB: TROUBLESHOOTING */}
        {activeTab === 'troubleshooting' && (
          <div className="space-y-4">
            {troubleshoots.map((tr) => (
              <div key={tr.id} className="bg-[#1a1a1e] border border-amber-500/30 rounded-xl p-4 space-y-3">
                <div className="flex items-start gap-2.5">
                  <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
                  <div>
                    <h3 className="font-bold text-sm text-amber-200 font-mono">{tr.title}</h3>
                    <p className="text-xs text-zinc-400 mt-1">{tr.cause}</p>
                  </div>
                </div>

                <div className="space-y-3 pt-2 border-t border-zinc-800">
                  {tr.solutions.map((sol, sIdx) => (
                    <div key={sIdx} className="bg-zinc-950/80 p-3 rounded-lg border border-zinc-800 space-y-1.5">
                      <div className="flex items-center justify-between font-semibold text-xs text-zinc-200">
                        <span>{sol.label}</span>
                        <button
                          onClick={() => copyCode(`${tr.id}-${sIdx}`, sol.code)}
                          className="flex items-center gap-1 text-[11px] text-sky-400 hover:text-sky-300 font-mono"
                        >
                          {copiedId === `${tr.id}-${sIdx}` ? <Check className="w-3 h-3 text-emerald-400" /> : <Copy className="w-3 h-3" />}
                          <span>{copiedId === `${tr.id}-${sIdx}` ? 'Copied' : 'Copy'}</span>
                        </button>
                      </div>
                      <div className="font-mono text-[11px] text-emerald-400 overflow-x-auto p-2 bg-[#0e0e11] rounded border border-zinc-800/80 select-text">
                        <pre>{sol.code}</pre>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

