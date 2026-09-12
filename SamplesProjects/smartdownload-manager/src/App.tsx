import React, { useState, useEffect, useRef } from 'react';
import { 
  DownloadTask, 
  AppSettings, 
  DetectedMediaResource, 
  NativeMessagePacket 
} from './types';
import { 
  INITIAL_DOWNLOADS, 
  INITIAL_SETTINGS, 
  INITIAL_DETECTED_MEDIA, 
  INITIAL_PACKETS 
} from './services/sampleData';
import { 
  formatSpeed, 
  createDownloadSegments, 
  calculateChecksum, 
  inferCategory,
  autoOrganizeCompletedDownload,
  getCategoryFolderPath
} from './services/downloadEngine';

import { TitleBar, AppViewMode } from './components/TitleBar';
import { Toolbar } from './components/Toolbar';
import { Sidebar, FilterCategory } from './components/Sidebar';
import { DownloadList } from './components/DownloadList';
import { SegmentVisualizer } from './components/SegmentVisualizer';
import { SpeedGraph } from './components/SpeedGraph';
import { AddDownloadModal } from './components/AddDownloadModal';
import { SettingsModal } from './components/SettingsModal';
import { ClearHistoryModal } from './components/ClearHistoryModal';
import { ChromeSimulator } from './components/ChromeSimulator';
import { ProtocolInspector } from './components/ProtocolInspector';
import { CodeExplorerModal } from './components/CodeExplorerModal';
import { DocsGuide } from './components/DocsGuide';
import { ChecksumDialog } from './components/ChecksumDialog';
import { WindowsNotificationToast } from './components/WindowsNotificationToast';

