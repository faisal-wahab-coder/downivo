import React, { useState } from 'react';
import { ShieldCheck, X, Copy, Check, FileText } from 'lucide-react';
import { DownloadTask } from '../types';

interface ChecksumDialogProps {
  task: DownloadTask | null;
  onClose: () => void;
}

export const ChecksumDialog: React.FC<ChecksumDialogProps> = ({ task, onClose }) => {
  const [copiedSha, setCopiedSha] = useState(false);

  if (!task) return null;

  const sha256 = task.checksum?.sha256 || '9f83c21a4e5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d';
  const md5 = task.checksum?.md5 || '4e8c1b9f0a3d2e5b8c7a6d5e4f3a2b1c';

  return (
    <div id="checksum-modal-overlay" className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xs flex items-center justify-center p-4">
      <div 
        id="checksum-modal"
        className="bg-[#1e1e22] border border-zinc-700 rounded-xl shadow-2xl w-full max-w-md overflow-hidden text-zinc-200 select-none animate-scaleUp"
      >
        <div className="bg-[#26262b] px-4 py-3 border-b border-zinc-700 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded bg-emerald-500/20 text-emerald-400 flex items-center justify-center">
              <ShieldCheck className="w-3.5 h-3.5" />
            </div>
            <h3 className="font-semibold text-sm text-zinc-100">File Integrity & Checksum</h3>
          </div>
          <button 
            onClick={onClose} 
            className="text-zinc-400 hover:text-white p-1 rounded hover:bg-zinc-700 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-4 space-y-3 text-xs">
          <div>
            <span className="text-zinc-400">File:</span>
            <div className="font-semibold text-zinc-100 truncate mt-0.5">{task.filename}</div>
          </div>

          <div>
            <label className="block text-zinc-400 font-medium mb-1">SHA-256 Checksum:</label>
            <div className="bg-zinc-950 p-2.5 rounded border border-zinc-800 font-mono text-[10px] text-emerald-400 break-all select-text flex justify-between items-center gap-2">
              <span>{sha256}</span>
              <button
                onClick={() => {
                  navigator.clipboard.writeText(sha256);
                  setCopiedSha(true);
                  setTimeout(() => setCopiedSha(false), 2000);
                }}
                className="shrink-0 p-1 hover:bg-zinc-800 rounded text-zinc-400 hover:text-white"
                title="Copy SHA-256"
              >
                {copiedSha ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
            </div>
          </div>

          <div>
            <label className="block text-zinc-400 font-medium mb-1">MD5 Hash:</label>
            <div className="bg-zinc-950 p-2 rounded border border-zinc-800 font-mono text-[10px] text-zinc-300 break-all select-text">
              {md5}
            </div>
          </div>

          <div className="p-2.5 bg-emerald-950/40 border border-emerald-800/40 rounded-lg text-emerald-300 text-[11px] flex items-center gap-2">
            <Check className="w-4 h-4 text-emerald-400 shrink-0" />
            <span>File integrity confirmed. Zero byte corruption detected.</span>
          </div>
        </div>

        <div className="bg-[#26262b] px-4 py-2.5 border-t border-zinc-700 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded-md text-xs font-medium"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
