import React from 'react';
import { 
  Download, 
  CheckCircle2, 
  PauseCircle, 
  AlertCircle, 
  Clock, 
  Folder, 
  Video, 
  Music, 
  FileText, 
  Image as ImageIcon, 
  Box, 
  Archive, 
  Layers, 
  Calendar,
  HardDrive,
  History
} from 'lucide-react';
import { DownloadTask, CategoryInfo } from '../types';

export type FilterCategory = 'all' | 'history' | 'downloading' | 'completed' | 'paused' | 'failed' | 'queued' | 'Videos' | 'Music' | 'Documents' | 'Images' | 'Programs' | 'Archives' | 'Other';

interface SidebarProps {
  selectedFilter: FilterCategory;
  onSelectFilter: (filter: FilterCategory) => void;
  downloads: DownloadTask[];
}

export const Sidebar: React.FC<SidebarProps> = ({
  selectedFilter,
  onSelectFilter,
  downloads,
}) => {
  const countByStatus = {
    all: downloads.length,
    downloading: downloads.filter(d => d.status === 'downloading' || d.status === 'connecting').length,
    completed: downloads.filter(d => d.status === 'completed').length,
    paused: downloads.filter(d => d.status === 'paused').length,
    failed: downloads.filter(d => d.status === 'failed').length,
    queued: downloads.filter(d => d.status === 'queued').length,
  };

  const countByCategory = {
    Videos: downloads.filter(d => d.category === 'Videos').length,
    Music: downloads.filter(d => d.category === 'Music').length,
    Documents: downloads.filter(d => d.category === 'Documents').length,
    Images: downloads.filter(d => d.category === 'Images').length,
    Programs: downloads.filter(d => d.category === 'Programs').length,
    Archives: downloads.filter(d => d.category === 'Archives').length,
    Other: downloads.filter(d => d.category === 'Other').length,
  };

  const navItemClass = (id: FilterCategory) =>
    `w-full flex items-center justify-between px-2.5 py-1.5 rounded-md text-xs font-medium transition-colors ${
      selectedFilter === id
        ? 'bg-sky-600/20 text-sky-400 border border-sky-500/30'
        : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/60 border border-transparent'
    }`;

  return (
    <aside id="app-sidebar" className="w-56 bg-[#1b1b1e] border-r border-[#2d2d32] p-2.5 flex flex-col justify-between select-none overflow-y-auto">
      <div className="space-y-4">
        {/* Status Section */}
        <div>
          <div className="text-[10px] font-bold uppercase tracking-wider text-zinc-500 px-2.5 mb-1.5">
            Tasks & Status
          </div>
          <div className="space-y-0.5">
            <button
              id="filter-all"
              onClick={() => onSelectFilter('all')}
              className={navItemClass('all')}
            >
              <div className="flex items-center gap-2">
                <Folder className="w-3.5 h-3.5 text-zinc-400" />
                <span>All Downloads</span>
              </div>
              <span className="text-[11px] bg-zinc-800 px-1.5 py-0.2 rounded text-zinc-400">{countByStatus.all}</span>
            </button>

            <button
              id="filter-downloading"
              onClick={() => onSelectFilter('downloading')}
              className={navItemClass('downloading')}
            >
              <div className="flex items-center gap-2">
                <Download className="w-3.5 h-3.5 text-sky-400" />
                <span>Downloading</span>
              </div>
              {countByStatus.downloading > 0 && (
                <span className="text-[11px] bg-sky-500/20 text-sky-400 px-1.5 py-0.2 rounded font-semibold">
                  {countByStatus.downloading}
                </span>
              )}
            </button>

            <button
              id="filter-completed"
              onClick={() => onSelectFilter('completed')}
              className={navItemClass('completed')}
            >
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                <span>Completed</span>
              </div>
              <span className="text-[11px] bg-zinc-800 px-1.5 py-0.2 rounded text-zinc-400">{countByStatus.completed}</span>
            </button>

            <button
              id="filter-history"
              onClick={() => onSelectFilter('history')}
              className={navItemClass('history')}
            >
              <div className="flex items-center gap-2">
                <History className="w-3.5 h-3.5 text-teal-400" />
                <span>Download History</span>
              </div>
              <span className="text-[11px] bg-teal-500/20 text-teal-300 px-1.5 py-0.2 rounded font-mono">{countByStatus.completed}</span>
            </button>

            <button
              id="filter-paused"
              onClick={() => onSelectFilter('paused')}
              className={navItemClass('paused')}
            >
              <div className="flex items-center gap-2">
                <PauseCircle className="w-3.5 h-3.5 text-amber-400" />
                <span>Paused</span>
              </div>
              {countByStatus.paused > 0 && (
                <span className="text-[11px] bg-amber-500/20 text-amber-400 px-1.5 py-0.2 rounded">{countByStatus.paused}</span>
              )}
            </button>

            <button
              id="filter-queued"
              onClick={() => onSelectFilter('queued')}
              className={navItemClass('queued')}
            >
              <div className="flex items-center gap-2">
                <Clock className="w-3.5 h-3.5 text-purple-400" />
                <span>Queued</span>
              </div>
              <span className="text-[11px] bg-zinc-800 px-1.5 py-0.2 rounded text-zinc-400">{countByStatus.queued}</span>
            </button>

            <button
              id="filter-failed"
              onClick={() => onSelectFilter('failed')}
              className={navItemClass('failed')}
            >
              <div className="flex items-center gap-2">
                <AlertCircle className="w-3.5 h-3.5 text-rose-400" />
                <span>Failed</span>
              </div>
              {countByStatus.failed > 0 && (
                <span className="text-[11px] bg-rose-500/20 text-rose-400 px-1.5 py-0.2 rounded">{countByStatus.failed}</span>
              )}
            </button>
          </div>
        </div>

        {/* Categories Section */}
        <div>
          <div className="text-[10px] font-bold uppercase tracking-wider text-zinc-500 px-2.5 mb-1.5">
            Categories
          </div>
          <div className="space-y-0.5">
            <button
              id="filter-cat-videos"
              onClick={() => onSelectFilter('Videos')}
              className={navItemClass('Videos')}
            >
              <div className="flex items-center gap-2">
                <Video className="w-3.5 h-3.5 text-red-400" />
                <span>Videos</span>
              </div>
              <span className="text-[11px] text-zinc-500">{countByCategory.Videos}</span>
            </button>

            <button
              id="filter-cat-music"
              onClick={() => onSelectFilter('Music')}
              className={navItemClass('Music')}
            >
              <div className="flex items-center gap-2">
                <Music className="w-3.5 h-3.5 text-indigo-400" />
                <span>Music</span>
              </div>
              <span className="text-[11px] text-zinc-500">{countByCategory.Music}</span>
            </button>

            <button
              id="filter-cat-docs"
              onClick={() => onSelectFilter('Documents')}
              className={navItemClass('Documents')}
            >
              <div className="flex items-center gap-2">
                <FileText className="w-3.5 h-3.5 text-blue-400" />
                <span>Documents</span>
              </div>
              <span className="text-[11px] text-zinc-500">{countByCategory.Documents}</span>
            </button>

            <button
              id="filter-cat-images"
              onClick={() => onSelectFilter('Images')}
              className={navItemClass('Images')}
            >
              <div className="flex items-center gap-2">
                <ImageIcon className="w-3.5 h-3.5 text-emerald-400" />
                <span>Images</span>
              </div>
              <span className="text-[11px] text-zinc-500">{countByCategory.Images}</span>
            </button>

            <button
              id="filter-cat-programs"
              onClick={() => onSelectFilter('Programs')}
              className={navItemClass('Programs')}
            >
              <div className="flex items-center gap-2">
                <Box className="w-3.5 h-3.5 text-amber-400" />
                <span>Programs</span>
              </div>
              <span className="text-[11px] text-zinc-500">{countByCategory.Programs}</span>
            </button>

            <button
              id="filter-cat-archives"
              onClick={() => onSelectFilter('Archives')}
              className={navItemClass('Archives')}
            >
              <div className="flex items-center gap-2">
                <Archive className="w-3.5 h-3.5 text-orange-400" />
                <span>Archives</span>
              </div>
              <span className="text-[11px] text-zinc-500">{countByCategory.Archives}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Storage Disk indicator */}
      <div className="pt-3 border-t border-zinc-800/80">
        <div className="flex items-center gap-2 text-zinc-400 text-xs mb-1.5">
          <HardDrive className="w-3.5 h-3.5 text-sky-400" />
          <span className="font-medium text-zinc-300">Drive C: (System)</span>
        </div>
        <div className="w-full bg-zinc-800 rounded-full h-1.5 overflow-hidden">
          <div className="bg-sky-500 h-full rounded-full w-[42%]" />
        </div>
        <div className="flex justify-between text-[10px] text-zinc-500 mt-1">
          <span>248 GB free</span>
          <span>512 GB SSD</span>
        </div>
      </div>
    </aside>
  );
};
