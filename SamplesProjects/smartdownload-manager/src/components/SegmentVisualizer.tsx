import React from 'react';
import { DownloadTask, DownloadSegment } from '../types';
import { formatBytes, formatSpeed } from '../services/downloadEngine';
import { Network, Layers, Zap } from 'lucide-react';

interface SegmentVisualizerProps {
  task: DownloadTask | null;
}

export const SegmentVisualizer: React.FC<SegmentVisualizerProps> = ({ task }) => {
  if (!task) {
    return (
      <div id="segment-visualizer-empty" className="h-36 bg-[#18181b] border-t border-[#2d2d32] p-4 flex flex-col items-center justify-center text-zinc-500 text-xs select-none">
        <Network className="w-5 h-5 mb-1 text-zinc-600" />
        <span>Select an active download task to monitor parallel thread segments</span>
      </div>
    );
  }

  const segments = task.segments || [];
  const percent = task.totalBytes > 0 
    ? Math.min(100, (task.downloadedBytes / task.totalBytes) * 100) 
    : 0;

  return (
    <div id="segment-visualizer" className="bg-[#18181b] border-t border-[#2d2d32] p-3 select-none flex flex-col gap-2.5">
      {/* Header Info */}
      <div className="flex items-center justify-between text-xs">
        <div className="flex items-center gap-2">
          <div className="p-1 rounded bg-sky-500/10 text-sky-400 border border-sky-500/20">
            <Layers className="w-3.5 h-3.5" />
          </div>
          <div>
            <span className="font-semibold text-zinc-200">{task.filename}</span>
            <span className="text-zinc-500 ml-2 text-[11px]">
              ({task.connectionCount} parallel connections • {formatBytes(task.downloadedBytes)} of {formatBytes(task.totalBytes)})
            </span>
          </div>
        </div>

        <div className="flex items-center gap-3 text-[11px]">
          <span className="text-zinc-400">
            Current Speed: <strong className="text-sky-400 font-semibold">{formatSpeed(task.speed)}</strong>
          </span>
          <span className="text-zinc-400">
            ETA: <strong className="text-emerald-400 font-semibold">{task.eta > 0 ? `${task.eta}s` : '--'}</strong>
          </span>
          <span className="px-2 py-0.5 rounded bg-zinc-800 text-zinc-300 font-mono">
            {percent.toFixed(1)}%
          </span>
        </div>
      </div>

      {/* Aggregate Overview Bar */}
      <div className="w-full bg-zinc-900 border border-zinc-800 rounded h-2.5 overflow-hidden flex">
        {segments.map((seg, i) => {
          const segPercent = seg.totalBytes > 0 ? (seg.downloadedBytes / seg.totalBytes) * 100 : 0;
          return (
            <div 
              key={`agg-seg-${i}`} 
              className="h-full border-r border-zinc-950/80 transition-all duration-300"
              style={{ 
                width: `${100 / segments.length}%`,
                background: segPercent >= 100 
                  ? '#10b981' 
                  : `linear-gradient(to right, #0284c7 ${segPercent}%, #27272a ${segPercent}%)`
              }}
              title={`Connection #${seg.id + 1}: ${segPercent.toFixed(0)}%`}
            />
          );
        })}
      </div>

      {/* Segment Grid (IDM-Style Connection Threads) */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-1.5 max-h-24 overflow-y-auto pr-1">
        {segments.map((seg) => {
          const segProgress = seg.totalBytes > 0 
            ? Math.min(100, (seg.downloadedBytes / seg.totalBytes) * 100) 
            : (task.status === 'completed' ? 100 : 0);
          
          return (
            <div
              key={`seg-card-${seg.id}`}
              id={`segment-thread-${seg.id}`}
              className="bg-zinc-900/90 border border-zinc-800/80 rounded p-1.5 flex flex-col justify-between text-[10px]"
            >
              <div className="flex items-center justify-between text-zinc-400 mb-1">
                <span className="font-mono font-medium text-zinc-300">Conn #{seg.id + 1}</span>
                <span className={`px-1 rounded text-[9px] ${
                  segProgress >= 100 
                    ? 'bg-emerald-500/20 text-emerald-300' 
                    : task.status === 'downloading'
                    ? 'bg-sky-500/20 text-sky-300 animate-pulse'
                    : 'bg-zinc-800 text-zinc-400'
                }`}>
                  {segProgress >= 100 ? 'DONE' : `${segProgress.toFixed(0)}%`}
                </span>
              </div>

              {/* Mini Segment Progress Bar */}
              <div className="w-full bg-zinc-800 rounded-sm h-1.5 overflow-hidden mb-1">
                <div 
                  className={`h-full transition-all duration-300 ${
                    segProgress >= 100 ? 'bg-emerald-500' : 'bg-sky-500'
                  }`}
                  style={{ width: `${segProgress}%` }}
                />
              </div>

              <div className="flex justify-between text-[9px] text-zinc-500">
                <span>{formatBytes(seg.downloadedBytes)}</span>
                <span>{task.status === 'downloading' ? formatSpeed(seg.speed) : '--'}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
