import React from 'react';
import { 
  Plus, 
  Play, 
  Pause, 
  Square, 
  Trash2, 
  Settings, 
  Gauge, 
  Calendar, 
  Search, 
  RotateCw,
  RotateCcw,
  History,
  AlertTriangle,
  SlidersHorizontal,
  ChevronDown
} from 'lucide-react';
import { SpeedLimitConfig, SchedulerConfig } from '../types';
import { formatBytes } from '../services/downloadEngine';

interface ToolbarProps {
  onAddUrl: () => void;
  onResumeSelected: () => void;
  onPauseSelected: () => void;
  onStopSelected: () => void;
  onDeleteSelected: () => void;
  onRedownloadSelected: () => void;
  onReloadSelected: () => void;
  onReloadStuck?: () => void;
  hasStuckDownloads?: boolean;
  stuckCount?: number;
  onSimulateStall?: () => void;
  onOpenHistory: () => void;
  onClearHistory: () => void;
  historyCount: number;
  isHistoryView: boolean;
  onOpenSettings: () => void;
  hasSelection: boolean;
  selectedStatus?: string;
  speedConfig: SpeedLimitConfig;
  onToggleSpeedLimit: () => void;
  schedulerConfig: SchedulerConfig;
  searchQuery: string;
  onSearchChange: (q: string) => void;
}

