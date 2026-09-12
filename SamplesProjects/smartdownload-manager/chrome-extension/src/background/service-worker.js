/**
 * SmartDownload Manager - Chrome Service Worker (Manifest V3)
 * Handles Native Messaging bridge, download routing, and context menu items
 */

const NATIVE_HOST_NAME = "com.smartdownload.manager";
let nativePort = null;
let isConnected = false;

// Connect to Windows Native Messaging Host
function connectNativeHost() {
  try {
    nativePort = chrome.runtime.connectNative(NATIVE_HOST_NAME);
    nativePort.onMessage.addListener(handleNativeMessage);
    nativePort.onDisconnect.addListener(() => {
      isConnected = false;
      console.warn("SmartDownload Native Host disconnected:", chrome.runtime.lastError?.message);
      updateBadge(false);
    });
    
    // Send initial handshake ping
    nativePort.postMessage({ protocolVersion: 1, type: "PING" });
    isConnected = true;
    updateBadge(true);
  } catch (err) {
    console.error("Failed to connect to native host:", err);
    isConnected = false;
    updateBadge(false);
  }
}

function handleNativeMessage(msg) {
  if (msg.type === "PONG") {
    console.log("Native host connected:", msg.application, msg.version);
    isConnected = true;
    updateBadge(true);
  }
}

function updateBadge(connected) {
  chrome.action.setBadgeText({ text: connected ? "ON" : "OFF" });
  chrome.action.setBadgeBackgroundColor({ color: connected ? "#10b981" : "#ef4444" });
}

// Intercept standard browser downloads
chrome.downloads.onCreated.addListener(async (downloadItem) => {
  const settings = await chrome.storage.local.get({ interceptDownloads: true });
  if (!settings.interceptDownloads) return;

  const url = downloadItem.url;
  const filename = downloadItem.filename;

  // Send request to Windows Native Host
  if (nativePort && isConnected) {
    nativePort.postMessage({
      protocolVersion: 1,
      type: "DOWNLOAD_REQUEST",
      data: {
        url: url,
        filename: filename,
        totalBytes: downloadItem.totalBytes,
        mime: downloadItem.mime
      }
    });

    // Cancel Chrome default download
    chrome.downloads.cancel(downloadItem.id);
  }
});

// Setup Context Menu
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "smartdownload-parent",
    title: "SmartDownload Manager",
    contexts: ["link", "image", "video", "audio", "selection"]
  });

  chrome.contextMenus.create({
    parentId: "smartdownload-parent",
    id: "smartdownload-link",
    title: "Download Link with SmartDownload",
    contexts: ["link"]
  });

  chrome.contextMenus.create({
    parentId: "smartdownload-parent",
    id: "smartdownload-media",
    title: "Download Media with SmartDownload",
    contexts: ["image", "video", "audio"]
  });

  connectNativeHost();
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  const targetUrl = info.linkUrl || info.srcUrl || info.selectionText;
  if (targetUrl && nativePort && isConnected) {
    nativePort.postMessage({
      protocolVersion: 1,
      type: "DOWNLOAD_REQUEST",
      data: {
        url: targetUrl,
        pageUrl: tab?.url,
        pageTitle: tab?.title
      }
    });
  }
});

// Listen from Content Scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === "SEND_TO_MANAGER") {
    if (nativePort && isConnected) {
      nativePort.postMessage({
        protocolVersion: 1,
        type: "DOWNLOAD_REQUEST",
        data: request.data
      });
      sendResponse({ status: "success" });
    } else {
      sendResponse({ status: "not_connected" });
    }
  } else if (request.type === "CHECK_CONNECTION") {
    sendResponse({ connected: isConnected });
  }
  return true;
});
