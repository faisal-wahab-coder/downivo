import React from 'react';
import { 
  Monitor, 
  Globe, 
  Cpu, 
  FolderArchive, 
  BookOpen, 
  Minus, 
  Square, 
  X, 
  Zap,
  Download,
  Gauge
} from 'lucide-react';

export type AppViewMode = 'desktop' | 'browser' | 'protocol' | 'codebase' | 'docs';

interface TitleBarProps {
  currentView: AppViewMode;
  onViewChange: (view: AppViewMode) => void;
  activeDownloadCount: number;
  totalSpeed: number;
  formatSpeed: (s: number) => string;
  onMinimize?: () => void;
  onMaximize?: () => void;
  onClose?: () => void;
}

export const TitleBar: React.FC<TitleBarProps> = ({
  currentView,
  onViewChange,
  activeDownloadCount,
  totalSpeed,
  formatSpeed,
  onMinimize,
  onMaximize,
  onClose,
}) => {
  return (
    <header id="app-titlebar" className="bg-[#18181b] border-b border-[#27272a] text-zinc-200 select-none flex items-center justify-between px-3 py-1.5 text-xs">
      {/* Brand & App Title */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2 font-semibold text-sky-400">
          <div className="w-5 h-5 rounded bg-sky-500/20 border border-sky-500/40 flex items-center justify-center text-sky-400">
            <Zap className="w-3.5 h-3.5" />
          </div>
          <span className="tracking-tight text-sm text-zinc-100 font-bold">SmartDownload <span className="text-sky-400 font-normal">Manager</span></span>
        </div>

        <span className="text-zinc-600">|</span>

        {/* Live Status indicator */}
        <div className="flex items-center gap-2 px-2 py-0.5 bg-zinc-900/80 rounded border border-zinc-800 text-[11px]">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
          <span className="text-zinc-300 font-medium">Native Host: Connected</span>
          {activeDownloadCount > 0 && (
            <span className="text-sky-400 font-semibold ml-1 flex items-center gap-1">
              <Download className="w-3 h-3 animate-bounce" /> {activeDownloadCount} active ({formatSpeed(totalSpeed)})
            </span>
          )}
        </div>
      </div>

      {/* Navigation View Switcher */}
      <nav aria-label="Application View Switcher" className="flex items-center gap-1 bg-zinc-900/90 p-0.5 rounded-lg border border-zinc-800">
        <button
          id="nav-tab-desktop"
          onClick={() => onViewChange('desktop')}
          className={`flex items-center gap-1.5 px-3 py-1 rounded-md transition-all font-medium text-xs ${
            currentView === 'desktop'
              ? 'bg-sky-600 text-white shadow-sm'
              : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/60'
          }`}
        >
          <Monitor className="w-3.5 h-3.5" />
          <span>Windows App</span>
        </button>

        <button
          id="nav-tab-browser"
          onClick={() => onViewChange('browser')}
          className={`flex items-center gap-1.5 px-3 py-1 rounded-md transition-all font-medium text-xs ${
            currentView === 'browser'
              ? 'bg-sky-600 text-white shadow-sm'
              : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/60'
          }`}
        >
          <Globe className="w-3.5 h-3.5" />
          <span>Chrome Sniffer</span>
        </button>

        <button
          id="nav-tab-protocol"
          onClick={() => onViewChange('protocol')}
          className={`flex items-center gap-1.5 px-3 py-1 rounded-md transition-all font-medium text-xs ${
            currentView === 'protocol'
              ? 'bg-sky-600 text-white shadow-sm'
              : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/60'
          }`}
        >
          <Cpu className="w-3.5 h-3.5" />
          <span>Native Protocol</span>
        </button>

        <button
          id="nav-tab-codebase"
          onClick={() => onViewChange('codebase')}
          className={`flex items-center gap-1.5 px-3 py-1 rounded-md transition-all font-medium text-xs ${
            currentView === 'codebase'
              ? 'bg-sky-600 text-white shadow-sm'
              : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/60'
          }`}
        >
          <FolderArchive className="w-3.5 h-3.5" />
          <span>Codebase & .ZIP</span>
        </button>

        <button
          id="nav-tab-docs"
          onClick={() => onViewChange('docs')}
          className={`flex items-center gap-1.5 px-3 py-1 rounded-md transition-all font-medium text-xs ${
            currentView === 'docs'
              ? 'bg-sky-600 text-white shadow-sm'
              : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/60'
          }`}
        >
          <BookOpen className="w-3.5 h-3.5" />
          <span>PowerShell Guide</span>
        </button>
      </nav>

      {/* Windows Window Controls */}
      <div className="flex items-center gap-1">
        <button
          id="win-btn-minimize"
          onClick={onMinimize}
          className="w-7 h-6 flex items-center justify-center text-zinc-400 hover:text-white hover:bg-zinc-800 rounded transition-colors"
          title="Minimize to Tray"
        >
          <Minus className="w-3.5 h-3.5" />
        </button>
        <button
          id="win-btn-maximize"
          onClick={onMaximize}
          className="w-7 h-6 flex items-center justify-center text-zinc-400 hover:text-white hover:bg-zinc-800 rounded transition-colors"
          title="Maximize"
        >
          <Square className="w-3 h-3" />
        </button>
        <button
          id="win-btn-close"
          onClick={onClose}
          className="w-7 h-6 flex items-center justify-center text-zinc-400 hover:text-white hover:bg-red-600 rounded transition-colors"
          title="Close (Minimize to Tray)"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>
    </header>
  );
};
