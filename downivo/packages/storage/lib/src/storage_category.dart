/// Category folders under the app download root — docs/01_Project_Overview.md §14
enum StorageCategory {
  videos('Videos'),
  images('Images'),
  audio('Audio'),
  documents('Documents'),
  archives('Archives'),
  apk('APK'),
  qrDownloads('QR Downloads'),
  favorites('Favorites'),
  vault('Vault'),
  temp('Temp'),
  logs('Logs');

  const StorageCategory(this.folderName);

  final String folderName;
}
