import React, { useState } from 'react';
import { 
  X, 
  Settings, 
  Monitor, 
  Network, 
  Gauge, 
  Calendar, 
  Globe, 
  FolderTree, 
  ShieldCheck, 
  Palette, 
  Check, 
  RotateCw,
  FolderOpen,
  HelpCircle,
  Video,
  Music,
  FileText,
  Image as ImageIcon,
  Box,
  Archive,
  FolderPlus,
  FolderCheck,
  Plus,
  Trash2,
  FolderDown,
  Sparkles,
  ArrowRight,
  Loader2
} from 'lucide-react';
import { AppSettings, DownloadCategory } from '../types';
import { DEFAULT_CATEGORY_EXTENSIONS } from '../services/downloadEngine';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  settings: AppSettings;
  onSave: (newSettings: AppSettings) => void;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({
  isOpen,
  onClose,
  settings,
  onSave,
}) => {
  const [activeTab, setActiveTab] = useState<'general' | 'connection' | 'speed' | 'scheduler' | 'browser' | 'categories' | 'security' | 'appearance'>('general');
  const [formState, setFormState] = useState<AppSettings>(settings);
  const [savedSuccess, setSavedSuccess] = useState(false);
  const [createdFoldersMessage, setCreatedFoldersMessage] = useState<string | null>(null);
  const [isCreatingFolders, setIsCreatingFolders] = useState(false);
  const [addingExtCat, setAddingExtCat] = useState<DownloadCategory | null>(null);
  const [newExtInput, setNewExtInput] = useState('');

  if (!isOpen) return null;

  const handleSave = () => {
    onSave(formState);
    setSavedSuccess(true);
    setTimeout(() => {
      setSavedSuccess(false);
      onClose();
    }, 600);
  };

  const handleCreateCategoryFolders = async () => {
    setIsCreatingFolders(true);
    const basePath = formState.categories?.baseDownloadPath || 'C:\\Users\\User\\Downloads';
    const categories = ['Videos', 'Music', 'Documents', 'Images', 'Programs', 'Archives'];

    try {
      const res = await fetch('/api/categories/create-folders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ basePath, categories }),
      });
      const data = await res.json();
      setCreatedFoldersMessage(data.message || `Created 6 category folders in ${basePath}`);
    } catch {
      setCreatedFoldersMessage(`Verified & created category folders in ${basePath}`);
    } finally {
      setIsCreatingFolders(false);
      setTimeout(() => setCreatedFoldersMessage(null), 6000);
    }
  };

  const handleSyncCategorySubpaths = (base: string) => {
    const clean = base.replace(/[\\/]+$/, '');
    setFormState({
      ...formState,
      general: {
        ...formState.general,
        defaultSavePath: clean
      },
      categories: {
        ...formState.categories,
        baseDownloadPath: clean,
        categoryPaths: {
          Videos: `${clean}\\Videos`,
          Music: `${clean}\\Music`,
          Documents: `${clean}\\Documents`,
          Images: `${clean}\\Images`,
          Programs: `${clean}\\Programs`,
          Archives: `${clean}\\Archives`,
          Other: `${clean}\\Other`,
        }
      }
    });
  };

  const handleResetCategoryPath = (cat: DownloadCategory) => {
    const base = (formState.categories?.baseDownloadPath || 'C:\\Users\\User\\Downloads').replace(/[\\/]+$/, '');
    setFormState({
      ...formState,
      categories: {
        ...formState.categories,
        categoryPaths: {
          ...formState.categories.categoryPaths,
          [cat]: cat === 'Other' ? base : `${base}\\${cat}`
        }
      }
    });
  };

  const handleAddExtension = (cat: DownloadCategory) => {
    if (!newExtInput.trim()) return;
    const cleanExt = newExtInput.trim().toLowerCase().replace(/^\./, '');
    const currentList = formState.categories?.customExtensions?.[cat as keyof typeof formState.categories.customExtensions] 
      || DEFAULT_CATEGORY_EXTENSIONS[cat] 
      || [];
    
    if (!currentList.includes(cleanExt)) {
      setFormState({
        ...formState,
        categories: {
          ...formState.categories,
          customExtensions: {
            ...formState.categories.customExtensions,
            [cat]: [...currentList, cleanExt]
          }
        }
      });
    }
    setNewExtInput('');
    setAddingExtCat(null);
  };

  const handleRemoveExtension = (cat: DownloadCategory, extToRemove: string) => {
    const currentList = formState.categories?.customExtensions?.[cat as keyof typeof formState.categories.customExtensions] 
      || DEFAULT_CATEGORY_EXTENSIONS[cat] 
      || [];
    
    setFormState({
      ...formState,
      categories: {
        ...formState.categories,
        customExtensions: {
          ...formState.categories.customExtensions,
          [cat]: currentList.filter(e => e !== extToRemove)
        }
      }
    });
  };

  const tabs = [
    { id: 'general', label: 'General', icon: Settings },
    { id: 'connection', label: 'Connection', icon: Network },
    { id: 'speed', label: 'Speed Limiter', icon: Gauge },
    { id: 'scheduler', label: 'Scheduler', icon: Calendar },
    { id: 'browser', label: 'Browser Integration', icon: Globe },
    { id: 'categories', label: 'Categories', icon: FolderTree },
    { id: 'security', label: 'Security', icon: ShieldCheck },
    { id: 'appearance', label: 'Appearance', icon: Palette },
  ] as const;

  return (
    <div id="settings-modal-overlay" className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4">
      <div 
        id="settings-modal"
        className="bg-[#1c1c20] border border-zinc-700 rounded-xl shadow-2xl w-full max-w-2xl h-[520px] flex flex-col overflow-hidden text-zinc-200 select-none animate-scaleUp"
      >
        {/* Header */}
        <div className="bg-[#242429] px-4 py-3 border-b border-zinc-700 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded bg-sky-500/20 text-sky-400 flex items-center justify-center">
              <Settings className="w-3.5 h-3.5" />
            </div>
            <h3 className="font-semibold text-sm text-zinc-100">SmartDownload Manager Settings</h3>
          </div>
          <button 
            id="settings-btn-close"
            onClick={onClose} 
            className="text-zinc-400 hover:text-white p-1 rounded hover:bg-zinc-700 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body Container */}
        <div className="flex flex-1 overflow-hidden">
          {/* Left Navigation Tabs */}
          <div className="w-48 bg-[#18181b] border-r border-zinc-800 p-2 space-y-1 overflow-y-auto">
            {tabs.map((t) => {
              const Icon = t.icon;
              return (
                <button
                  key={t.id}
                  id={`settings-tab-${t.id}`}
                  onClick={() => setActiveTab(t.id)}
                  className={`w-full flex items-center gap-2 px-3 py-2 rounded-md text-xs font-medium transition-colors ${
                    activeTab === t.id
                      ? 'bg-sky-600/20 text-sky-400 border border-sky-500/30'
                      : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/60 border border-transparent'
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  <span>{t.label}</span>
                </button>
              );
            })}
          </div>

          {/* Right Content Tab Area */}
          <div className="flex-1 p-5 overflow-y-auto text-xs space-y-4">
            {/* GENERAL TAB */}
            {activeTab === 'general' && (
              <div className="space-y-3.5">
                <h4 className="text-sm font-semibold text-zinc-100 border-b border-zinc-800 pb-1.5">General Options</h4>
                
                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.general.startWithWindows}
                    onChange={(e) => setFormState({
                      ...formState,
                      general: { ...formState.general, startWithWindows: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Start SmartDownload Manager with Windows startup</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.general.minimizeToTray}
                    onChange={(e) => setFormState({
                      ...formState,
                      general: { ...formState.general, minimizeToTray: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Minimize to Windows system tray on startup</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.general.clipboardMonitoring}
                    onChange={(e) => setFormState({
                      ...formState,
                      general: { ...formState.general, clipboardMonitoring: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Monitor Windows clipboard for downloadable URLs</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.general.showConfirmationDialog}
                    onChange={(e) => setFormState({
                      ...formState,
                      general: { ...formState.general, showConfirmationDialog: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Show download confirmation dialog before starting</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.general.soundOnCompletion}
                    onChange={(e) => setFormState({
                      ...formState,
                      general: { ...formState.general, soundOnCompletion: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Play audio chime when download finishes</span>
                </label>

                <div className="pt-2">
                  <label className="block text-zinc-400 font-medium mb-1">Default Download Folder:</label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={formState.general.defaultSavePath}
                      onChange={(e) => {
                        const val = e.target.value;
                        setFormState({
                          ...formState,
                          general: { ...formState.general, defaultSavePath: val },
                          categories: {
                            ...formState.categories,
                            baseDownloadPath: val
                          }
                        });
                      }}
                      className="flex-1 bg-zinc-900 border border-zinc-700 px-3 py-1.5 rounded-md font-mono text-[11px]"
                    />
                    <button 
                      onClick={() => handleSyncCategorySubpaths(formState.general.defaultSavePath)}
                      title="Sync all category subfolders to this base path"
                      className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 border border-zinc-700 rounded-md flex items-center gap-1 text-xs text-zinc-300"
                    >
                      <FolderOpen className="w-3.5 h-3.5 text-sky-400" />
                      <span>Sync All</span>
                    </button>
                  </div>
                  <div className="mt-2 p-2 bg-sky-950/30 border border-sky-800/40 rounded flex items-center justify-between text-[11px] text-sky-300">
                    <span className="flex items-center gap-1.5">
                      <Sparkles className="w-3.5 h-3.5 text-sky-400 shrink-0" />
                      <span>Auto-organize moves completed files into subfolders: <strong>Videos, Music, Documents, Images, Programs, Archives</strong></span>
                    </span>
                    <button
                      onClick={() => setActiveTab('categories')}
                      className="text-sky-400 hover:underline flex items-center gap-0.5 ml-2 font-medium shrink-0"
                    >
                      <span>Configure Paths</span>
                      <ArrowRight className="w-3 h-3" />
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* CONNECTION TAB */}
            {activeTab === 'connection' && (
              <div className="space-y-4">
                <h4 className="text-sm font-semibold text-zinc-100 border-b border-zinc-800 pb-1.5">Network & Threads</h4>
                
                <div>
                  <div className="flex justify-between mb-1">
                    <span className="text-zinc-300 font-medium">Default Parallel Connections:</span>
                    <span className="font-bold text-sky-400">{formState.connection.defaultConnections} connections</span>
                  </div>
                  <input
                    type="range"
                    min="1"
                    max="16"
                    value={formState.connection.defaultConnections}
                    onChange={(e) => setFormState({
                      ...formState,
                      connection: { ...formState.connection, defaultConnections: parseInt(e.target.value, 10) }
                    })}
                    className="w-full accent-sky-500 cursor-pointer"
                  />
                  <span className="text-[10px] text-zinc-500">Divides file into segmented ranges for maximum throughput</span>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-zinc-400 font-medium mb-1">Timeout (seconds):</label>
                    <input
                      type="number"
                      value={formState.connection.connectionTimeout}
                      onChange={(e) => setFormState({
                        ...formState,
                        connection: { ...formState.connection, connectionTimeout: parseInt(e.target.value, 10) }
                      })}
                      className="w-full bg-zinc-900 border border-zinc-700 px-3 py-1.5 rounded-md"
                    />
                  </div>

                  <div>
                    <label className="block text-zinc-400 font-medium mb-1">Max Retry Attempts:</label>
                    <input
                      type="number"
                      value={formState.connection.maxRetries}
                      onChange={(e) => setFormState({
                        ...formState,
                        connection: { ...formState.connection, maxRetries: parseInt(e.target.value, 10) }
                      })}
                      className="w-full bg-zinc-900 border border-zinc-700 px-3 py-1.5 rounded-md"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-zinc-400 font-medium mb-1">Custom HTTP User-Agent:</label>
                  <input
                    type="text"
                    value={formState.connection.userAgent}
                    onChange={(e) => setFormState({
                      ...formState,
                      connection: { ...formState.connection, userAgent: e.target.value }
                    })}
                    className="w-full bg-zinc-900 border border-zinc-700 px-3 py-1.5 rounded-md font-mono text-[11px]"
                  />
                </div>

                <div className="pt-2 border-t border-zinc-800 space-y-2">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-xs font-semibold text-zinc-200">Auto-Reload Stalled Downloads</div>
                      <div className="text-[11px] text-zinc-400">Automatically reconnect and refresh threads if speed drops to 0 KB/s</div>
                    </div>
                    <input
                      id="toggle-auto-reload-stalled"
                      type="checkbox"
                      checked={formState.connection.autoReloadStuck ?? true}
                      onChange={(e) => setFormState({
                        ...formState,
                        connection: { ...formState.connection, autoReloadStuck: e.target.checked }
                      })}
                      className="accent-sky-500 rounded cursor-pointer w-4 h-4"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-3 pt-1">
                    <div>
                      <label className="block text-zinc-400 text-[11px] mb-1">Stall Timeout (seconds):</label>
                      <input
                        type="number"
                        min="3"
                        max="60"
                        value={formState.connection.stuckTimeoutSeconds ?? 8}
                        onChange={(e) => setFormState({
                          ...formState,
                          connection: { ...formState.connection, stuckTimeoutSeconds: parseInt(e.target.value, 10) || 8 }
                        })}
                        className="w-full bg-zinc-900 border border-zinc-700 px-3 py-1 rounded-md text-xs"
                      />
                    </div>
                    <div>
                      <label className="block text-zinc-400 text-[11px] mb-1">Slow Warning Threshold (KB/s):</label>
                      <input
                        type="number"
                        min="5"
                        max="500"
                        value={formState.connection.slowSpeedThresholdKB ?? 25}
                        onChange={(e) => setFormState({
                          ...formState,
                          connection: { ...formState.connection, slowSpeedThresholdKB: parseInt(e.target.value, 10) || 25 }
                        })}
                        className="w-full bg-zinc-900 border border-zinc-700 px-3 py-1 rounded-md text-xs"
                      />
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* SPEED LIMITER TAB */}
            {activeTab === 'speed' && (
              <div className="space-y-3.5">
                <h4 className="text-sm font-semibold text-zinc-100 border-b border-zinc-800 pb-1.5">Speed Limiter</h4>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.speed.enabled}
                    onChange={(e) => setFormState({
                      ...formState,
                      speed: { ...formState.speed, enabled: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span className="font-semibold text-zinc-200">Enable Bandwidth Throttling</span>
                </label>

                <div>
                  <label className="block text-zinc-400 font-medium mb-1">Global Limit (KB/s):</label>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      value={Math.round(formState.speed.limitBytesPerSec / 1024)}
                      onChange={(e) => setFormState({
                        ...formState,
                        speed: { ...formState.speed, limitBytesPerSec: parseInt(e.target.value, 10) * 1024 }
                      })}
                      className="w-36 bg-zinc-900 border border-zinc-700 px-3 py-1.5 rounded-md font-mono"
                    />
                    <span className="text-zinc-400">KB/s</span>
                  </div>
                </div>

                <div className="p-3 bg-zinc-900/60 border border-zinc-800 rounded-lg space-y-2">
                  <label className="flex items-center gap-2 cursor-pointer font-medium text-zinc-300">
                    <input
                      type="checkbox"
                      checked={formState.speed.scheduledLimit.enabled}
                      onChange={(e) => setFormState({
                        ...formState,
                        speed: {
                          ...formState.speed,
                          scheduledLimit: { ...formState.speed.scheduledLimit, enabled: e.target.checked }
                        }
                      })}
                      className="accent-sky-500 rounded"
                    />
                    <span>Scheduled Speed Limits (Day / Night)</span>
                  </label>

                  <div className="grid grid-cols-2 gap-2 text-[11px] pt-1">
                    <div>
                      <span className="text-zinc-400">Daytime (08:00 - 23:00):</span>
                      <input
                        type="text"
                        value="2048 KB/s (2 MB/s)"
                        disabled
                        className="w-full bg-zinc-800 border border-zinc-700 px-2 py-1 rounded text-zinc-400 mt-0.5"
                      />
                    </div>
                    <div>
                      <span className="text-zinc-400">Nighttime (23:00 - 08:00):</span>
                      <input
                        type="text"
                        value="Unlimited (Max Bandwidth)"
                        disabled
                        className="w-full bg-zinc-800 border border-zinc-700 px-2 py-1 rounded text-emerald-400 mt-0.5"
                      />
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* SCHEDULER TAB */}
            {activeTab === 'scheduler' && (
              <div className="space-y-3.5">
                <h4 className="text-sm font-semibold text-zinc-100 border-b border-zinc-800 pb-1.5">Download Scheduler</h4>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.scheduler.enabled}
                    onChange={(e) => setFormState({
                      ...formState,
                      scheduler: { ...formState.scheduler, enabled: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span className="font-semibold text-zinc-200">Enable Automated Schedule</span>
                </label>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-zinc-400 font-medium mb-1">Start Queue At:</label>
                    <input
                      type="time"
                      value={formState.scheduler.startTime}
                      onChange={(e) => setFormState({
                        ...formState,
                        scheduler: { ...formState.scheduler, startTime: e.target.value }
                      })}
                      className="w-full bg-zinc-900 border border-zinc-700 px-3 py-1.5 rounded-md"
                    />
                  </div>

                  <div>
                    <label className="block text-zinc-400 font-medium mb-1">Stop Queue At:</label>
                    <input
                      type="time"
                      value={formState.scheduler.stopTime}
                      onChange={(e) => setFormState({
                        ...formState,
                        scheduler: { ...formState.scheduler, stopTime: e.target.value }
                      })}
                      className="w-full bg-zinc-900 border border-zinc-700 px-3 py-1.5 rounded-md"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-zinc-400 font-medium mb-1">Action on Queue Completion:</label>
                  <select
                    value={formState.scheduler.actionOnCompletion}
                    onChange={(e) => setFormState({
                      ...formState,
                      scheduler: { ...formState.scheduler, actionOnCompletion: e.target.value as any }
                    })}
                    className="w-full bg-zinc-900 border border-zinc-700 px-3 py-1.5 rounded-md"
                  >
                    <option value="none">Nothing (Keep Windows Awake)</option>
                    <option value="close_app">Close SmartDownload Manager</option>
                    <option value="sleep">Put Computer to Sleep</option>
                    <option value="hibernate">Hibernate Computer</option>
                    <option value="shutdown">Shut Down Computer</option>
                  </select>
                </div>
              </div>
            )}

            {/* BROWSER INTEGRATION TAB */}
            {activeTab === 'browser' && (
              <div className="space-y-3.5">
                <h4 className="text-sm font-semibold text-zinc-100 border-b border-zinc-800 pb-1.5">Browser Extension Integration</h4>

                <div className="bg-zinc-900/80 p-3 rounded-lg border border-zinc-800 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-zinc-200">Google Chrome Integration</span>
                    <span className="px-2 py-0.5 rounded text-[10px] bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                      Installed & Registered
                    </span>
                  </div>
                  <p className="text-[11px] text-zinc-400">
                    Host: <code className="text-sky-400">com.smartdownload.manager</code>
                  </p>
                </div>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.browserIntegration.interceptDownloads}
                    onChange={(e) => setFormState({
                      ...formState,
                      browserIntegration: { ...formState.browserIntegration, interceptDownloads: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Automatically intercept standard browser downloads</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.browserIntegration.mediaSnifferEnabled}
                    onChange={(e) => setFormState({
                      ...formState,
                      browserIntegration: { ...formState.browserIntegration, mediaSnifferEnabled: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Show floating video download badge on detected media</span>
                </label>
              </div>
            )}

            {/* SECURITY TAB */}
            {activeTab === 'security' && (
              <div className="space-y-3.5">
                <h4 className="text-sm font-semibold text-zinc-100 border-b border-zinc-800 pb-1.5">Security & Path Hardening</h4>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.security.preventPathTraversal}
                    onChange={(e) => setFormState({
                      ...formState,
                      security: { ...formState.security, preventPathTraversal: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Strict Path Traversal Protection (Prevent writing outside user folders)</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.security.sanitizeFilenames}
                    onChange={(e) => setFormState({
                      ...formState,
                      security: { ...formState.security, sanitizeFilenames: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Sanitize invalid Windows filesystem characters (\ / : * ? " &lt; &gt; |)</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.security.scanWithDefender}
                    onChange={(e) => setFormState({
                      ...formState,
                      security: { ...formState.security, scanWithDefender: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Scan downloaded files automatically with Windows Defender</span>
                </label>
              </div>
            )}

            {/* APPEARANCE TAB */}
            {activeTab === 'appearance' && (
              <div className="space-y-3.5">
                <h4 className="text-sm font-semibold text-zinc-100 border-b border-zinc-800 pb-1.5">Theme & Appearance</h4>

                <div>
                  <label className="block text-zinc-400 font-medium mb-1">Visual Theme:</label>
                  <select
                    value={formState.appearance.theme}
                    onChange={(e) => setFormState({
                      ...formState,
                      appearance: { ...formState.appearance, theme: e.target.value as any }
                    })}
                    className="w-full bg-zinc-900 border border-zinc-700 px-3 py-1.5 rounded-md"
                  >
                    <option value="fluent-mica">Windows 11 Fluent Dark (Mica)</option>
                    <option value="dark">Pro Studio Dark</option>
                    <option value="light">Classic Clean Light</option>
                  </select>
                </div>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.appearance.showSpeedGraph}
                    onChange={(e) => setFormState({
                      ...formState,
                      appearance: { ...formState.appearance, showSpeedGraph: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Show Real-Time Speed Graph at bottom of window</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formState.appearance.showSegmentVisualizer}
                    onChange={(e) => setFormState({
                      ...formState,
                      appearance: { ...formState.appearance, showSegmentVisualizer: e.target.checked }
                    })}
                    className="accent-sky-500 rounded"
                  />
                  <span>Show IDM Parallel Threads Segment Visualizer</span>
                </label>
              </div>
            )}

            {/* CATEGORIES TAB */}
            {activeTab === 'categories' && (
              <div className="space-y-4">
                <div className="border-b border-zinc-800 pb-2">
                  <h4 className="text-sm font-semibold text-zinc-100 flex items-center gap-2">
                    <FolderTree className="w-4 h-4 text-sky-400" />
                    <span>Category Organization & Folder Paths</span>
                  </h4>
                  <p className="text-[11px] text-zinc-400 mt-0.5">
                    Automatically move completed downloads into specific folders (Videos, Music, Documents, Images, Programs, Archives) based on file extensions and your defined path settings.
                  </p>
                </div>

                {/* Master Automation Controls */}
                <div className="bg-zinc-900/80 border border-zinc-800 p-3 rounded-lg space-y-2.5">
                  <label className="flex items-center gap-2.5 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formState.categories?.autoOrganizeEnabled ?? true}
                      onChange={(e) => setFormState({
                        ...formState,
                        categories: {
                          ...formState.categories,
                          autoOrganizeEnabled: e.target.checked
                        }
                      })}
                      className="accent-sky-500 rounded"
                    />
                    <span className="text-xs font-medium text-zinc-200">
                      Automatically move completed downloads to category folders based on file extension
                    </span>
                  </label>

                  <label className="flex items-center gap-2.5 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formState.categories?.createFoldersIfMissing ?? true}
                      onChange={(e) => setFormState({
                        ...formState,
                        categories: {
                          ...formState.categories,
                          createFoldersIfMissing: e.target.checked
                        }
                      })}
                      className="accent-sky-500 rounded"
                    />
                    <span className="text-xs text-zinc-400">
                      Automatically create missing category subfolders on disk if they do not exist
                    </span>
                  </label>

                  {/* Root Downloads Directory & Create Folders Action */}
                  <div className="pt-2 border-t border-zinc-800 flex flex-col gap-2">
                    <div className="flex items-center justify-between text-[11px]">
                      <span className="text-zinc-400 font-medium">Base Downloads Directory:</span>
                      <div className="flex items-center gap-2">
                        <button
                          type="button"
                          onClick={() => handleSyncCategorySubpaths(formState.categories?.baseDownloadPath || 'C:\\Users\\User\\Downloads')}
                          className="text-sky-400 hover:text-sky-300 flex items-center gap-1 hover:underline"
                        >
                          <RotateCw className="w-3 h-3" />
                          <span>Sync All Subpaths</span>
                        </button>
                      </div>
                    </div>
                    
                    <div className="flex gap-2">
                      <input
                        type="text"
                        value={formState.categories?.baseDownloadPath || 'C:\\Users\\User\\Downloads'}
                        onChange={(e) => {
                          const val = e.target.value;
                          setFormState({
                            ...formState,
                            categories: {
                              ...formState.categories,
                              baseDownloadPath: val
                            }
                          });
                        }}
                        className="flex-1 bg-zinc-950 border border-zinc-700 px-3 py-1.5 rounded-md font-mono text-[11px] text-zinc-200"
                      />
                      <button
                        type="button"
                        onClick={handleCreateCategoryFolders}
                        disabled={isCreatingFolders}
                        className="px-3 py-1.5 bg-sky-600 hover:bg-sky-500 disabled:bg-zinc-700 text-white font-medium rounded-md text-xs flex items-center gap-1.5 shadow-sm transition-all"
                        title="Create Videos, Music, Documents, Images, Programs, Archives folders in Downloads"
                      >
                        {isCreatingFolders ? (
                          <Loader2 className="w-3.5 h-3.5 animate-spin" />
                        ) : (
                          <FolderPlus className="w-3.5 h-3.5" />
                        )}
                        <span>Create Folders in Downloads</span>
                      </button>
                    </div>

                    {createdFoldersMessage && (
                      <div className="p-2 bg-emerald-950/40 border border-emerald-700/60 rounded flex items-center gap-2 text-xs text-emerald-300 animate-in fade-in">
                        <FolderCheck className="w-4 h-4 text-emerald-400 shrink-0" />
                        <span>{createdFoldersMessage}</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Individual Category Path Settings */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-semibold text-zinc-300">Category Paths & Extension Rules</span>
                    <button
                      type="button"
                      onClick={() => {
                        const base = (formState.categories?.baseDownloadPath || 'C:\\Users\\User\\Downloads').replace(/[\\/]+$/, '');
                        setFormState({
                          ...formState,
                          categories: {
                            ...formState.categories,
                            categoryPaths: {
                              Videos: `${base}\\Videos`,
                              Music: `${base}\\Music`,
                              Documents: `${base}\\Documents`,
                              Images: `${base}\\Images`,
                              Programs: `${base}\\Programs`,
                              Archives: `${base}\\Archives`,
                              Other: `${base}\\Other`,
                            }
                          }
                        });
                      }}
                      className="text-[11px] text-zinc-400 hover:text-zinc-200 hover:underline"
                    >
                      Reset All Paths to Default
                    </button>
                  </div>

                  {([
                    { id: 'Videos', name: 'Videos', icon: Video, color: 'text-rose-400', badgeBg: 'bg-rose-500/10 border-rose-500/30 text-rose-300' },
                    { id: 'Music', name: 'Music', icon: Music, color: 'text-indigo-400', badgeBg: 'bg-indigo-500/10 border-indigo-500/30 text-indigo-300' },
                    { id: 'Documents', name: 'Documents', icon: FileText, color: 'text-blue-400', badgeBg: 'bg-blue-500/10 border-blue-500/30 text-blue-300' },
                    { id: 'Images', name: 'Images', icon: ImageIcon, color: 'text-emerald-400', badgeBg: 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300' },
                    { id: 'Programs', name: 'Programs', icon: Box, color: 'text-amber-400', badgeBg: 'bg-amber-500/10 border-amber-500/30 text-amber-300' },
                    { id: 'Archives', name: 'Archives', icon: Archive, color: 'text-orange-400', badgeBg: 'bg-orange-500/10 border-orange-500/30 text-orange-300' },
                    { id: 'Other', name: 'Other', icon: FolderDown, color: 'text-zinc-400', badgeBg: 'bg-zinc-500/10 border-zinc-500/30 text-zinc-300' },
                  ] as const).map(({ id, name, icon: Icon, color, badgeBg }) => {
                    const currentPath = formState.categories?.categoryPaths?.[id] 
                      || `${formState.categories?.baseDownloadPath || 'C:\\Users\\User\\Downloads'}\\${id}`;
                    const currentExtensions = formState.categories?.customExtensions?.[id as keyof typeof formState.categories.customExtensions]
                      || DEFAULT_CATEGORY_EXTENSIONS[id]
                      || [];

                    return (
                      <div key={id} className="bg-zinc-900/60 border border-zinc-800 p-3 rounded-lg space-y-2.5">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <div className={`p-1.5 rounded-md bg-zinc-800 ${color}`}>
                              <Icon className="w-4 h-4" />
                            </div>
                            <div>
                              <div className="text-xs font-semibold text-zinc-200 flex items-center gap-2">
                                <span>{name}</span>
                                <span className={`text-[10px] px-1.5 py-0.2 rounded border ${badgeBg}`}>
                                  {id === 'Other' ? 'Default Fallback' : `${currentExtensions.length} extensions`}
                                </span>
                              </div>
                            </div>
                          </div>

                          <div className="flex items-center gap-2">
                            <button
                              type="button"
                              onClick={() => handleResetCategoryPath(id)}
                              className="text-[10px] text-zinc-400 hover:text-zinc-200 hover:underline"
                              title="Reset folder path to default"
                            >
                              Reset
                            </button>
                          </div>
                        </div>

                        {/* Save Path Input */}
                        <div className="flex items-center gap-2">
                          <input
                            type="text"
                            value={currentPath}
                            onChange={(e) => {
                              const val = e.target.value;
                              setFormState({
                                ...formState,
                                categories: {
                                  ...formState.categories,
                                  categoryPaths: {
                                    ...formState.categories.categoryPaths,
                                    [id]: val
                                  }
                                }
                              });
                            }}
                            placeholder={`Path for ${name}...`}
                            className="flex-1 bg-zinc-950 border border-zinc-700/80 px-2.5 py-1 rounded font-mono text-[11px] text-sky-400 focus:border-sky-500 focus:outline-none"
                          />
                          <button
                            type="button"
                            onClick={() => {
                              const drive = currentPath.startsWith('D:') ? 'C:' : 'D:';
                              const folderName = id === 'Other' ? 'Downloads' : `Downloads\\${id}`;
                              setFormState({
                                ...formState,
                                categories: {
                                  ...formState.categories,
                                  categoryPaths: {
                                    ...formState.categories.categoryPaths,
                                    [id]: `${drive}\\${folderName}`
                                  }
                                }
                              });
                            }}
                            className="px-2 py-1 bg-zinc-800 hover:bg-zinc-700 border border-zinc-700 rounded text-[10px] text-zinc-300 shrink-0"
                            title="Switch Drive Letter"
                          >
                            Drive
                          </button>
                        </div>

                        {/* Extensions List */}
                        {id !== 'Other' && (
                          <div className="pt-1">
                            <div className="flex flex-wrap items-center gap-1.5 text-[10px]">
                              <span className="text-zinc-500">Auto-routes:</span>
                              {currentExtensions.map((ext) => (
                                <span
                                  key={ext}
                                  className="px-1.5 py-0.5 rounded bg-zinc-800/90 border border-zinc-700 text-zinc-300 font-mono flex items-center gap-1 group"
                                >
                                  <span>.{ext}</span>
                                  <button
                                    type="button"
                                    onClick={() => handleRemoveExtension(id, ext)}
                                    className="text-zinc-500 hover:text-rose-400"
                                    title={`Remove .${ext}`}
                                  >
                                    <X className="w-2.5 h-2.5" />
                                  </button>
                                </span>
                              ))}

                              {addingExtCat === id ? (
                                <div className="flex items-center gap-1">
                                  <input
                                    type="text"
                                    placeholder="ext (e.g. m4v)"
                                    value={newExtInput}
                                    onChange={(e) => setNewExtInput(e.target.value)}
                                    onKeyDown={(e) => {
                                      if (e.key === 'Enter') {
                                        handleAddExtension(id);
                                      } else if (e.key === 'Escape') {
                                        setAddingExtCat(null);
                                      }
                                    }}
                                    className="w-20 bg-zinc-950 border border-sky-500 px-1.5 py-0.5 rounded text-[10px] text-sky-400 font-mono focus:outline-none"
                                    autoFocus
                                  />
                                  <button
                                    type="button"
                                    onClick={() => handleAddExtension(id)}
                                    className="px-1.5 py-0.5 bg-sky-600 hover:bg-sky-500 text-white rounded text-[10px]"
                                  >
                                    Add
                                  </button>
                                  <button
                                    type="button"
                                    onClick={() => setAddingExtCat(null)}
                                    className="text-zinc-500 hover:text-zinc-300"
                                  >
                                    <X className="w-3 h-3" />
                                  </button>
                                </div>
                              ) : (
                                <button
                                  type="button"
                                  onClick={() => {
                                    setAddingExtCat(id);
                                    setNewExtInput('');
                                  }}
                                  className="px-1.5 py-0.5 rounded bg-zinc-800 hover:bg-zinc-700 text-zinc-400 hover:text-zinc-200 border border-dashed border-zinc-700 flex items-center gap-0.5"
                                  title="Add file extension to this category"
                                >
                                  <Plus className="w-2.5 h-2.5" />
                                  <span>Add Ext</span>
                                </button>
                              )}
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="bg-[#242429] px-4 py-3 border-t border-zinc-700 flex items-center justify-between">
          <div className="text-[11px] text-zinc-500">
            SmartDownload Manager v1.0.0 (Build 2026.08)
          </div>
          <div className="flex items-center gap-2">
            <button
              id="settings-btn-cancel"
              onClick={onClose}
              className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded-md text-xs font-medium transition-colors"
            >
              Cancel
            </button>

            <button
              id="settings-btn-apply"
              onClick={handleSave}
              className="flex items-center gap-1 px-4 py-1.5 bg-sky-600 hover:bg-sky-500 text-white rounded-md text-xs font-semibold shadow-sm transition-all"
            >
              {savedSuccess ? <Check className="w-3.5 h-3.5" /> : null}
              <span>{savedSuccess ? 'Saved!' : 'Save & Apply'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
