import React, { useState } from 'react';
import { 
  DownloadTask, 
  DownloadStatus 
} from '../types';
import { 
  formatBytes, 
  formatSpeed, 
  formatEta 
} from '../services/downloadEngine';
import { 
  Play, 
  Pause, 
  Square, 
  RotateCw, 
  RotateCcw,
  Trash2, 
  ExternalLink, 
  FolderOpen, 
  Copy, 
  ShieldCheck, 
  FileText, 
  Video, 
  Music, 
  Image as ImageIcon, 
  Box, 
  Archive, 
  FileQuestion,
  MoreVertical,
  CheckCircle2,
  AlertCircle,
  Clock,
  Sparkles,
  History,
  AlertTriangle
} from 'lucide-react';

interface DownloadListProps {
  downloads: DownloadTask[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onResume: (id: string) => void;
  onPause: (id: string) => void;
  onStop: (id: string) => void;
  onRetry: (id: string) => void;
  onReload?: (id: string) => void;
  onDelete: (id: string) => void;
  onVerifyChecksum: (task: DownloadTask) => void;
  onOpenFile: (task: DownloadTask) => void;
  onOpenFolder: (task: DownloadTask) => void;
  isHistoryView?: boolean;
  onClearHistory?: () => void;
}

export const DownloadList: React.FC<DownloadListProps> = ({
  downloads,
  selectedId,
  onSelect,
  onResume,
  onPause,
  onStop,
  onRetry,
  onReload,
  onDelete,
  onVerifyChecksum,
  onOpenFile,
  onOpenFolder,
  isHistoryView = false,
  onClearHistory,
}) => {
  const [contextMenu, setContextMenu] = useState<{ x: number; y: number; task: DownloadTask } | null>(null);

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'Videos': return <Video className="w-4 h-4 text-rose-400" />;
      case 'Music': return <Music className="w-4 h-4 text-indigo-400" />;
      case 'Documents': return <FileText className="w-4 h-4 text-blue-400" />;
      case 'Images': return <ImageIcon className="w-4 h-4 text-emerald-400" />;
      case 'Programs': return <Box className="w-4 h-4 text-amber-400" />;
      case 'Archives': return <Archive className="w-4 h-4 text-orange-400" />;
      default: return <FileQuestion className="w-4 h-4 text-zinc-400" />;
    }
  };

  const formatCompletionTime = (timestamp?: number) => {
    if (!timestamp) return 'Completed';
    const d = new Date(timestamp);
    const now = new Date();
    const isToday = d.toDateString() === now.toDateString();
    const timeStr = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    return isToday ? `Today ${timeStr}` : `${d.toLocaleDateString([], { month: 'short', day: 'numeric' })} ${timeStr}`;
  };

  const getStatusBadge = (status: DownloadStatus) => {
    switch (status) {
      case 'downloading':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-medium bg-sky-500/20 text-sky-400 border border-sky-500/30 animate-pulse">
            <span className="w-1.5 h-1.5 rounded-full bg-sky-400" />
            Downloading
          </span>
        );
      case 'completed':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-medium bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
            <CheckCircle2 className="w-3 h-3" />
            Completed
          </span>
        );
      case 'paused':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-medium bg-amber-500/20 text-amber-400 border border-amber-500/30">
            <Pause className="w-3 h-3" />
            Paused
          </span>
        );
      case 'queued':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-medium bg-purple-500/20 text-purple-400 border border-purple-500/30">
            <Clock className="w-3 h-3" />
            Queued
          </span>
        );
      case 'failed':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-medium bg-rose-500/20 text-rose-400 border border-rose-500/30">
            <AlertCircle className="w-3 h-3" />
            Failed
          </span>
        );
      default:
        return <span className="text-zinc-500 text-xs">{status}</span>;
    }
  };

  const handleContextMenu = (e: React.MouseEvent, task: DownloadTask) => {
    e.preventDefault();
    onSelect(task.id);
    setContextMenu({
      x: e.clientX,
      y: e.clientY,
      task,
    });
  };

  const closeContextMenu = () => setContextMenu(null);

  return (
    <div 
      id="download-list-container"
      className="flex-1 bg-[#18181b] overflow-auto select-none relative flex flex-col"
      onClick={closeContextMenu}
    >
      {/* History Header Banner */}
      {isHistoryView && (
        <div 
          id="history-view-banner"
          className="bg-[#1c1c20] border-b border-zinc-800 px-4 py-2.5 flex items-center justify-between shrink-0"
        >
          <div className="flex items-center gap-2 text-xs">
            <div className="p-1 rounded bg-teal-500/20 text-teal-300 border border-teal-500/30">
              <History className="w-3.5 h-3.5" />
            </div>
            <span className="text-zinc-200 font-medium">
              Download History: <strong className="text-white font-semibold">{downloads.length}</strong> completed {downloads.length === 1 ? 'item' : 'items'}
            </span>
            <span className="text-zinc-500 text-[11px]">
              (Total: {formatBytes(downloads.reduce((acc, d) => acc + d.downloadedBytes, 0))})
            </span>
          </div>

          <div className="flex items-center gap-2">
            {onClearHistory && (
              <button
                id="btn-banner-clear-history"
                onClick={onClearHistory}
                disabled={downloads.length === 0}
                className={`flex items-center gap-1.5 px-3 py-1 rounded text-xs font-medium border transition-colors ${
                  downloads.length > 0
                    ? 'bg-rose-500/10 hover:bg-rose-500/20 text-rose-300 border-rose-500/30 cursor-pointer'
                    : 'text-zinc-600 border-zinc-800 cursor-not-allowed'
                }`}
                title="Clear download history records from manager list"
              >
                <Trash2 className="w-3.5 h-3.5" />
                <span>Clear History</span>
              </button>
            )}
          </div>
        </div>
      )}

      {downloads.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center text-zinc-500 py-16">
          <div className="w-12 h-12 rounded-full bg-zinc-800/80 flex items-center justify-center mb-3">
            {isHistoryView ? <History className="w-6 h-6 text-teal-400/80" /> : <FileQuestion className="w-6 h-6 text-zinc-400" />}
          </div>
          <p className="text-sm font-medium text-zinc-300">
            {isHistoryView ? 'Download history is empty' : 'No downloads match the active filter'}
          </p>
          <p className="text-xs text-zinc-500 mt-1">
            {isHistoryView 
              ? 'Finished downloads will be logged here automatically.' 
              : 'Click "+ Add URL" or download media from the Chrome Sniffer tab'}
          </p>
        </div>
      ) : (
        <table id="downloads-table" className="w-full text-left text-xs border-collapse">
          <thead className="bg-[#202024] sticky top-0 z-10 border-b border-[#2d2d32] text-zinc-400 text-[11px]">
            <tr>
              <th className="py-2 px-3 font-semibold w-8">#</th>
              <th className="py-2 px-3 font-semibold">Filename</th>
              <th className="py-2 px-3 font-semibold w-28">Size</th>
              <th className="py-2 px-3 font-semibold w-28">Status</th>
              <th className="py-2 px-3 font-semibold w-48">Progress</th>
              <th className="py-2 px-3 font-semibold w-28">Speed</th>
              <th className="py-2 px-3 font-semibold w-24">ETA / Completed</th>
              <th className="py-2 px-3 font-semibold w-24">Category</th>
              <th className="py-2 px-3 font-semibold w-12 text-center">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#27272a]">
            {downloads.map((task, idx) => {
              const isSelected = selectedId === task.id;
              const percent = task.totalBytes > 0 
                ? Math.min(100, (task.downloadedBytes / task.totalBytes) * 100) 
                : (task.status === 'completed' ? 100 : 0);

              return (
                <tr
                  key={task.id}
                  id={`download-row-${task.id}`}
                  onClick={() => onSelect(task.id)}
                  onContextMenu={(e) => handleContextMenu(e, task)}
                  onDoubleClick={() => task.status === 'completed' ? onOpenFile(task) : onResume(task.id)}
                  className={`cursor-pointer transition-colors ${
                    isSelected 
                      ? 'bg-sky-950/40 text-zinc-100 border-l-2 border-sky-500' 
                      : 'hover:bg-zinc-800/50 text-zinc-300'
                  }`}
                >
                  <td className="py-2.5 px-3 font-mono text-zinc-500 text-[11px]">{idx + 1}</td>
                  
                  {/* Filename & Icon */}
                  <td className="py-2.5 px-3">
                    <div className="flex items-center gap-2 max-w-md">
                      <div className="shrink-0">{getCategoryIcon(task.category)}</div>
                      <div className="truncate">
                        <div className="font-medium truncate text-zinc-200 text-xs" title={task.filename}>
                          {task.filename}
                        </div>
                        <div className="text-[10px] text-zinc-500 truncate max-w-xs" title={task.url}>
                          {task.url}
                        </div>
                      </div>
                    </div>
                  </td>

                  {/* Size */}
                  <td className="py-2.5 px-3 whitespace-nowrap text-zinc-400 font-mono text-[11px]">
                    <div>{formatBytes(task.downloadedBytes)}</div>
                    <div className="text-[10px] text-zinc-500">of {task.totalBytes > 0 ? formatBytes(task.totalBytes) : 'Unknown'}</div>
                  </td>

                  {/* Status */}
                  <td className="py-2.5 px-3 whitespace-nowrap">
                    {getStatusBadge(task.status)}
                  </td>

                  {/* Progress Bar & Segments */}
                  <td className="py-2.5 px-3">
                    <div className="space-y-1">
                      <div className="flex justify-between text-[10px] font-mono text-zinc-400">
                        <span>{percent.toFixed(1)}%</span>
                        <span>{task.connectionCount} conn</span>
                      </div>
                      <div className="w-full bg-zinc-800 rounded-full h-1.5 overflow-hidden">
                        <div 
                          className={`h-full rounded-full transition-all duration-300 ${
                            task.status === 'completed'
                              ? 'bg-emerald-500'
                              : task.status === 'paused'
                              ? 'bg-amber-500'
                              : task.status === 'failed'
                              ? 'bg-rose-500'
                              : 'bg-sky-500'
                          }`}
                          style={{ width: `${percent}%` }}
                        />
                      </div>
                    </div>
                  </td>

                  {/* Speed with Stuck / Slow Warning & Reload */}
                  <td className="py-2.5 px-3 whitespace-nowrap font-mono text-[11px]">
                    {task.status === 'downloading' ? (
                      (task.isStuck || (task.speed === 0 && (task.stuckDuration || 0) >= 3)) ? (
                        <div className="flex items-center gap-1.5">
                          <span 
                            className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-amber-500/20 text-amber-300 border border-amber-500/40 animate-pulse"
                            title="Connection stalled at 0 KB/s. Click Reload to reconnect threads."
                          >
                            <AlertTriangle className="w-2.5 h-2.5" />
                            Stuck
                          </span>
                          {onReload && (
                            <button
                              id={`btn-reload-stuck-${task.id}`}
                              onClick={(e) => {
                                e.stopPropagation();
                                onReload(task.id);
                              }}
                              className="p-1 rounded bg-amber-500/20 hover:bg-amber-500/40 text-amber-300 border border-amber-500/40 transition-colors"
                              title="Reload connections (re-establish threads without losing progress)"
                            >
                              <RotateCcw className="w-3 h-3" />
                            </button>
                          )}
                        </div>
                      ) : (task.isSlow || (task.speed > 0 && task.speed < 30 * 1024)) ? (
                        <div className="flex items-center gap-1.5">
                          <span className="text-amber-400 font-medium" title="Slow throughput detected">
                            {formatSpeed(task.speed)}
                          </span>
                          {onReload && (
                            <button
                              id={`btn-reload-slow-${task.id}`}
                              onClick={(e) => {
                                e.stopPropagation();
                                onReload(task.id);
                              }}
                              className="p-1 rounded bg-zinc-800 hover:bg-amber-600/30 text-amber-400 border border-zinc-700 transition-colors"
                              title="Reload connections to boost throughput"
                            >
                              <RotateCcw className="w-3 h-3" />
                            </button>
                          )}
                        </div>
                      ) : (
                        <div className="flex items-center gap-1 text-sky-400 font-medium">
                          <span>{formatSpeed(task.speed)}</span>
                          {task.reloadCount && task.reloadCount > 0 ? (
                            <span className="text-[9px] px-1 py-0.2 bg-sky-950 text-sky-300 border border-sky-800 rounded font-mono" title={`Reloaded ${task.reloadCount} times`}>
                              ⚡{task.reloadCount}
                            </span>
                          ) : null}
                        </div>
                      )
                    ) : (
                      <span className="text-zinc-500">--</span>
                    )}
                  </td>

                  {/* ETA / Completed Time */}
                  <td className="py-2.5 px-3 whitespace-nowrap font-mono text-[11px] text-zinc-400">
                    {task.status === 'downloading' ? (
                      formatEta(task.eta)
                    ) : task.status === 'completed' ? (
                      <span className="text-zinc-400 text-[10px]" title={task.completedAt ? new Date(task.completedAt).toLocaleString() : ''}>
                        {formatCompletionTime(task.completedAt)}
                      </span>
                    ) : (
                      '--'
                    )}
                  </td>

                  {/* Category */}
                  <td className="py-2.5 px-3 whitespace-nowrap text-[11px]">
                    <div className="flex items-center gap-1.5" title={`Destination: ${task.savePath}`}>
                      <span className="text-zinc-300 font-medium">{task.category}</span>
                      {task.movedToCategoryFolder && (
                        <span className="text-[9px] px-1 py-0.2 bg-emerald-950/80 text-emerald-400 border border-emerald-800/60 rounded font-mono" title={`Auto-organized to ${task.category} folder: ${task.savePath}`}>
                          Organized
                        </span>
                      )}
                    </div>
                    <div className="text-[9px] text-zinc-500 font-mono truncate max-w-[140px]" title={task.savePath}>
                      {task.savePath.includes('\\') ? task.savePath.split('\\').slice(-2).join('\\') : task.savePath}
                    </div>
                  </td>

                  {/* Actions Dropdown Button */}
                  <td className="py-2.5 px-3 text-center">
                    <button
                      id={`download-menu-btn-${task.id}`}
                      onClick={(e) => {
                        e.stopPropagation();
                        handleContextMenu(e, task);
                      }}
                      className="p-1 rounded text-zinc-400 hover:text-white hover:bg-zinc-700 transition-colors"
                    >
                      <MoreVertical className="w-3.5 h-3.5" />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}

      {/* Windows Context Menu */}
      {contextMenu && (
        <div
          id="download-context-menu"
          style={{ top: contextMenu.y, left: Math.min(contextMenu.x, window.innerWidth - 220) }}
          className="fixed z-50 w-52 bg-[#222226] border border-zinc-700 shadow-2xl rounded-md py-1 text-xs text-zinc-200 select-none animation-fadeIn"
          onClick={(e) => e.stopPropagation()}
        >
          {contextMenu.task.status === 'downloading' ? (
            <>
              <button
                onClick={() => { onPause(contextMenu.task.id); closeContextMenu(); }}
                className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-zinc-700 text-left text-amber-400"
              >
                <Pause className="w-3.5 h-3.5" />
                <span>Pause Download</span>
              </button>
              {onReload && (
                <button
                  id="context-btn-reload"
                  onClick={() => { onReload(contextMenu.task.id); closeContextMenu(); }}
                  className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-zinc-700 text-left text-amber-300 font-medium"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>Reload Connections (Fix Slow / Stuck)</span>
                </button>
              )}
            </>
          ) : contextMenu.task.status !== 'completed' ? (
            <button
              onClick={() => { onResume(contextMenu.task.id); closeContextMenu(); }}
              className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-zinc-700 text-left text-emerald-400"
            >
              <Play className="w-3.5 h-3.5" />
              <span>Resume Download</span>
            </button>
          ) : null}

          {contextMenu.task.status === 'completed' && (
            <>
              <button
                onClick={() => { onOpenFile(contextMenu.task); closeContextMenu(); }}
                className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-zinc-700 text-left text-sky-400 font-medium"
              >
                <ExternalLink className="w-3.5 h-3.5" />
                <span>Open File</span>
              </button>
              <button
                onClick={() => { onOpenFolder(contextMenu.task); closeContextMenu(); }}
                className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-zinc-700 text-left text-zinc-200"
              >
                <FolderOpen className="w-3.5 h-3.5" />
                <span>Open Containing Folder</span>
              </button>
              <button
                onClick={() => { onVerifyChecksum(contextMenu.task); closeContextMenu(); }}
                className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-zinc-700 text-left text-emerald-300"
              >
                <ShieldCheck className="w-3.5 h-3.5" />
                <span>Verify SHA-256 Checksum</span>
              </button>
            </>
          )}

          <div className="h-px bg-zinc-700 my-1" />

          <button
            onClick={() => { onRetry(contextMenu.task.id); closeContextMenu(); }}
            className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-zinc-700 text-left text-zinc-300"
          >
            <RotateCw className="w-3.5 h-3.5" />
            <span>Re-download from Scratch</span>
          </button>

          <button
            onClick={() => {
              navigator.clipboard.writeText(contextMenu.task.url);
              closeContextMenu();
            }}
            className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-zinc-700 text-left text-zinc-300"
          >
            <Copy className="w-3.5 h-3.5" />
            <span>Copy Download Link</span>
          </button>

          <div className="h-px bg-zinc-700 my-1" />

          <button
            onClick={() => { onDelete(contextMenu.task.id); closeContextMenu(); }}
            className="w-full flex items-center gap-2 px-3 py-1.5 hover:bg-rose-900/40 text-left text-rose-400"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span>{contextMenu.task.status === 'completed' ? 'Remove from History' : 'Delete Download'}</span>
          </button>
        </div>
      )}
    </div>
  );
};
