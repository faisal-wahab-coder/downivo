import React, { useState } from 'react';
import { 
  Trash2, 
  History, 
  AlertTriangle, 
  X, 
  CheckCircle2, 
  HardDrive,
  Info
} from 'lucide-react';

interface ClearHistoryModalProps {
  isOpen: boolean;
  onClose: () => void;
  completedCount: number;
  totalFinishedBytes: number;
  onConfirmClear: (includeFailed: boolean) => void;
}

export const ClearHistoryModal: React.FC<ClearHistoryModalProps> = ({
  isOpen,
  onClose,
  completedCount,
  totalFinishedBytes,
  onConfirmClear,
}) => {
  const [includeFailed, setIncludeFailed] = useState(false);

  if (!isOpen) return null;

  const formatSize = (bytes: number) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${(bytes / Math.pow(k, i)).toFixed(1)} ${sizes[i]}`;
  };

  return (
    <div 
      id="clear-history-modal-overlay"
      className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 select-none animation-fadeIn"
      onClick={onClose}
    >
      <div 
        id="clear-history-modal"
        className="bg-[#202024] border border-zinc-700 w-full max-w-md rounded-lg shadow-2xl overflow-hidden flex flex-col text-zinc-200"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div className="bg-[#18181b] border-b border-zinc-800 px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2 text-sm font-semibold text-zinc-100">
            <div className="p-1 rounded bg-rose-500/20 text-rose-400 border border-rose-500/30">
              <History className="w-4 h-4" />
            </div>
            <span>Clear Download History</span>
          </div>
          <button 
            id="btn-close-clear-history-modal"
            onClick={onClose}
            className="text-zinc-400 hover:text-white p-1 rounded-md hover:bg-zinc-800 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Modal Content */}
        <div className="p-5 space-y-4 text-xs">
          <div className="flex items-start gap-3 p-3 bg-zinc-900/90 border border-zinc-800 rounded-md">
            <Info className="w-4 h-4 text-sky-400 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <p className="text-zinc-200 font-medium">
                You are about to clear <span className="font-bold text-white">{completedCount} completed {completedCount === 1 ? 'task' : 'tasks'}</span> ({formatSize(totalFinishedBytes)}) from your download history.
              </p>
              <p className="text-[11px] text-zinc-400">
                Downloaded files in your category folders (<span className="text-zinc-300 font-mono">Downloads\</span>) will <strong className="text-emerald-400">remain safe and intact on your disk</strong>. Only manager tracking history will be cleared.
              </p>
            </div>
          </div>

          {/* Option to also clear failed tasks */}
          <label className="flex items-center gap-2.5 p-2 rounded bg-zinc-800/40 hover:bg-zinc-800/70 border border-zinc-700/60 cursor-pointer transition-colors">
            <input 
              id="checkbox-include-failed"
              type="checkbox"
              checked={includeFailed}
              onChange={(e) => setIncludeFailed(e.target.checked)}
              className="accent-rose-500 rounded cursor-pointer"
            />
            <span className="text-zinc-300">Also clear failed and cancelled download records</span>
          </label>
        </div>

        {/* Modal Footer */}
        <div className="bg-[#18181b] border-t border-zinc-800 px-4 py-3 flex items-center justify-end gap-2">
          <button
            id="btn-cancel-clear-history"
            onClick={onClose}
            className="px-3.5 py-1.5 rounded-md text-xs font-medium text-zinc-300 hover:bg-zinc-800 border border-zinc-700 transition-colors"
          >
            Cancel
          </button>
          <button
            id="btn-confirm-clear-history"
            onClick={() => {
              onConfirmClear(includeFailed);
              onClose();
            }}
            className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-md text-xs font-semibold bg-rose-600 hover:bg-rose-500 text-white shadow-sm transition-all"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span>Clear History</span>
          </button>
        </div>
      </div>
    </div>
  );
};
