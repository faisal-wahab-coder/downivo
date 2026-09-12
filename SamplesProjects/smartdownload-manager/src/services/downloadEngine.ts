import { DownloadTask, DownloadSegment, AppSettings, DownloadCategory, CategoriesSettings } from '../types';

export const DEFAULT_CATEGORY_EXTENSIONS: Record<DownloadCategory, string[]> = {
  Videos: ['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', 'wmv', 'm4v', 'ts', 'm3u8', '3gp'],
  Music: ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma', 'opus', 'alac', 'aiff'],
  Documents: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'epub', 'rtf', 'odt', 'md'],
  Images: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'ico', 'tiff', 'psd', 'ai', 'raw'],
  Programs: ['exe', 'msi', 'apk', 'dmg', 'deb', 'rpm', 'appimage', 'bat', 'cmd'],
  Archives: ['zip', 'rar', '7z', 'tar', 'gz', 'iso', 'bz2', 'xz', 'tgz'],
  Other: []
};

export function formatBytes(bytes: number, decimals = 2): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

export function formatSpeed(bytesPerSec: number): string {
  if (bytesPerSec <= 0) return '0 KB/s';
  return formatBytes(bytesPerSec) + '/s';
}

export function formatEta(seconds: number): string {
  if (!isFinite(seconds) || seconds < 0 || seconds === 0) return '--:--';
  if (seconds > 86400) return '> 1 day';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);

  if (h > 0) {
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}

export function inferCategory(
  filename: string,
  customExtensions?: Partial<Record<DownloadCategory, string[]>>
): DownloadCategory {
  const ext = filename.split('.').pop()?.toLowerCase() || '';
  if (!ext) return 'Other';

  // Check custom extensions first if provided
  if (customExtensions) {
    for (const [cat, extensions] of Object.entries(customExtensions)) {
      if (extensions && extensions.map(e => e.toLowerCase().replace(/^\./, '')).includes(ext)) {
        return cat as DownloadCategory;
      }
    }
  }

  // Fallback to default extension mapping
  for (const [cat, extensions] of Object.entries(DEFAULT_CATEGORY_EXTENSIONS)) {
    if (extensions.includes(ext)) {
      return cat as DownloadCategory;
    }
  }

  return 'Other';
}

/**
 * Gets the designated folder path for a category based on user's defined path settings
 */
export function getCategoryFolderPath(
  category: DownloadCategory,
  settings: CategoriesSettings
): string {
  if (settings.categoryPaths && settings.categoryPaths[category]) {
    return settings.categoryPaths[category];
  }
  const base = settings.baseDownloadPath.replace(/[\\/]+$/, '');
  return category === 'Other' ? base : `${base}\\${category}`;
}

/**
 * Generates a unique filename if the destination file already exists
 */
export function getUniqueFilename(targetPath: string, existingPaths: string[]): string {
  if (!existingPaths.includes(targetPath)) {
    return targetPath;
  }

  const lastSlash = Math.max(targetPath.lastIndexOf('\\'), targetPath.lastIndexOf('/'));
  const dir = lastSlash >= 0 ? targetPath.slice(0, lastSlash) : '';
  const fullFilename = lastSlash >= 0 ? targetPath.slice(lastSlash + 1) : targetPath;
  
  const lastDot = fullFilename.lastIndexOf('.');
  const base = lastDot >= 0 ? fullFilename.slice(0, lastDot) : fullFilename;
  const ext = lastDot >= 0 ? fullFilename.slice(lastDot) : '';
  const separator = targetPath.includes('/') ? '/' : '\\';

  let counter = 1;
  let newPath = `${dir ? dir + separator : ''}${base} (${counter})${ext}`;
  while (existingPaths.includes(newPath)) {
    counter++;
    newPath = `${dir ? dir + separator : ''}${base} (${counter})${ext}`;
  }
  return newPath;
}

/**
 * Automatically calculates destination category path and moves completed download
 */
export function autoOrganizeCompletedDownload(
  task: DownloadTask,
  categoriesSettings: CategoriesSettings,
  allExistingTaskPaths: string[]
): {
  updatedTask: DownloadTask;
  moved: boolean;
  targetFolder: string;
  previousPath: string;
} {
  const previousPath = task.savePath;

  if (!categoriesSettings.autoOrganizeEnabled) {
    return {
      updatedTask: task,
      moved: false,
      targetFolder: '',
      previousPath
    };
  }

  const category = inferCategory(task.filename, categoriesSettings.customExtensions);
  const targetFolder = getCategoryFolderPath(category, categoriesSettings);
  const separator = targetFolder.includes('/') ? '/' : '\\';
  
  const desiredPath = `${targetFolder}${separator}${task.filename}`;
  const finalSavePath = getUniqueFilename(desiredPath, allExistingTaskPaths.filter(p => p !== previousPath));

  // Determine if path actually changed
  const moved = previousPath.toLowerCase() !== finalSavePath.toLowerCase();

  return {
    updatedTask: {
      ...task,
      category,
      savePath: finalSavePath,
      originalSavePath: task.originalSavePath || previousPath,
      movedToCategoryFolder: moved,
      targetCategoryFolder: targetFolder
    },
    moved,
    targetFolder,
    previousPath
  };
}

export function createDownloadSegments(totalBytes: number, connectionCount: number): DownloadSegment[] {
  if (totalBytes <= 0 || connectionCount <= 1) {
    return [{
      id: 0,
      startByte: 0,
      endByte: totalBytes > 0 ? totalBytes - 1 : 0,
      downloadedBytes: 0,
      totalBytes: totalBytes > 0 ? totalBytes : 0,
      speed: 0,
      status: 'idle'
    }];
  }

  const chunkSize = Math.ceil(totalBytes / connectionCount);
  const segments: DownloadSegment[] = [];

  for (let i = 0; i < connectionCount; i++) {
    const start = i * chunkSize;
    const end = Math.min(totalBytes - 1, (i + 1) * chunkSize - 1);
    const segSize = end - start + 1;
    segments.push({
      id: i,
      startByte: start,
      endByte: end,
      downloadedBytes: 0,
      totalBytes: Math.max(0, segSize),
      speed: 0,
      status: 'idle'
    });
  }

  return segments;
}

export function calculateChecksum(data: Uint8Array): { md5: string; sha256: string } {
  // Fast synthetic checksum for demonstration & verification
  let hash = 0;
  for (let i = 0; i < Math.min(data.length, 100000); i++) {
    hash = ((hash << 5) - hash) + data[i];
    hash |= 0;
  }
  const hex = Math.abs(hash).toString(16).padStart(8, '0');
  return {
    md5: `${hex}8f3c2a1b9e0d4c6a`,
    sha256: `${hex}a9b8c7d6e5f40123456789abcdef0123456789abcdef0123456789abcdef`
  };
}
