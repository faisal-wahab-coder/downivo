export type DownloadStatus = 
  | 'queued' 
  | 'connecting' 
  | 'downloading' 
  | 'paused' 
  | 'completed' 
  | 'failed' 
  | 'cancelled';

export interface DownloadSegment {
  id: number;
  startByte: number;
  endByte: number;
  downloadedBytes: number;
  totalBytes: number;
  speed: number; // bytes per sec
  status: 'idle' | 'downloading' | 'completed' | 'failed';
}

export type DownloadCategory = 'Videos' | 'Music' | 'Documents' | 'Images' | 'Programs' | 'Archives' | 'Other';

export interface CategoryPathConfig {
  Videos: string;
  Music: string;
  Documents: string;
  Images: string;
  Programs: string;
  Archives: string;
  Other: string;
}

export interface CategoriesSettings {
  autoOrganizeEnabled: boolean;
  createFoldersIfMissing: boolean;
  baseDownloadPath: string;
  categoryPaths: CategoryPathConfig;
  customExtensions?: {
    Videos: string[];
    Music: string[];
    Documents: string[];
    Images: string[];
    Programs: string[];
    Archives: string[];
  };
}

export interface DownloadTask {
  id: string;
  url: string;
  filename: string;
  category: DownloadCategory;
  status: DownloadStatus;
  totalBytes: number;
  downloadedBytes: number;
  speed: number; // bytes per second
  eta: number; // seconds remaining
  connectionCount: number;
  segments: DownloadSegment[];
  savePath: string;
  originalSavePath?: string;
  movedToCategoryFolder?: boolean;
  targetCategoryFolder?: string;
  mimeType: string;
  resumable: boolean;
  createdAt: number;
  completedAt?: number;
  error?: string;
  retryCount: number;
  checksum?: {
    md5?: string;
    sha256?: string;
  };
  sourcePageUrl?: string;
  quality?: string;
  downloadBlobUrl?: string;
  isStuck?: boolean;
  isSlow?: boolean;
  stuckDuration?: number;
  reloadCount?: number;
  lastReloadAt?: number;
}

export interface CategoryInfo {
  id: string;
  name: 'Videos' | 'Music' | 'Documents' | 'Images' | 'Programs' | 'Archives' | 'Other';
  icon: string;
  defaultPath: string;
  extensions: string[];
  count: number;
}

export interface SchedulerConfig {
  enabled: boolean;
  startTime: string; // "22:00"
  stopTime: string; // "06:00"
  maxConcurrentDownloads: number;
  actionOnCompletion: 'none' | 'shutdown' | 'sleep' | 'hibernate' | 'close_app' | 'beep';
  daysOfWeek: number[]; // [0,1,2,3,4,5,6]
  autoStartQueue: boolean;
}

export interface SpeedLimitConfig {
  enabled: boolean;
  limitBytesPerSec: number; // 0 = unlimited
  scheduledLimit: {
    enabled: boolean;
    daytimeLimit: number;
    nighttimeLimit: number;
    dayStartTime: string;
    nightStartTime: string;
  };
}

export interface AppSettings {
  general: {
    startWithWindows: boolean;
    minimizeToTray: boolean;
    closeToTray: boolean;
    showConfirmationDialog: boolean;
    autoStartDownloads: boolean;
    clipboardMonitoring: boolean;
    defaultSavePath: string;
    soundOnCompletion: boolean;
  };
  connection: {
    defaultConnections: number; // e.g. 8
    maxConnectionsPerServer: number; // e.g. 16
    connectionTimeout: number; // seconds
    maxRetries: number;
    userAgent: string;
    autoReloadStuck: boolean;
    stuckTimeoutSeconds: number; // seconds of 0 speed before auto-reload
    slowSpeedThresholdKB: number; // threshold in KB/s considered slow
  };
  speed: SpeedLimitConfig;
  scheduler: SchedulerConfig;
  appearance: {
    theme: 'dark' | 'light' | 'system' | 'fluent-mica';
    accentColor: string;
    showSpeedGraph: boolean;
    showSegmentVisualizer: boolean;
    compactView: boolean;
  };
  browserIntegration: {
    chromeEnabled: boolean;
    edgeEnabled: boolean;
    firefoxEnabled: boolean;
    interceptDownloads: boolean;
    mediaSnifferEnabled: boolean;
    minVideoSizeMB: number;
    ignoredDomains: string[];
  };
  security: {
    sanitizeFilenames: boolean;
    preventPathTraversal: boolean;
    scanWithDefender: boolean;
    blockExecutablesFromUntrusted: boolean;
  };
  categories: CategoriesSettings;
}

export interface DetectedMediaResource {
  id: string;
  url: string;
  pageUrl: string;
  pageTitle: string;
  filename: string;
  mimeType: string;
  quality: string; // e.g. "1080p", "720p", "480p", "320kbps Audio"
  resolution?: string;
  estimatedSize?: number;
  duration?: string;
  detectedAt: number;
  ignored?: boolean;
}

export interface NativeMessagePacket {
  id: string;
  timestamp: number;
  direction: 'chrome_to_host' | 'host_to_chrome';
  type: 
    | 'PING' 
    | 'PONG' 
    | 'DOWNLOAD_REQUEST' 
    | 'DOWNLOAD_ACCEPTED' 
    | 'DOWNLOAD_REJECTED' 
    | 'MEDIA_DETECTED' 
    | 'GET_STATUS' 
    | 'STATUS_RESPONSE' 
    | 'DOWNLOAD_PAUSE' 
    | 'DOWNLOAD_RESUME' 
    | 'DOWNLOAD_RELOAD'
    | 'DOWNLOAD_CANCEL' 
    | 'DOWNLOAD_PROGRESS' 
    | 'OPEN_MANAGER' 
    | 'GET_SETTINGS' 
    | 'SET_SETTINGS';
  payload: any;
  status: 'valid' | 'invalid' | 'blocked';
  error?: string;
}

export interface CodeFile {
  path: string;
  name: string;
  language: 'python' | 'json' | 'typescript' | 'javascript' | 'html' | 'css' | 'batch' | 'inno' | 'markdown';
  description: string;
  content: string;
  category: 'windows_app' | 'chrome_extension' | 'native_host' | 'installer' | 'tests' | 'docs';
}
