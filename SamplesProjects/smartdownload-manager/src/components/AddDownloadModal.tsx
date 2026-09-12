import React, { useState, useEffect } from 'react';
import { 
  X, 
  Download, 
  FolderOpen, 
  Sliders, 
  Layers, 
  Check, 
  Loader2, 
  Sparkles, 
  ShieldCheck, 
  FileCode, 
  Clock,
  FolderTree
} from 'lucide-react';
import { formatBytes, inferCategory, getCategoryFolderPath } from '../services/downloadEngine';
import { DownloadCategory, CategoriesSettings } from '../types';

interface AddDownloadModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (data: {
    url: string;
    filename: string;
    category: DownloadCategory;
    savePath: string;
    connections: number;
    startImmediately: boolean;
    totalBytes: number;
  }) => void;
  initialUrl?: string;
  initialFilename?: string;
  initialSize?: number;
  categoriesSettings?: CategoriesSettings;
}

export const AddDownloadModal: React.FC<AddDownloadModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  initialUrl = '',
  initialFilename = '',
  initialSize,
  categoriesSettings,
}) => {
  const [url, setUrl] = useState(initialUrl);
  const [filename, setFilename] = useState(initialFilename);
  const [category, setCategory] = useState<DownloadCategory>('Archives');
  const [savePath, setSavePath] = useState(
    categoriesSettings ? getCategoryFolderPath('Archives', categoriesSettings) : 'C:\\Users\\User\\Downloads\\Archives'
  );
  const [connections, setConnections] = useState(8);
  const [isProbing, setIsProbing] = useState(false);
  const [probedSize, setProbedSize] = useState<number | null>(initialSize || null);
  const [acceptRanges, setAcceptRanges] = useState(true);

  useEffect(() => {
    if (isOpen) {
      setUrl(initialUrl || '/api/test-files/ubuntu-24.04-desktop-amd64.iso');
      if (initialUrl) {
        probeUrl(initialUrl);
      } else {
        probeUrl('/api/test-files/ubuntu-24.04-desktop-amd64.iso');
      }
    }
  }, [isOpen, initialUrl]);

  const probeUrl = async (targetUrl: string) => {
    if (!targetUrl) return;
    setIsProbing(true);
    try {
      const res = await fetch('/api/download/probe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: targetUrl }),
      });
      const data = await res.json();
      if (data.filename) {
        setFilename(data.filename);
        const inferred = inferCategory(data.filename, categoriesSettings?.customExtensions);
        setCategory(inferred);
        if (categoriesSettings) {
          setSavePath(getCategoryFolderPath(inferred, categoriesSettings));
        } else {
          setSavePath(`C:\\Users\\User\\Downloads\\${inferred !== 'Other' ? inferred : ''}`);
        }
      }
      if (data.size) setProbedSize(data.size);
      if (data.acceptRanges !== undefined) setAcceptRanges(data.acceptRanges);
    } catch (err) {
      console.warn("Probe failed, using fallback:", err);
      const fname = targetUrl.split('/').pop() || 'download.bin';
      setFilename(fname);
      const inferred = inferCategory(fname, categoriesSettings?.customExtensions);
      setCategory(inferred);
      if (categoriesSettings) {
        setSavePath(getCategoryFolderPath(inferred, categoriesSettings));
      } else {
        setSavePath(`C:\\Users\\User\\Downloads\\${inferred !== 'Other' ? inferred : ''}`);
      }
      setProbedSize(25 * 1024 * 1024);
    } finally {
      setIsProbing(false);
    }
  };

  if (!isOpen) return null;

  const handleSubmit = (startImmediately: boolean) => {
    if (!url.trim()) return;
    onConfirm({
      url: url.trim(),
      filename: filename.trim() || 'download.bin',
      category,
      savePath: `${savePath.replace(/[\\/]+$/, '')}\\${filename.trim() || 'download.bin'}`,
      connections,
      startImmediately,
      totalBytes: probedSize || 25 * 1024 * 1024,
    });
    onClose();
  };

  const sampleUrls = [
    { label: 'Ubuntu 24.04 ISO (50 MB)', url: '/api/test-files/ubuntu-24.04-desktop-amd64.iso' },
    { label: 'Nature 4K Video (25 MB)', url: '/api/test-files/nature_4k_cinematic_landscape.mp4' },
    { label: 'Dev Toolchain EXE (15 MB)', url: '/api/test-files/developer_toolchain_v3.4.1_setup.exe' },
    { label: 'Lofi Audio MP3 (5 MB)', url: '/api/test-files/lofi_ambient_coding_session.mp3' },
  ];

  return (
    <div id="add-download-modal-overlay" className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xs flex items-center justify-center p-4">
      <div 
        id="add-download-modal"
        className="bg-[#1e1e22] border border-zinc-700 rounded-xl shadow-2xl w-full max-w-lg overflow-hidden text-zinc-200 select-none animate-scaleUp"
      >
        {/* Header */}
        <div className="bg-[#26262b] px-4 py-3 border-b border-zinc-700 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded bg-sky-500/20 text-sky-400 flex items-center justify-center">
              <Download className="w-3.5 h-3.5" />
            </div>
            <h3 className="font-semibold text-sm text-zinc-100">Download File Information</h3>
          </div>
          <button 
            id="btn-close-modal"
            onClick={onClose} 
            className="text-zinc-400 hover:text-white p-1 rounded hover:bg-zinc-700 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Content */}
        <div className="p-4 space-y-3.5 text-xs">
          {/* URL Input */}
          <div>
            <label className="block text-zinc-400 font-medium mb-1">Download Address (URL):</label>
            <div className="flex gap-2">
              <input
                id="input-download-url"
                type="text"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                onBlur={() => probeUrl(url)}
                placeholder="https://example.com/file.zip"
                className="flex-1 bg-zinc-900 border border-zinc-700 text-zinc-100 px-3 py-1.5 rounded-md focus:outline-none focus:border-sky-500 font-mono text-[11px]"
              />
              <button
                id="btn-probe-url"
                onClick={() => probeUrl(url)}
                disabled={isProbing}
                className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded-md font-medium flex items-center gap-1.5"
              >
                {isProbing ? <Loader2 className="w-3.5 h-3.5 animate-spin text-sky-400" /> : 'Inspect'}
              </button>
            </div>

            {/* Quick Test Samples */}
            <div className="flex items-center gap-1.5 mt-1.5 flex-wrap">
              <span className="text-[10px] text-zinc-500">Quick Test:</span>
              {sampleUrls.map((s, i) => (
                <button
                  key={i}
                  id={`sample-preset-${i}`}
                  onClick={() => {
                    setUrl(s.url);
                    probeUrl(s.url);
                  }}
                  className="px-2 py-0.5 bg-zinc-800/80 hover:bg-sky-900/40 text-zinc-400 hover:text-sky-300 rounded text-[10px] border border-zinc-700 transition-colors"
                >
                  {s.label}
                </button>
              ))}
            </div>
          </div>

          {/* Filename & Category */}
          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-2">
              <label className="block text-zinc-400 font-medium mb-1">File Name:</label>
              <input
                id="input-download-filename"
                type="text"
                value={filename}
                onChange={(e) => {
                  const val = e.target.value;
                  setFilename(val);
                  const inferred = inferCategory(val, categoriesSettings?.customExtensions);
                  setCategory(inferred);
                  if (categoriesSettings) {
                    setSavePath(getCategoryFolderPath(inferred, categoriesSettings));
                  }
                }}
                className="w-full bg-zinc-900 border border-zinc-700 text-zinc-100 px-3 py-1.5 rounded-md focus:outline-none focus:border-sky-500 font-mono text-[11px]"
              />
            </div>

            <div>
              <label className="block text-zinc-400 font-medium mb-1">Category:</label>
              <select
                id="select-download-category"
                value={category}
                onChange={(e) => {
                  const newCat = e.target.value as DownloadCategory;
                  setCategory(newCat);
                  if (categoriesSettings) {
                    setSavePath(getCategoryFolderPath(newCat, categoriesSettings));
                  } else {
                    setSavePath(`C:\\Users\\User\\Downloads\\${newCat !== 'Other' ? newCat : ''}`);
                  }
                }}
                className="w-full bg-zinc-900 border border-zinc-700 text-zinc-100 px-2 py-1.5 rounded-md focus:outline-none focus:border-sky-500 text-xs"
              >
                <option value="Videos">Videos</option>
                <option value="Music">Music</option>
                <option value="Documents">Documents</option>
                <option value="Images">Images</option>
                <option value="Programs">Programs</option>
                <option value="Archives">Archives</option>
                <option value="Other">Other</option>
              </select>
            </div>
          </div>

          {/* Save Directory */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="text-zinc-400 font-medium">Save Path (Destination Folder):</label>
              <span className="text-[10px] text-sky-400 font-mono flex items-center gap-1">
                <FolderTree className="w-3 h-3" />
                <span>Auto-routed to {category}</span>
              </span>
            </div>
            <div className="flex gap-2">
              <input
                id="input-save-path"
                type="text"
                value={savePath}
                onChange={(e) => setSavePath(e.target.value)}
                className="flex-1 bg-zinc-900 border border-zinc-700 text-zinc-300 px-3 py-1.5 rounded-md font-mono text-[11px]"
              />
              <button 
                id="btn-browse-folder"
                onClick={() => {
                  if (categoriesSettings) {
                    setSavePath(getCategoryFolderPath(category, categoriesSettings));
                  } else {
                    setSavePath(`C:\\Users\\User\\Downloads\\${category !== 'Other' ? category : ''}`);
                  }
                }}
                title="Reset to category default"
                className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded-md font-medium flex items-center gap-1 text-xs"
              >
                <FolderOpen className="w-3.5 h-3.5 text-sky-400" />
                <span>Reset</span>
              </button>
            </div>
          </div>

          {/* Connections & Probed Info */}
          <div className="bg-zinc-900/80 p-3 rounded-lg border border-zinc-800 space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="text-zinc-400">Estimated File Size:</span>
              <span className="font-semibold text-zinc-200 font-mono">
                {probedSize ? formatBytes(probedSize) : 'Probing size...'}
              </span>
            </div>

            <div className="flex items-center justify-between text-xs">
              <span className="text-zinc-400">Server Byte-Range Support:</span>
              <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                acceptRanges 
                  ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' 
                  : 'bg-amber-500/20 text-amber-400'
              }`}>
                {acceptRanges ? 'Accept-Ranges: bytes (Multi-Thread Supported)' : 'Single Connection Only'}
              </span>
            </div>

            {/* Parallel Connections Slider */}
            <div>
              <div className="flex items-center justify-between text-xs mb-1">
                <span className="text-zinc-400 flex items-center gap-1">
                  <Layers className="w-3 h-3 text-sky-400" /> Max Connections:
                </span>
                <span className="font-bold text-sky-400">{connections} Parallel Threads</span>
              </div>
              <input
                id="slider-connections"
                type="range"
                min="1"
                max="16"
                step="1"
                value={connections}
                onChange={(e) => setConnections(parseInt(e.target.value, 10))}
                className="w-full accent-sky-500 cursor-pointer"
              />
              <div className="flex justify-between text-[9px] text-zinc-500">
                <span>1 (Single)</span>
                <span>4</span>
                <span>8 (Recommended)</span>
                <span>16 (Max)</span>
              </div>
            </div>
          </div>
        </div>

        {/* Footer Buttons */}
        <div className="bg-[#26262b] px-4 py-3 border-t border-zinc-700 flex items-center justify-between">
          <button
            id="btn-cancel-download"
            onClick={onClose}
            className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded-md text-xs font-medium transition-colors"
          >
            Cancel
          </button>

          <div className="flex items-center gap-2">
            <button
              id="btn-download-later"
              onClick={() => handleSubmit(false)}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-purple-300 border border-zinc-700 rounded-md text-xs font-medium transition-all"
            >
              <Clock className="w-3.5 h-3.5" />
              <span>Download Later</span>
            </button>

            <button
              id="btn-start-download-now"
              onClick={() => handleSubmit(true)}
              className="flex items-center gap-1.5 px-4 py-1.5 bg-sky-600 hover:bg-sky-500 active:bg-sky-700 text-white rounded-md text-xs font-semibold shadow-md transition-all"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Start Download</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
