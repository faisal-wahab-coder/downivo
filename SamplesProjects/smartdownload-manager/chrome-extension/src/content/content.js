/**
 * SmartDownload Manager - Media Sniffer & Floating Detector
 * Observes HTML5 video/audio elements and network resource manifests without bypassing DRM
 */

(function () {
  const detectedResources = new Map();

  function scanMediaElements() {
    const videos = document.querySelectorAll('video, audio');
    videos.forEach((el, index) => {
      const src = el.currentSrc || el.src;
      if (src && src.startsWith('http') && !detectedResources.has(src)) {
        const ext = src.split('.').pop().split('?')[0].toLowerCase();
        const quality = el.videoHeight ? el.videoHeight + 'p' : 'HD Video';
        
        const resource = {
          id: 'media-' + Date.now() + '-' + index,
          url: src,
          pageUrl: window.location.href,
          pageTitle: document.title,
          filename: document.title.replace(/[^a-zA-Z0-9_-]/g, '_') + '.' + (ext || 'mp4'),
          quality: quality,
          mimeType: 'video/mp4'
        };

        detectedResources.set(src, resource);
        showFloatingBadge(resource);
      }
    });
  }

  function showFloatingBadge(resource) {
    if (document.getElementById('smartdownload-floating-badge')) return;

    const badge = document.createElement('div');
    badge.id = 'smartdownload-floating-badge';
    badge.className = 'smartdownload-overlay-container';
    badge.innerHTML = `
      <div class="sd-badge-header">
        <span class="sd-icon">⚡</span>
        <span class="sd-title">SmartDownload Detected</span>
        <button class="sd-close" id="sd-close-btn">&times;</button>
      </div>
      <div class="sd-badge-body">
        <div class="sd-res-name">${resource.filename.substring(0, 30)}...</div>
        <div class="sd-res-quality">${resource.quality} • MP4</div>
      </div>
      <div class="sd-badge-actions">
        <button class="sd-btn-download" id="sd-download-btn">Download Now</button>
        <button class="sd-btn-ignore" id="sd-ignore-btn">Ignore</button>
      </div>
    `;

    document.body.appendChild(badge);

    document.getElementById('sd-download-btn')?.addEventListener('click', () => {
      chrome.runtime.sendMessage({
        type: 'SEND_TO_MANAGER',
        data: resource
      }, (res) => {
        badge.remove();
      });
    });

    document.getElementById('sd-close-btn')?.addEventListener('click', () => badge.remove());
    document.getElementById('sd-ignore-btn')?.addEventListener('click', () => badge.remove());
  }

  // Observe DOM for newly mounted video players
  const observer = new MutationObserver(() => scanMediaElements());
  observer.observe(document.body, { childList: true, subtree: true });

  // Initial Scan
  window.addEventListener('load', scanMediaElements);
})();
