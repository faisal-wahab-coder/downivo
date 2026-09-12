import { DownloadTask, CategoryInfo, AppSettings, DetectedMediaResource, NativeMessagePacket } from '../types';
import { createDownloadSegments } from './downloadEngine';

export const INITIAL_SETTINGS: AppSettings = {
  general: {
    startWithWindows: true,
    minimizeToTray: true,
    closeToTray: true,
    showConfirmationDialog: true,
    autoStartDownloads: false,
    clipboardMonitoring: true,
    defaultSavePath: 'C:\\Users\\User\\Downloads',
    soundOnCompletion: true,
  },
  connection: {
    defaultConnections: 8,
    maxConnectionsPerServer: 16,
    connectionTimeout: 15,
    maxRetries: 3,
    userAgent: 'SmartDownloadManager/1.0 (Windows NT 10.0; Win64; x64)',
    autoReloadStuck: true,
    stuckTimeoutSeconds: 8,
    slowSpeedThresholdKB: 25,
  },
  speed: {
    enabled: false,
    limitBytesPerSec: 2 * 1024 * 1024, // 2 MB/s
    scheduledLimit: {
      enabled: false,
      daytimeLimit: 2 * 1024 * 1024,
      nighttimeLimit: 0,
      dayStartTime: '08:00',
      nightStartTime: '23:00',
    }
  },
  scheduler: {
    enabled: false,
    startTime: '22:00',
    stopTime: '06:00',
    maxConcurrentDownloads: 3,
    actionOnCompletion: 'none',
    daysOfWeek: [1, 2, 3, 4, 5, 6, 0],
    autoStartQueue: true
  },
  appearance: {
    theme: 'fluent-mica',
    accentColor: '#0284c7',
    showSpeedGraph: true,
    showSegmentVisualizer: true,
    compactView: false,
  },
  browserIntegration: {
    chromeEnabled: true,
    edgeEnabled: true,
    firefoxEnabled: false,
    interceptDownloads: true,
    mediaSnifferEnabled: true,
    minVideoSizeMB: 1,
    ignoredDomains: ['localhost', '127.0.0.1'],
  },
  security: {
    sanitizeFilenames: true,
    preventPathTraversal: true,
    scanWithDefender: true,
    blockExecutablesFromUntrusted: true,
  },
  categories: {
    autoOrganizeEnabled: true,
    createFoldersIfMissing: true,
    baseDownloadPath: 'C:\\Users\\User\\Downloads',
    categoryPaths: {
      Videos: 'C:\\Users\\User\\Downloads\\Videos',
      Music: 'C:\\Users\\User\\Downloads\\Music',
      Documents: 'C:\\Users\\User\\Downloads\\Documents',
      Images: 'C:\\Users\\User\\Downloads\\Images',
      Programs: 'C:\\Users\\User\\Downloads\\Programs',
      Archives: 'C:\\Users\\User\\Downloads\\Archives',
      Other: 'C:\\Users\\User\\Downloads\\Other',
    },
    customExtensions: {
      Videos: ['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', 'wmv', 'm4v', 'ts', 'm3u8', '3gp'],
      Music: ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma', 'opus'],
      Documents: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'epub', 'rtf', 'odt', 'md'],
      Images: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'ico', 'tiff', 'psd'],
      Programs: ['exe', 'msi', 'apk', 'dmg', 'deb', 'rpm', 'appimage', 'bat', 'cmd'],
      Archives: ['zip', 'rar', '7z', 'tar', 'gz', 'iso', 'bz2', 'xz'],
    }
  }
};

export const INITIAL_CATEGORIES: CategoryInfo[] = [
  { id: 'all', name: 'Other', icon: 'Folder', defaultPath: 'C:\\Users\\User\\Downloads', extensions: [], count: 6 },
  { id: 'videos', name: 'Videos', icon: 'Video', defaultPath: 'C:\\Users\\User\\Downloads\\Videos', extensions: ['mp4', 'mkv', 'avi', 'mov', 'webm'], count: 2 },
  { id: 'music', name: 'Music', icon: 'Music', defaultPath: 'C:\\Users\\User\\Downloads\\Music', extensions: ['mp3', 'wav', 'flac', 'aac'], count: 1 },
  { id: 'documents', name: 'Documents', icon: 'FileText', defaultPath: 'C:\\Users\\User\\Downloads\\Documents', extensions: ['pdf', 'docx', 'xlsx', 'txt'], count: 1 },
  { id: 'images', name: 'Images', icon: 'Image', defaultPath: 'C:\\Users\\User\\Downloads\\Images', extensions: ['jpg', 'png', 'webp', 'svg'], count: 1 },
  { id: 'programs', name: 'Programs', icon: 'Box', defaultPath: 'C:\\Users\\User\\Downloads\\Programs', extensions: ['exe', 'msi', 'apk'], count: 1 },
  { id: 'archives', name: 'Archives', icon: 'Archive', defaultPath: 'C:\\Users\\User\\Downloads\\Archives', extensions: ['zip', 'rar', '7z', 'iso'], count: 1 },
];