export const Toolbar: React.FC<ToolbarProps> = ({
  onAddUrl,
  onResumeSelected,
  onPauseSelected,
  onStopSelected,
  onDeleteSelected,
  onRedownloadSelected,
  onReloadSelected,
  onReloadStuck,
  hasStuckDownloads = false,
  stuckCount = 0,
  onSimulateStall,
  onOpenHistory,
  onClearHistory,
  historyCount,
  isHistoryView,
  onOpenSettings,
  hasSelection,
  selectedStatus,
  speedConfig,
  onToggleSpeedLimit,
  schedulerConfig,
  searchQuery,
  onSearchChange,
}) => {
  return (
    <div id="app-toolbar" className="bg-[#18181b] border-b border-[#27272a] px-3.5 py-2.5 flex flex-col gap-2">
      {/* Row 1: Primary Action Buttons, Dividers, History, Speed & Scheduler */}
      <div className="flex items-center gap-1.5 flex-wrap">
        <button
          id="toolbar-btn-add"
          onClick={onAddUrl}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-sky-600 hover:bg-sky-500 active:bg-sky-700 text-white rounded-md text-xs font-semibold shadow-sm transition-all"
        >
          <Plus className="w-4 h-4" />
          <span>Add URL</span>
        </button>

        <div className="h-5 w-px bg-zinc-700 mx-0.5" />

        <button
          id="toolbar-btn-resume"
          onClick={onResumeSelected}
          disabled={!hasSelection || selectedStatus === 'downloading' || selectedStatus === 'completed'}
          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-md text-xs font-medium transition-all ${
            hasSelection && selectedStatus !== 'downloading' && selectedStatus !== 'completed'
              ? 'bg-zinc-800 hover:bg-emerald-600/20 text-emerald-400 hover:text-emerald-300 border border-zinc-700'
              : 'text-zinc-500 bg-zinc-800/40 cursor-not-allowed border border-transparent'
          }`}
          title="Resume Download"
        >
          <Play className="w-3.5 h-3.5 fill-current" />
          <span>Resume</span>
        </button>

        <button
          id="toolbar-btn-pause"
          onClick={onPauseSelected}
          disabled={!hasSelection || selectedStatus !== 'downloading'}
          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-md text-xs font-medium transition-all ${
            hasSelection && selectedStatus === 'downloading'
              ? 'bg-zinc-800 hover:bg-amber-600/20 text-amber-400 hover:text-amber-300 border border-zinc-700'
              : 'text-zinc-500 bg-zinc-800/40 cursor-not-allowed border border-transparent'
          }`}
          title="Pause Download"
        >
          <Pause className="w-3.5 h-3.5 fill-current" />
          <span>Pause</span>
        </button>

        <button
          id="toolbar-btn-stop"
          onClick={onStopSelected}
          disabled={!hasSelection || selectedStatus !== 'downloading'}
          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-md text-xs font-medium transition-all ${
            hasSelection && selectedStatus === 'downloading'
              ? 'bg-zinc-800 hover:bg-red-600/20 text-red-400 hover:text-red-300 border border-zinc-700'
              : 'text-zinc-500 bg-zinc-800/40 cursor-not-allowed border border-transparent'
          }`}
          title="Stop"
        >
          <Square className="w-3 h-3 fill-current" />
          <span>Stop</span>
        </button>

        {/* RELOAD IF SLOW OR STUCK BUTTON */}
        <button
          id="toolbar-btn-reload"
          onClick={hasStuckDownloads && onReloadStuck ? onReloadStuck : onReloadSelected}
          disabled={!hasStuckDownloads && (!hasSelection || selectedStatus !== 'downloading')}
          className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-xs font-medium transition-all ${
            hasStuckDownloads
              ? 'bg-amber-500/20 hover:bg-amber-500/30 text-amber-300 border border-amber-500/50 shadow-sm animate-pulse'
              : hasSelection && selectedStatus === 'downloading'
              ? 'bg-zinc-800 hover:bg-amber-600/20 text-amber-400 hover:text-amber-300 border border-zinc-700'
              : 'text-zinc-500 bg-zinc-800/40 cursor-not-allowed border border-transparent'
          }`}
          title={
            hasStuckDownloads
              ? `Stalled download detected (${stuckCount})! Click to reload connections and restore speed without losing progress`
              : 'Reload connections (fixes slow or stuck speeds by reconnecting socket chunks)'
          }
        >
          <RotateCcw className={`w-3.5 h-3.5 ${hasStuckDownloads ? 'animate-spin' : ''}`} />
          <span>{hasStuckDownloads ? `Reload Stuck (${stuckCount})` : 'Reload'}</span>
        </button>

        <button
          id="toolbar-btn-redownload"
          onClick={onRedownloadSelected}
          disabled={!hasSelection}
          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-md text-xs font-medium transition-all ${
            hasSelection
              ? 'bg-zinc-800 hover:bg-sky-600/20 text-sky-400 hover:text-sky-300 border border-zinc-700'
              : 'text-zinc-500 bg-zinc-800/40 cursor-not-allowed border border-transparent'
          }`}
          title="Re-download from start"
        >
          <RotateCw className="w-3.5 h-3.5" />
          <span>Retry</span>
        </button>

        <button
          id="toolbar-btn-delete"
          onClick={onDeleteSelected}
          disabled={!hasSelection}
          className={`flex items-center gap-1 px-2.5 py-1.5 rounded-md text-xs font-medium transition-all ${
            hasSelection
              ? 'bg-zinc-800 hover:bg-red-600/20 text-rose-400 hover:text-rose-300 border border-zinc-700'
              : 'text-zinc-500 bg-zinc-800/40 cursor-not-allowed border border-transparent'
          }`}
          title="Delete from Queue"
        >
          <Trash2 className="w-3.5 h-3.5" />
          <span>Delete</span>
        </button>

        <div className="h-5 w-px bg-zinc-700 mx-0.5" />

        {/* DOWNLOAD HISTORY BUTTON */}
        <button
          id="toolbar-btn-history"
          onClick={onOpenHistory}
          className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-xs font-medium border transition-all ${
            isHistoryView
              ? 'bg-teal-600/25 text-teal-300 border-teal-500/50 shadow-xs'
              : 'bg-zinc-800 text-zinc-300 border-zinc-700 hover:bg-zinc-700 hover:text-white'
          }`}
          title="View Download History"
        >
          <History className="w-3.5 h-3.5 text-teal-400" />
          <span>History ({historyCount})</span>
        </button>

        {/* CLEAR HISTORY BUTTON */}
        <button
          id="toolbar-btn-clear-history"
          onClick={onClearHistory}
          disabled={historyCount === 0}
          className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-xs font-medium transition-all ${
            historyCount > 0
              ? 'bg-zinc-800 hover:bg-rose-600/20 text-rose-400 hover:text-rose-300 border border-zinc-700 cursor-pointer'
              : 'text-zinc-600 bg-zinc-800/30 cursor-not-allowed border border-transparent'
          }`}
          title={historyCount > 0 ? "Clear completed downloads from history (files remain safely on disk)" : "Download history is empty"}
        >
          <Trash2 className="w-3.5 h-3.5" />
          <span>Clear History</span>
        </button>

        <div className="h-5 w-px bg-zinc-700 mx-0.5" />

        {/* Speed Limiter Quick Button */}
        <button
          id="toolbar-btn-speed-limiter"
          onClick={onToggleSpeedLimit}
          className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-xs font-medium border transition-all ${
            speedConfig.enabled
              ? 'bg-amber-500/20 text-amber-300 border-amber-500/40'
              : 'bg-zinc-800 text-zinc-400 border-zinc-700 hover:text-zinc-200'
          }`}
          title="Toggle Speed Limiter"
        >
          <Gauge className="w-3.5 h-3.5" />
          <span>
            {speedConfig.enabled
              ? `Limit: ${formatBytes(speedConfig.limitBytesPerSec)}/s`
              : 'Speed: Unlimited'}
          </span>
        </button>

        {/* Scheduler Quick Status */}
        <div
          id="toolbar-scheduler-status"
          className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-xs font-medium border ${
            schedulerConfig.enabled
              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30'
              : 'bg-zinc-800/60 text-zinc-500 border-zinc-800'
          }`}
          title={
            schedulerConfig.enabled
              ? `Scheduled: ${schedulerConfig.startTime} - ${schedulerConfig.stopTime}`
              : 'Scheduler is Idle'
          }
        >
          <Calendar className="w-3.5 h-3.5" />
          <span>{schedulerConfig.enabled ? `${schedulerConfig.startTime}-${schedulerConfig.stopTime}` : 'Scheduler: Off'}</span>
        </div>
      </div>

      {/* Row 2: Secondary Controls (Test Slow/Stall + Search + Settings) */}
      <div className="flex items-center gap-2 flex-wrap">
        {onSimulateStall && (
          <button
            id="toolbar-btn-simulate-stall"
            onClick={onSimulateStall}
            className="flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-semibold bg-amber-500/10 hover:bg-amber-500/20 text-amber-400 border border-amber-500/40 rounded-md transition-colors"
            title="Simulate slow / stalled connection to test reload and recovery"
          >
            <AlertTriangle className="w-3.5 h-3.5" />
            <span>Test Slow/Stall</span>
          </button>
        )}

        <div className="relative">
          <Search className="w-3.5 h-3.5 text-zinc-500 absolute left-2.5 top-1/2 -translate-y-1/2" />
          <input
            id="toolbar-search-input"
            type="text"
            placeholder="Search downloads..."
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            className="w-56 bg-zinc-900 border border-zinc-700 text-zinc-200 pl-8 pr-3 py-1.5 text-xs rounded-md focus:outline-none focus:border-sky-500 transition-colors"
          />
        </div>

        <button
          id="toolbar-btn-settings"
          onClick={onOpenSettings}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded-md text-xs font-medium transition-all"
        >
          <Settings className="w-3.5 h-3.5" />
          <span>Settings</span>
        </button>
      </div>
    </div>
  );
};