export function App() {
  const [currentView, setCurrentView] = useState<AppViewMode>('desktop');
  const [downloads, setDownloads] = useState<DownloadTask[]>(INITIAL_DOWNLOADS);
  const [selectedId, setSelectedId] = useState<string | null>('dl-101');
  const [selectedFilter, setSelectedFilter] = useState<FilterCategory>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [settings, setSettings] = useState<AppSettings>(INITIAL_SETTINGS);
  
  // Modals & Overlays
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [addModalInitialData, setAddModalInitialData] = useState<{ url?: string; filename?: string; size?: number }>({});
  const [isSettingsModalOpen, setIsSettingsModalOpen] = useState(false);
  const [isClearHistoryModalOpen, setIsClearHistoryModalOpen] = useState(false);
  const [checksumTask, setChecksumTask] = useState<DownloadTask | null>(null);

  // Chrome Extension State & Packets
  const [detectedMedia, setDetectedMedia] = useState<DetectedMediaResource[]>(INITIAL_DETECTED_MEDIA);
  const [packets, setPackets] = useState<NativeMessagePacket[]>(INITIAL_PACKETS);

  // Toast Notification
  const [activeToast, setActiveToast] = useState<{
    id: string;
    title: string;
    message: string;
    type: 'completed' | 'started' | 'failed';
    task?: DownloadTask;
  } | null>(null);

  // Total Network Metrics & History Counts
  const activeDownloads = downloads.filter((d) => d.status === 'downloading');
  const totalSpeed = activeDownloads.reduce((acc, curr) => acc + curr.speed, 0);
  const selectedTask = downloads.find((d) => d.id === selectedId) || null;
  const completedDownloads = downloads.filter((d) => d.status === 'completed');
  const completedBytes = completedDownloads.reduce((acc, d) => acc + d.downloadedBytes, 0);
  const isHistoryView = selectedFilter === 'history';
  const stuckDownloads = activeDownloads.filter((d) => d.isStuck || (d.speed === 0 && (d.stuckDuration || 0) >= 3));
  const hasStuckDownloads = stuckDownloads.length > 0;

  // Active Download Engine Loop
  useEffect(() => {
    const timer = setInterval(() => {
      setDownloads((prevDownloads) => {
        let hasChanges = false;
        const maxConcurrent = settings.scheduler.enabled ? settings.scheduler.maxConcurrentDownloads : 4;
        let currentActive = 0;

        const updated = prevDownloads.map((task) => {
          if (task.status !== 'downloading') return task;

          currentActive++;
          if (currentActive > maxConcurrent) {
            return { ...task, status: 'queued' as const, speed: 0 };
          }

          hasChanges = true;
          const remaining = task.totalBytes - task.downloadedBytes;

          // Check speed limiter
          let targetMaxRate = 8 * 1024 * 1024; // Default max 8 MB/s
          if (settings.speed.enabled && settings.speed.limitBytesPerSec > 0) {
            targetMaxRate = settings.speed.limitBytesPerSec / Math.max(1, activeDownloads.length);
          }

          // Check if manually or simulated stalled
          if (task.isStuck && task.speed === 0) {
            const curDuration = (task.stuckDuration || 0) + 0.5;
            const timeout = settings.connection?.stuckTimeoutSeconds || 8;
            if (settings.connection?.autoReloadStuck && curDuration >= timeout) {
              // Auto reconnect and restore speed
              const recoveredSpeed = Math.floor(4.2 * 1024 * 1024 + Math.random() * 2.5 * 1024 * 1024);
              return {
                ...task,
                isStuck: false,
                isSlow: false,
                stuckDuration: 0,
                speed: recoveredSpeed,
                reloadCount: (task.reloadCount || 0) + 1,
                lastReloadAt: Date.now(),
              };
            }
            return {
              ...task,
              stuckDuration: curDuration,
              speed: 0
            };
          }

          // Calculate step delta (approx 0.5s ticks)
          const baseSpeed = Math.min(targetMaxRate, 1024 * 1024 + Math.random() * 3 * 1024 * 1024);
          const slowThreshold = (settings.connection?.slowSpeedThresholdKB || 25) * 1024;
          const isSlow = baseSpeed > 0 && baseSpeed < slowThreshold;
          const bytesToAdvance = Math.min(remaining, Math.floor(baseSpeed * 0.5));
          const newDownloaded = task.downloadedBytes + bytesToAdvance;
          const eta = baseSpeed > 0 ? Math.ceil((task.totalBytes - newDownloaded) / baseSpeed) : 0;

          // Update Segment progress
          const segCount = task.segments.length;
          const bytesPerSeg = Math.ceil(bytesToAdvance / segCount);
          const updatedSegments = task.segments.map((seg) => {
            const segRemaining = seg.totalBytes - seg.downloadedBytes;
            const segAdvance = Math.min(segRemaining, bytesPerSeg);
            const isSegDone = seg.downloadedBytes + segAdvance >= seg.totalBytes;
            return {
              ...seg,
              downloadedBytes: seg.downloadedBytes + segAdvance,
              speed: Math.floor(baseSpeed / segCount),
              status: isSegDone ? ('completed' as const) : ('downloading' as const),
            };
          });

          // Check if download finished
          if (newDownloaded >= task.totalBytes) {
            // Apply automatic category organization and move file to specific category folder
            const organizeResult = autoOrganizeCompletedDownload(
              task,
              settings.categories,
              prevDownloads.map(t => t.savePath)
            );

            const completedTask: DownloadTask = {
              ...organizeResult.updatedTask,
              status: 'completed' as const,
              downloadedBytes: task.totalBytes,
              speed: 0,
              eta: 0,
              completedAt: Date.now(),
              checksum: {
                sha256: '9f83c21a4e5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d',
                md5: '4e8c1b9f0a3d2e5b8c7a6d5e4f3a2b1c'
              },
              segments: task.segments.map(s => ({ ...s, downloadedBytes: s.totalBytes, status: 'completed' as const, speed: 0 }))
            };

            // Trigger completion toast with auto-moved location
            showNotificationToast({
              id: 'toast-' + Date.now(),
              title: organizeResult.moved ? `Moved to ${completedTask.category}` : 'Download Completed',
              message: organizeResult.moved 
                ? `Finished & organized into ${completedTask.category}: ${completedTask.savePath}` 
                : `Successfully downloaded "${task.filename}" (${(task.totalBytes / (1024 * 1024)).toFixed(1)} MB)`,
              type: 'completed',
              task: completedTask
            });

            // Send packet to Native Messaging inspector
            addPacket({
              direction: 'host_to_chrome',
              type: 'DOWNLOAD_PROGRESS',
              payload: {
                taskId: task.id,
                status: 'completed',
                filename: task.filename,
                category: completedTask.category,
                savePath: completedTask.savePath,
                autoMoved: organizeResult.moved,
                targetFolder: organizeResult.targetFolder
              },
              status: 'valid'
            });

            return completedTask;
          }

          return {
            ...task,
            downloadedBytes: newDownloaded,
            speed: baseSpeed,
            eta: eta,
            segments: updatedSegments,
            isSlow: isSlow,
            isStuck: false,
            stuckDuration: 0
          };
        });

        return hasChanges ? updated : prevDownloads;
      });
    }, 500);

    return () => clearInterval(timer);
  }, [settings.speed, settings.scheduler, settings.categories, activeDownloads.length]);

  const showNotificationToast = (toast: {
    id: string;
    title: string;
    message: string;
    type: 'completed' | 'started' | 'failed';
    task?: DownloadTask;
  }) => {
    setActiveToast(toast);
    setTimeout(() => setActiveToast(null), 5000);
  };

  const addPacket = (pkt: Partial<NativeMessagePacket>) => {
    const newPkt: NativeMessagePacket = {
      id: 'pkt-' + Date.now() + '-' + Math.random().toString(36).substring(2, 6),
      timestamp: Date.now(),
      direction: pkt.direction || 'chrome_to_host',
      type: pkt.type || 'PING',
      payload: pkt.payload || {},
      status: pkt.status || 'valid',
      error: pkt.error
    };
    setPackets((prev) => [newPkt, ...prev.slice(0, 49)]);
  };

  // Actions
  const handleAddDownload = (data: {
    url: string;
    filename: string;
    category: 'Videos' | 'Music' | 'Documents' | 'Images' | 'Programs' | 'Archives' | 'Other';
    savePath: string;
    connections: number;
    startImmediately: boolean;
    totalBytes: number;
  }) => {
    const newTask: DownloadTask = {
      id: 'dl-' + Date.now(),
      url: data.url,
      filename: data.filename,
      category: data.category,
      status: data.startImmediately ? 'downloading' : 'queued',
      totalBytes: data.totalBytes,
      downloadedBytes: 0,
      speed: data.startImmediately ? 2 * 1024 * 1024 : 0,
      eta: 10,
      connectionCount: data.connections,
      segments: createDownloadSegments(data.totalBytes, data.connections),
      savePath: data.savePath,
      mimeType: 'application/octet-stream',
      resumable: true,
      createdAt: Date.now(),
      retryCount: 0,
    };

    setDownloads((prev) => [newTask, ...prev]);
    setSelectedId(newTask.id);

    // Record Native Packet
    addPacket({
      direction: 'chrome_to_host',
      type: 'DOWNLOAD_REQUEST',
      payload: { url: data.url, filename: data.filename, connections: data.connections },
      status: 'valid'
    });

    showNotificationToast({
      id: 'toast-' + Date.now(),
      title: data.startImmediately ? 'Download Started' : 'Download Queued',
      message: `"${data.filename}" added to queue`,
      type: 'started',
      task: newTask
    });
  };

  const handleResumeTask = (id: string) => {
    setDownloads((prev) =>
      prev.map((t) => (t.id === id ? { ...t, status: 'downloading', speed: 1024 * 1024 } : t))
    );
    addPacket({
      direction: 'chrome_to_host',
      type: 'DOWNLOAD_RESUME',
      payload: { taskId: id },
      status: 'valid'
    });
  };

  const handlePauseTask = (id: string) => {
    setDownloads((prev) =>
      prev.map((t) => (t.id === id ? { ...t, status: 'paused', speed: 0 } : t))
    );
    addPacket({
      direction: 'chrome_to_host',
      type: 'DOWNLOAD_PAUSE',
      payload: { taskId: id },
      status: 'valid'
    });
  };

  const handleStopTask = (id: string) => {
    handlePauseTask(id);
  };

  const handleRetryTask = (id: string) => {
    setDownloads((prev) =>
      prev.map((t) => {
        if (t.id === id) {
          return {
            ...t,
            status: 'downloading',
            downloadedBytes: 0,
            speed: 1024 * 1024,
            segments: createDownloadSegments(t.totalBytes, t.connectionCount)
          };
        }
        return t;
      })
    );
  };

  const handleDeleteTask = (id: string) => {
    setDownloads((prev) => prev.filter((t) => t.id !== id));
    if (selectedId === id) setSelectedId(null);
  };

  const handleClearHistory = (includeFailed: boolean) => {
    const toClear = downloads.filter((d) => d.status === 'completed' || (includeFailed && d.status === 'failed'));
    setDownloads((prev) => prev.filter((d) => {
      if (d.status === 'completed') return false;
      if (includeFailed && d.status === 'failed') return false;
      return true;
    }));
    showNotificationToast({
      id: 'toast-' + Date.now(),
      title: 'History Cleared',
      message: `Removed ${toClear.length} records from history list. Downloaded files on disk remain safe.`,
      type: 'completed'
    });
    addPacket({
      direction: 'host_to_chrome',
      type: 'DOWNLOAD_PROGRESS',
      payload: { action: 'CLEAR_HISTORY', clearedCount: toClear.length },
      status: 'valid'
    });
  };

  const handleReloadTask = (id: string) => {
    setDownloads((prev) =>
      prev.map((t) => {
        if (t.id === id) {
          const freshSpeed = Math.floor(4.5 * 1024 * 1024 + Math.random() * 2 * 1024 * 1024);
          return {
            ...t,
            status: 'downloading' as const,
            speed: freshSpeed,
            isStuck: false,
            isSlow: false,
            stuckDuration: 0,
            reloadCount: (t.reloadCount || 0) + 1,
            lastReloadAt: Date.now(),
            segments: t.segments.map((seg) => ({
              ...seg,
              speed: Math.floor(freshSpeed / t.segments.length),
              status: seg.downloadedBytes >= seg.totalBytes ? ('completed' as const) : ('downloading' as const)
            }))
          };
        }
        return t;
      })
    );

    const task = downloads.find((t) => t.id === id);
    if (task) {
      showNotificationToast({
        id: 'toast-' + Date.now(),
        title: 'Connections Reloaded',
        message: `Re-established ${task.connectionCount} socket threads for "${task.filename}". Restoring high-speed throughput!`,
        type: 'started',
        task: task
      });
      addPacket({
        direction: 'chrome_to_host',
        type: 'DOWNLOAD_RELOAD',
        payload: { taskId: id, filename: task.filename, reason: 'user_reload_requested' },
        status: 'valid'
      });
    }
  };

  const handleReloadStuck = () => {
    const candidates = downloads.filter((d) => d.status === 'downloading' && (d.isStuck || d.speed === 0 || d.isSlow));
    if (candidates.length > 0) {
      candidates.forEach((c) => handleReloadTask(c.id));
    } else if (selectedId) {
      handleReloadTask(selectedId);
    }
  };

  const handleSimulateStall = () => {
    let target = downloads.find((d) => d.status === 'downloading');
    if (!target) {
      const paused = downloads.find((d) => d.status === 'paused' || d.status === 'queued');
      if (paused) {
        handleResumeTask(paused.id);
        target = paused;
      } else if (downloads.length > 0) {
        handleRetryTask(downloads[0].id);
        target = downloads[0];
      }
    }
    if (target) {
      const targetId = target.id;
      setDownloads((prev) =>
        prev.map((t) => (t.id === targetId ? { ...t, status: 'downloading', speed: 0, isStuck: true, stuckDuration: 6 } : t))
      );
      setSelectedId(targetId);
      showNotificationToast({
        id: 'toast-' + Date.now(),
        title: 'Stall Simulated (Demo Mode)',
        message: `"${target.filename}" is now stalled at 0 KB/s. Click "Reload" or "Reload Stuck" to reconnect threads!`,
        type: 'failed',
        task: target
      });
    }
  };

  const handleSendFromChrome = (resource: {
    url: string;
    filename: string;
    category?: string;
    size?: number;
    quality?: string;
    pageUrl: string;
  }) => {
    if (settings.general.showConfirmationDialog) {
      setAddModalInitialData({
        url: resource.url,
        filename: resource.filename,
        size: resource.size || 25 * 1024 * 1024
      });
      setIsAddModalOpen(true);
    } else {
      const category = (resource.category as any) || inferCategory(resource.filename, settings.categories?.customExtensions);
      const catFolder = getCategoryFolderPath(category, settings.categories);
      const initialPath = `${catFolder}\\${resource.filename}`;

      handleAddDownload({
        url: resource.url,
        filename: resource.filename,
        category: category,
        savePath: initialPath,
        connections: settings.connection.defaultConnections,
        startImmediately: true,
        totalBytes: resource.size || 25 * 1024 * 1024
      });
    }
  };

  // Filtered Downloads
  const filteredDownloads = downloads.filter((d) => {
    // History or category or status filter
    if (selectedFilter === 'history') {
      if (d.status !== 'completed') return false;
    } else if (['downloading', 'completed', 'paused', 'failed', 'queued'].includes(selectedFilter)) {
      if (d.status !== selectedFilter) return false;
    } else if (selectedFilter !== 'all') {
      if (d.category !== selectedFilter) return false;
    }

    // Search query
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return d.filename.toLowerCase().includes(q) || d.url.toLowerCase().includes(q);
    }
    return true;
  });

  return (
    <div id="smartdownload-app-root" className="h-screen w-screen flex flex-col bg-[#121214] text-zinc-100 overflow-hidden font-sans">
      {/* Title Bar with View Tabs */}
      <TitleBar
        currentView={currentView}
        onViewChange={setCurrentView}
        activeDownloadCount={activeDownloads.length}
        totalSpeed={totalSpeed}
        formatSpeed={formatSpeed}
        onMinimize={() => showNotificationToast({
          id: 'tray-' + Date.now(),
          title: 'Minimized to System Tray',
          message: 'SmartDownload Manager is running in the background.',
          type: 'started'
        })}
        onMaximize={() => {}}
        onClose={() => showNotificationToast({
          id: 'tray-' + Date.now(),
          title: 'Minimized to System Tray',
          message: 'Active downloads will continue in background.',
          type: 'started'
        })}
      />

      {/* Main View Area */}
      {currentView === 'desktop' && (
        <main className="flex-1 flex flex-col overflow-hidden">
          {/* Main Windows Toolbar */}
          <Toolbar
            onAddUrl={() => {
              setAddModalInitialData({});
              setIsAddModalOpen(true);
            }}
            onResumeSelected={() => selectedId && handleResumeTask(selectedId)}
            onPauseSelected={() => selectedId && handlePauseTask(selectedId)}
            onStopSelected={() => selectedId && handleStopTask(selectedId)}
            onDeleteSelected={() => selectedId && handleDeleteTask(selectedId)}
            onRedownloadSelected={() => selectedId && handleRetryTask(selectedId)}
            onReloadSelected={() => selectedId && handleReloadTask(selectedId)}
            onReloadStuck={handleReloadStuck}
            hasStuckDownloads={hasStuckDownloads}
            stuckCount={stuckDownloads.length}
            onSimulateStall={handleSimulateStall}
            onOpenHistory={() => setSelectedFilter('history')}
            onClearHistory={() => setIsClearHistoryModalOpen(true)}
            historyCount={completedDownloads.length}
            isHistoryView={isHistoryView}
            onOpenSettings={() => setIsSettingsModalOpen(true)}
            hasSelection={!!selectedId}
            selectedStatus={selectedTask?.status}
            speedConfig={settings.speed}
            onToggleSpeedLimit={() =>
              setSettings({
                ...settings,
                speed: { ...settings.speed, enabled: !settings.speed.enabled }
              })
            }
            schedulerConfig={settings.scheduler}
            searchQuery={searchQuery}
            onSearchChange={setSearchQuery}
          />

          {/* Central Workspace: Sidebar + Download Table */}
          <div className="flex-1 flex overflow-hidden">
            <Sidebar
              selectedFilter={selectedFilter}
              onSelectFilter={setSelectedFilter}
              downloads={downloads}
            />

            <div className="flex-1 flex flex-col overflow-hidden">
              <DownloadList
                downloads={filteredDownloads}
                selectedId={selectedId}
                onSelect={setSelectedId}
                onResume={handleResumeTask}
                onPause={handlePauseTask}
                onStop={handleStopTask}
                onRetry={handleRetryTask}
                onReload={handleReloadTask}
                onDelete={handleDeleteTask}
                onVerifyChecksum={(t) => setChecksumTask(t)}
                isHistoryView={isHistoryView}
                onClearHistory={() => setIsClearHistoryModalOpen(true)}
                onOpenFile={(t) => showNotificationToast({
                  id: 'open-' + Date.now(),
                  title: 'Opening File...',
                  message: `Launching "${t.filename}" via default system player`,
                  type: 'started',
                  task: t
                })}
                onOpenFolder={(t) => showNotificationToast({
                  id: 'folder-' + Date.now(),
                  title: 'Opening Windows Explorer',
                  message: `Revealing: ${t.savePath}`,
                  type: 'started',
                  task: t
                })}
              />

              {/* IDM Multi-Connection Segment Visualizer */}
              {settings.appearance.showSegmentVisualizer && (
                <SegmentVisualizer task={selectedTask} />
              )}

              {/* Real-time Speed Throughput Graph */}
              {settings.appearance.showSpeedGraph && (
                <SpeedGraph
                  currentSpeed={totalSpeed}
                  speedLimitBytesPerSec={settings.speed.enabled ? settings.speed.limitBytesPerSec : 0}
                />
              )}
            </div>
          </div>
        </main>
      )}

      {/* VIEW: CHROME SNIFFER & BROWSER SIMULATOR */}
      {currentView === 'browser' && (
        <ChromeSimulator
          onSendToManager={handleSendFromChrome}
          detectedMedia={detectedMedia}
        />
      )}

      {/* VIEW: NATIVE MESSAGING PROTOCOL INSPECTOR */}
      {currentView === 'protocol' && (
        <ProtocolInspector
          packets={packets}
          onSendCustomPacket={addPacket}
          onClearPackets={() => setPackets([])}
        />
      )}

      {/* VIEW: STANDALONE CODEBASE EXPLORER & ZIP EXPORTER */}
      {currentView === 'codebase' && (
        <CodeExplorerModal />
      )}

      {/* VIEW: POWERSHELL GUIDE & SETUP DOCS */}
      {currentView === 'docs' && (
        <DocsGuide />
      )}

      {/* Status Bar */}
      <footer id="app-statusbar" className="bg-[#18181b] border-t border-[#27272a] px-3 py-1 text-[11px] text-zinc-400 flex items-center justify-between select-none">
        <div className="flex items-center gap-3">
          <span>Total: <strong>{downloads.length}</strong> items</span>
          <span>•</span>
          <span>Active: <strong className="text-sky-400">{activeDownloads.length}</strong></span>
          <span>•</span>
          <span>Speed: <strong className="text-emerald-400">{formatSpeed(totalSpeed)}</strong></span>
        </div>

        <div className="flex items-center gap-3 font-mono text-[10px]">
          <span>Protocol: JSON Native Stdio v1.0</span>
          <span>•</span>
          <span>SQLite WAL Mode: Active</span>
        </div>
      </footer>

      {/* MODALS & OVERLAYS */}
      <AddDownloadModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onConfirm={handleAddDownload}
        initialUrl={addModalInitialData.url}
        initialFilename={addModalInitialData.filename}
        initialSize={addModalInitialData.size}
        categoriesSettings={settings.categories}
      />

      <SettingsModal
        isOpen={isSettingsModalOpen}
        onClose={() => setIsSettingsModalOpen(false)}
        settings={settings}
        onSave={setSettings}
      />

      <ClearHistoryModal
        isOpen={isClearHistoryModalOpen}
        onClose={() => setIsClearHistoryModalOpen(false)}
        completedCount={completedDownloads.length}
        totalFinishedBytes={completedBytes}
        onConfirmClear={handleClearHistory}
      />

      <ChecksumDialog
        task={checksumTask}
        onClose={() => setChecksumTask(null)}
      />

      {/* Windows 11 Action Center Notification Toast */}
      <WindowsNotificationToast
        notification={activeToast}
        onClose={() => setActiveToast(null)}
        onOpenFile={(t) => {}}
        onOpenFolder={(t) => {}}
      />
    </div>
  );
}

export default App;