export const INITIAL_DOWNLOADS: DownloadTask[] = [
  {
    id: 'dl-101',
    url: '/api/test-files/ubuntu-24.04-desktop-amd64.iso',
    filename: 'ubuntu-24.04-desktop-amd64.iso',
    category: 'Archives',
    status: 'downloading',
    totalBytes: 52428800, // 50 MB demo
    downloadedBytes: 29884416, // ~57%
    speed: 4850000, // ~4.8 MB/s
    eta: 5,
    connectionCount: 8,
    segments: createDownloadSegments(52428800, 8).map((seg, idx) => ({
      ...seg,
      downloadedBytes: Math.floor(seg.totalBytes * (0.4 + (idx % 4) * 0.15)),
      speed: 600000 + (idx * 50000),
      status: 'downloading'
    })),
    savePath: 'C:\\Users\\User\\Downloads\\Archives\\ubuntu-24.04-desktop-amd64.iso',
    mimeType: 'application/x-iso9660-image',
    resumable: true,
    createdAt: Date.now() - 120000,
    retryCount: 0,
    sourcePageUrl: 'https://releases.ubuntu.com/noble/'
  },
  {
    id: 'dl-102',
    url: '/api/test-files/nature_4k_cinematic_landscape.mp4',
    filename: 'nature_4k_cinematic_landscape.mp4',
    category: 'Videos',
    status: 'downloading',
    totalBytes: 26214400, // 25 MB
    downloadedBytes: 18454912, // ~70%
    speed: 3650000, // ~3.6 MB/s
    eta: 2,
    connectionCount: 8,
    segments: createDownloadSegments(26214400, 8).map((seg, idx) => ({
      ...seg,
      downloadedBytes: Math.floor(seg.totalBytes * (0.6 + (idx % 3) * 0.13)),
      speed: 450000 + (idx * 30000),
      status: 'downloading'
    })),
    savePath: 'C:\\Users\\User\\Downloads\\Videos\\nature_4k_cinematic_landscape.mp4',
    mimeType: 'video/mp4',
    resumable: true,
    createdAt: Date.now() - 80000,
    retryCount: 0,
    quality: '1080p Full HD',
    sourcePageUrl: 'https://video-hub.internal/watch?v=landscape4k'
  },
  {
    id: 'dl-103',
    url: '/api/test-files/developer_toolchain_v3.4.1_setup.exe',
    filename: 'developer_toolchain_v3.4.1_setup.exe',
    category: 'Programs',
    status: 'paused',
    totalBytes: 15728640, // 15 MB
    downloadedBytes: 6815744, // ~43%
    speed: 0,
    eta: 0,
    connectionCount: 4,
    segments: createDownloadSegments(15728640, 4).map((seg) => ({
      ...seg,
      downloadedBytes: Math.floor(seg.totalBytes * 0.43),
      status: 'idle',
      speed: 0
    })),
    savePath: 'C:\\Users\\User\\Downloads\\Programs\\developer_toolchain_v3.4.1_setup.exe',
    mimeType: 'application/octet-stream',
    resumable: true,
    createdAt: Date.now() - 360000,
    retryCount: 0,
    sourcePageUrl: 'https://dev-tools.internal/releases/'
  },
  {
    id: 'dl-104',
    url: '/api/test-files/project_architecture_spec_2026.pdf',
    filename: 'project_architecture_spec_2026.pdf',
    category: 'Documents',
    status: 'completed',
    totalBytes: 2097152, // 2 MB
    downloadedBytes: 2097152,
    speed: 0,
    eta: 0,
    connectionCount: 4,
    segments: createDownloadSegments(2097152, 4).map((seg) => ({
      ...seg,
      downloadedBytes: seg.totalBytes,
      status: 'completed',
      speed: 0
    })),
    savePath: 'C:\\Users\\User\\Downloads\\Documents\\project_architecture_spec_2026.pdf',
    mimeType: 'application/pdf',
    resumable: true,
    createdAt: Date.now() - 720000,
    completedAt: Date.now() - 690000,
    retryCount: 0,
    checksum: {
      sha256: '9f83c21a4e5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d'
    },
    sourcePageUrl: 'https://docs.internal/architecture.pdf'
  },
  {
    id: 'dl-105',
    url: '/api/test-files/lofi_ambient_coding_session.mp3',
    filename: 'lofi_ambient_coding_session.mp3',
    category: 'Music',
    status: 'completed',
    totalBytes: 5242880, // 5 MB
    downloadedBytes: 5242880,
    speed: 0,
    eta: 0,
    connectionCount: 4,
    segments: createDownloadSegments(5242880, 4).map((seg) => ({
      ...seg,
      downloadedBytes: seg.totalBytes,
      status: 'completed',
      speed: 0
    })),
    savePath: 'C:\\Users\\User\\Downloads\\Music\\lofi_ambient_coding_session.mp3',
    mimeType: 'audio/mpeg',
    resumable: true,
    createdAt: Date.now() - 1800000,
    completedAt: Date.now() - 1790000,
    retryCount: 0,
    sourcePageUrl: 'https://music.internal/track/9482'
  }
];

