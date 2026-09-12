import React, { useState } from 'react';
import { 
  FolderArchive, 
  Download, 
  FileCode, 
  Copy, 
  Check, 
  ChevronRight, 
  Folder, 
  Terminal, 
  Layers, 
  Sparkles,
  ShieldCheck
} from 'lucide-react';
import { CODEBASE_FILES } from '../data/codebaseTree';
import { CodeFile } from '../types';
import JSZip from 'jszip';

export const CodeExplorerModal: React.FC = () => {
  const [selectedFile, setSelectedFile] = useState<CodeFile>(CODEBASE_FILES[0]);
  const [copied, setCopied] = useState(false);
  const [isExporting, setIsExporting] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(selectedFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleExportZip = async () => {
    setIsExporting(true);
    try {
      const zip = new JSZip();

      CODEBASE_FILES.forEach((f) => {
        zip.file(f.path, f.content);
      });

      // Add root 1-click launcher
      zip.file(
        "RUN_WINDOWS_APP.bat",
        `@echo off
title SmartDownload Manager - Windows App Launcher
echo ========================================================
echo   SmartDownload Manager - Starting Windows App...
echo ========================================================
echo.
cd /d "%~dp0windows-download-manager"
call run.bat
`
      );

      // Add README.md
      zip.file(
        "README.md",
        `# SmartDownload Manager - Windows Desktop App + Chrome Extension

A professional Windows download manager inspired by IDM, built with Python (PySide6) and Google Chrome Extension (Manifest V3).

## Quick Start on Windows

### 1. Run Python Download Manager
\`\`\`powershell
cd windows-download-manager
pip install -r requirements.txt
python main.py
\`\`\`

### 2. Install Chrome Extension
1. Open Google Chrome and visit \`chrome://extensions\`
2. Enable **Developer Mode** (top-right toggle)
3. Click **Load unpacked** and select the \`chrome-extension\` folder.

### 3. Register Native Messaging Host
Run \`native-messaging\\install_host.bat\` as Administrator.

### 4. Build Standalone .EXE
\`\`\`powershell
python build_exe.py
\`\`\`
`
      );

      const blob = await zip.generateAsync({ type: 'blob' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'SmartDownload-Manager-Windows-v1.0.0.zip';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('ZIP generation error:', err);
    } finally {
      setIsExporting(false);
    }
  };

  const categories = [
    { id: 'windows_app', label: 'Windows Python App (PySide6)', icon: Layers },
    { id: 'chrome_extension', label: 'Chrome Extension (Manifest V3)', icon: Sparkles },
    { id: 'native_host', label: 'Native Messaging Host', icon: Terminal },
    { id: 'installer', label: 'PyInstaller & Inno Setup', icon: ShieldCheck },
    { id: 'tests', label: 'Automated Tests', icon: FileCode },
  ];

  return (
    <div id="codebase-explorer" className="flex-1 bg-[#141416] p-4 flex flex-col gap-3 select-none overflow-hidden text-xs text-zinc-200">
      {/* Top Banner */}
      <div className="bg-[#1f1f23] border border-zinc-700 p-3 rounded-xl flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-sky-500/20 text-sky-400 border border-sky-500/30 flex items-center justify-center">
            <FolderArchive className="w-4 h-4" />
          </div>
          <div>
            <h3 className="font-bold text-sm text-zinc-100 flex items-center gap-2">
              Standalone Production Codebase & Package Exporter
            </h3>
            <p className="text-[11px] text-zinc-400 mt-0.5">
              Complete Python 3 (PySide6) desktop application + Chrome Extension (Manifest V3) + Inno Setup installer scripts
            </p>
          </div>
        </div>

        {/* Download ZIP Button */}
        <button
          id="btn-export-zip"
          onClick={handleExportZip}
          disabled={isExporting}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white rounded-lg font-bold text-xs shadow-lg shadow-emerald-950/40 transition-all cursor-pointer"
        >
          <Download className="w-4 h-4" />
          <span>{isExporting ? 'Packaging ZIP...' : 'Download Complete Project (.ZIP)'}</span>
        </button>
      </div>

      {/* Main Splitter */}
      <div className="flex-1 flex gap-3 overflow-hidden">
        {/* Left File Tree Navigation */}
        <div className="w-72 bg-[#1b1b1e] border border-zinc-800 rounded-xl flex flex-col overflow-hidden">
          <div className="p-2.5 bg-[#222226] border-b border-zinc-800 font-semibold text-xs text-zinc-300">
            Project Files ({CODEBASE_FILES.length})
          </div>

          <div className="flex-1 overflow-y-auto p-2 space-y-3">
            {categories.map((cat) => {
              const files = CODEBASE_FILES.filter((f) => f.category === cat.id);
              if (files.length === 0) return null;
              const Icon = cat.icon;

              return (
                <div key={cat.id}>
                  <div className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wider text-zinc-500 px-1 mb-1">
                    <Icon className="w-3 h-3 text-sky-400" />
                    <span>{cat.label}</span>
                  </div>

                  <div className="space-y-0.5">
                    {files.map((file) => {
                      const isSelected = selectedFile.path === file.path;
                      return (
                        <button
                          key={file.path}
                          onClick={() => setSelectedFile(file)}
                          className={`w-full flex items-center justify-between px-2.5 py-1.5 rounded text-left transition-colors font-mono text-[11px] ${
                            isSelected
                              ? 'bg-sky-600/30 text-sky-300 border border-sky-500/40 font-semibold'
                              : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/60 border border-transparent'
                          }`}
                        >
                          <div className="flex items-center gap-1.5 truncate">
                            <FileCode className="w-3.5 h-3.5 shrink-0 text-zinc-400" />
                            <span className="truncate">{file.name}</span>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Code Viewer */}
        <div className="flex-1 bg-[#1b1b1e] border border-zinc-800 rounded-xl flex flex-col overflow-hidden">
          {/* File Header */}
          <div className="p-2.5 bg-[#222226] border-b border-zinc-800 flex items-center justify-between text-xs">
            <div>
              <span className="font-mono font-semibold text-sky-400">{selectedFile.path}</span>
              <p className="text-[10px] text-zinc-400 mt-0.5">{selectedFile.description}</p>
            </div>

            <button
              onClick={handleCopy}
              className="flex items-center gap-1.5 px-3 py-1 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded text-xs transition-colors"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
              <span>{copied ? 'Copied!' : 'Copy Code'}</span>
            </button>
          </div>

          {/* Code Content */}
          <div className="flex-1 p-4 bg-[#0e0e11] overflow-auto font-mono text-[11px] leading-relaxed text-zinc-300 select-text">
            <pre>{selectedFile.content}</pre>
          </div>
        </div>
      </div>
    </div>
  );
};
