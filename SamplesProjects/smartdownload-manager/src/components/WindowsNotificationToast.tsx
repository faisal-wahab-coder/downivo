import React from 'react';
import { CheckCircle2, Download, AlertCircle, X, ExternalLink, FolderOpen } from 'lucide-react';
import { DownloadTask } from '../types';
import { formatBytes } from '../services/downloadEngine';

interface WindowsNotificationToastProps {
  notification: {
    id: string;
    title: string;
    message: string;
    type: 'completed' | 'started' | 'failed';
    task?: DownloadTask;
  } | null;
  onClose: () => void;
  onOpenFile?: (task: DownloadTask) => void;
  onOpenFolder?: (task: DownloadTask) => void;
}

export const WindowsNotificationToast: React.FC<WindowsNotificationToastProps> = ({
  notification,
  onClose,
  onOpenFile,
  onOpenFolder,
}) => {
  if (!notification) return null;

  return (
    <aside 
      aria-label="Windows Action Center Notification"
      id="windows-notification-toast"
      className="fixed bottom-6 right-6 z-50 w-84 bg-[#1f1f23] border border-zinc-700 rounded-xl shadow-2xl p-3.5 text-zinc-100 animate-slideUp backdrop-blur-md select-none"
    >
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-2">
          {notification.type === 'completed' ? (
            <div className="w-6 h-6 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center">
              <CheckCircle2 className="w-4 h-4" />
            </div>
          ) : notification.type === 'started' ? (
            <div className="w-6 h-6 rounded-full bg-sky-500/20 text-sky-400 flex items-center justify-center">
              <Download className="w-4 h-4" />
            </div>
          ) : (
            <div className="w-6 h-6 rounded-full bg-rose-500/20 text-rose-400 flex items-center justify-center">
              <AlertCircle className="w-4 h-4" />
            </div>
          )}
          <div>
            <div className="text-[10px] text-zinc-400 font-semibold uppercase tracking-wider">SmartDownload Manager</div>
            <div className="font-bold text-xs text-zinc-100">{notification.title}</div>
          </div>
        </div>

        <button 
          onClick={onClose} 
          className="text-zinc-500 hover:text-white p-1"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>

      <div className="mt-2 text-xs text-zinc-300">
        {notification.message}
      </div>

      {notification.task && notification.type === 'completed' && (
        <div className="mt-3 pt-2 border-t border-zinc-800 flex gap-2">
          <button
            onClick={() => {
              if (onOpenFile && notification.task) onOpenFile(notification.task);
              onClose();
            }}
            className="flex-1 py-1.5 bg-sky-600 hover:bg-sky-500 text-white rounded text-xs font-semibold flex items-center justify-center gap-1 shadow-sm"
          >
            <ExternalLink className="w-3 h-3" />
            <span>Open File</span>
          </button>
          <button
            onClick={() => {
              if (onOpenFolder && notification.task) onOpenFolder(notification.task);
              onClose();
            }}
            className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded text-xs font-medium flex items-center gap-1"
          >
            <FolderOpen className="w-3 h-3" />
            <span>Open Folder</span>
          </button>
        </div>
      )}
    </aside>
  );
};