export const INITIAL_DETECTED_MEDIA: DetectedMediaResource[] = [
  {
    id: 'media-stream-1',
    url: '/api/test-files/sample_presentation_1080p.mp4',
    pageUrl: 'https://video-hub.internal/watch?v=tech_keynote_2026',
    pageTitle: 'Tech Keynote & Future Architecture 2026',
    filename: 'Tech_Keynote_2026_1080p.mp4',
    mimeType: 'video/mp4',
    quality: '1080p Full HD',
    resolution: '1920x1080',
    estimatedSize: 257000000,
    duration: '14:32',
    detectedAt: Date.now() - 25000,
  },
  {
    id: 'media-stream-2',
    url: '/api/test-files/sample_presentation_720p.mp4',
    pageUrl: 'https://video-hub.internal/watch?v=tech_keynote_2026',
    pageTitle: 'Tech Keynote & Future Architecture 2026',
    filename: 'Tech_Keynote_2026_720p.mp4',
    mimeType: 'video/mp4',
    quality: '720p HD',
    resolution: '1280x720',
    estimatedSize: 145000000,
    duration: '14:32',
    detectedAt: Date.now() - 25000,
  },
  {
    id: 'media-stream-3',
    url: '/api/test-files/keynote_audio_320k.mp3',
    pageUrl: 'https://video-hub.internal/watch?v=tech_keynote_2026',
    pageTitle: 'Tech Keynote & Future Architecture 2026',
    filename: 'Tech_Keynote_2026_Audio.mp3',
    mimeType: 'audio/mpeg',
    quality: '320 kbps Audio',
    estimatedSize: 34500000,
    duration: '14:32',
    detectedAt: Date.now() - 25000,
  }
];

export const INITIAL_PACKETS: NativeMessagePacket[] = [
  {
    id: 'pkt-1',
    timestamp: Date.now() - 15000,
    direction: 'chrome_to_host',
    type: 'PING',
    payload: { protocolVersion: 1, client: 'Chrome Extension v1.0.0' },
    status: 'valid'
  },
  {
    id: 'pkt-2',
    timestamp: Date.now() - 14980,
    direction: 'host_to_chrome',
    type: 'PONG',
    payload: { protocolVersion: 1, application: 'SmartDownload Manager', version: '1.0.0', status: 'ready' },
    status: 'valid'
  },
  {
    id: 'pkt-3',
    timestamp: Date.now() - 10000,
    direction: 'chrome_to_host',
    type: 'MEDIA_DETECTED',
    payload: {
      url: 'https://video-hub.internal/watch?v=tech_keynote_2026',
      filename: 'Tech_Keynote_2026_1080p.mp4',
      quality: '1080p',
      size: 257000000
    },
    status: 'valid'
  },
  {
    id: 'pkt-4',
    timestamp: Date.now() - 9980,
    direction: 'host_to_chrome',
    type: 'STATUS_RESPONSE',
    payload: { status: 'acknowledged', activeQueue: 2 },
    status: 'valid'
  }
];
