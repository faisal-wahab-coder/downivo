import React, { useState } from 'react';
import { 
  Globe, 
  ArrowLeft, 
  ArrowRight, 
  RotateCw, 
  ShieldCheck, 
  Puzzle, 
  Download, 
  Film, 
  Sparkles, 
  Play, 
  Music, 
  FileText, 
  Check, 
  X, 
  SlidersHorizontal,
  ExternalLink,
  Layers,
  ChevronRight,
  HardDrive
} from 'lucide-react';
import { DetectedMediaResource } from '../types';
import { formatBytes } from '../services/downloadEngine';

interface ChromeSimulatorProps {
  onSendToManager: (resource: {
    url: string;
    filename: string;
    category?: string;
    size?: number;
    quality?: string;
    pageUrl: string;
  }) => void;
  detectedMedia: DetectedMediaResource[];
}

export const ChromeSimulator: React.FC<ChromeSimulatorProps> = ({
  onSendToManager,
  detectedMedia,
}) => {
  const [activeTab, setActiveTab] = useState<'videohub' | 'fileshare' | 'devportal'>('videohub');
  const [showExtensionPopup, setShowExtensionPopup] = useState(false);
  const [floatingBadgeDismissed, setFloatingBadgeDismissed] = useState(false);
  const [downloadTriggeredToast, setDownloadTriggeredToast] = useState<string | null>(null);
  const [videoPlaying, setVideoPlaying] = useState(true);

  const currentUrls = {
    videohub: 'https://videohub.internal/watch?v=tech_keynote_2026',
    fileshare: 'https://releases.ubuntu.com/noble/',
    devportal: 'https://developer-hub.internal/downloads',
  };

  const handleDownload = (item: {
    url: string;
    filename: string;
    category?: string;
    size?: number;
    quality?: string;
  }) => {
    onSendToManager({
      ...item,
      pageUrl: currentUrls[activeTab],
    });

    setDownloadTriggeredToast(`Sent "${item.filename}" to SmartDownload Manager!`);
    setTimeout(() => setDownloadTriggeredToast(null), 3000);
  };

  return (
    <div id="chrome-simulator" className="flex-1 bg-[#121214] flex flex-col overflow-hidden select-none">
      {/* Chrome Window Top Bar with Tabs */}
      <div className="bg-[#1f1f23] border-b border-[#2d2d32] pt-2 px-2 flex items-center justify-between">
        <div className="flex items-center gap-1">
          {/* Tab 1: Video Hub */}
          <button
            id="chrome-tab-video"
            onClick={() => { setActiveTab('videohub'); setFloatingBadgeDismissed(false); }}
            className={`flex items-center gap-2 px-3 py-1.5 rounded-t-lg text-xs font-medium transition-all ${
              activeTab === 'videohub'
                ? 'bg-[#2b2b30] text-zinc-100 shadow-sm border-t border-x border-zinc-700'
                : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/50'
            }`}
          >
            <Film className="w-3.5 h-3.5 text-red-400" />
            <span>VideoHub - Tech Keynote 4K</span>
            <span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-ping ml-1" />
          </button>

          {/* Tab 2: File Sharing */}
          <button
            id="chrome-tab-files"
            onClick={() => setActiveTab('fileshare')}
            className={`flex items-center gap-2 px-3 py-1.5 rounded-t-lg text-xs font-medium transition-all ${
              activeTab === 'fileshare'
                ? 'bg-[#2b2b30] text-zinc-100 shadow-sm border-t border-x border-zinc-700'
                : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/50'
            }`}
          >
            <HardDrive className="w-3.5 h-3.5 text-orange-400" />
            <span>Ubuntu Releases Mirror</span>
          </button>

          {/* Tab 3: Dev Portal */}
          <button
            id="chrome-tab-dev"
            onClick={() => setActiveTab('devportal')}
            className={`flex items-center gap-2 px-3 py-1.5 rounded-t-lg text-xs font-medium transition-all ${
              activeTab === 'devportal'
                ? 'bg-[#2b2b30] text-zinc-100 shadow-sm border-t border-x border-zinc-700'
                : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/50'
            }`}
          >
            <Globe className="w-3.5 h-3.5 text-sky-400" />
            <span>Developer Software Hub</span>
          </button>
        </div>

        {/* Chrome Window Actions */}
        <div className="flex items-center gap-2 text-zinc-400 text-xs pb-1 pr-2">
          <span className="text-[11px] text-zinc-500">Google Chrome (Simulated Sandbox)</span>
        </div>
      </div>

      {/* Chrome Navigation & Omnibox Bar */}
      <div className="bg-[#2b2b30] px-3 py-1.5 border-b border-[#38383e] flex items-center justify-between gap-3 text-xs">
        <div className="flex items-center gap-1.5 text-zinc-400">
          <button className="p-1 hover:bg-zinc-700 rounded transition-colors" title="Back">
            <ArrowLeft className="w-3.5 h-3.5" />
          </button>
          <button className="p-1 hover:bg-zinc-700 rounded transition-colors" title="Forward">
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
          <button className="p-1 hover:bg-zinc-700 rounded transition-colors" title="Reload">
            <RotateCw className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Omnibox Address Bar */}
        <div className="flex-1 max-w-2xl bg-[#1e1e22] border border-zinc-700 text-zinc-200 px-3 py-1 rounded-full flex items-center gap-2 text-[11px]">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
          <span className="font-mono truncate">{currentUrls[activeTab]}</span>
        </div>

        {/* Chrome Extensions Tray */}
        <div className="flex items-center gap-2 relative">
          {/* SmartDownload Extension Action Button */}
          <button
            id="chrome-extension-icon-btn"
            onClick={() => setShowExtensionPopup(!showExtensionPopup)}
            className="flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-sky-500/20 text-sky-300 border border-sky-500/40 hover:bg-sky-500/30 transition-all font-semibold text-[11px]"
            title="SmartDownload Manager Chrome Extension"
          >
            <Download className="w-3.5 h-3.5" />
            <span>SmartDownload</span>
            <span className="w-4 h-4 rounded-full bg-emerald-500 text-zinc-950 text-[10px] font-bold flex items-center justify-center">
              {detectedMedia.length}
            </span>
          </button>

          {/* Chrome Toolbar Extension Dropdown Popup */}
          {showExtensionPopup && (
            <div 
              id="chrome-extension-popup"
              className="absolute right-0 top-9 z-50 w-80 bg-[#18181b] border border-zinc-700 rounded-xl shadow-2xl p-3 text-zinc-200 animate-scaleUp"
            >
              <div className="flex items-center justify-between border-b border-zinc-800 pb-2 mb-2">
                <div className="flex items-center gap-1.5 font-bold text-xs text-sky-400">
                  <Download className="w-3.5 h-3.5" />
                  <span>SmartDownload Manager</span>
                </div>
                <span className="px-2 py-0.5 rounded-full text-[10px] bg-emerald-500/20 text-emerald-400 font-semibold border border-emerald-500/30">
                  ● Connected
                </span>
              </div>

              <div className="text-[11px] font-semibold text-zinc-400 mb-1.5">
                Media Detected on this Page ({detectedMedia.length})
              </div>

              <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
                {detectedMedia.map((res) => (
                  <div key={res.id} className="bg-zinc-900 border border-zinc-800 rounded-lg p-2 text-xs">
                    <div className="font-medium text-zinc-200 truncate text-[11px] mb-1">
                      {res.filename}
                    </div>
                    <div className="flex items-center justify-between text-[10px] text-zinc-400 mb-1.5">
                      <span>{res.quality}</span>
                      <span>{res.estimatedSize ? formatBytes(res.estimatedSize) : 'Dynamic Stream'}</span>
                    </div>
                    <button
                      onClick={() => {
                        handleDownload({
                          url: res.url,
                          filename: res.filename,
                          quality: res.quality,
                          size: res.estimatedSize,
                          category: 'Videos'
                        });
                        setShowExtensionPopup(false);
                      }}
                      className="w-full py-1 bg-sky-600 hover:bg-sky-500 text-white rounded text-[11px] font-medium flex items-center justify-center gap-1 shadow-xs"
                    >
                      <Download className="w-3 h-3" />
                      <span>Download with SmartDownload</span>
                    </button>
                  </div>
                ))}
              </div>

              <div className="pt-2 mt-2 border-t border-zinc-800 flex justify-between items-center text-[10px] text-zinc-400">
                <span>Native Host v1.0.0</span>
                <span className="text-sky-400">Settings</span>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Simulated Webpage Content */}
      <div className="flex-1 bg-[#0f0f11] overflow-y-auto p-6 relative">
        {/* Notification Toast when download triggered */}
        {downloadTriggeredToast && (
          <div className="fixed top-20 right-8 z-50 bg-sky-600 text-white px-4 py-2.5 rounded-lg shadow-xl flex items-center gap-2 text-xs font-semibold animate-slideDown">
            <Check className="w-4 h-4" />
            <span>{downloadTriggeredToast}</span>
          </div>
        )}

        {/* TAB 1: VIDEO HUB */}
        {activeTab === 'videohub' && (
          <div className="max-w-4xl mx-auto space-y-6">
            {/* Simulated Video Player */}
            <div className="bg-zinc-950 border border-zinc-800 rounded-xl overflow-hidden shadow-2xl relative group">
              <div className="aspect-video w-full bg-linear-to-tr from-zinc-950 via-zinc-900 to-sky-950/40 flex flex-col items-center justify-center relative">
                <div className="w-16 h-16 rounded-full bg-sky-600/90 text-white flex items-center justify-center shadow-lg group-hover:scale-110 transition-transform cursor-pointer">
                  <Play className="w-8 h-8 fill-current ml-1" />
                </div>
                <div className="absolute bottom-4 left-4 right-4 bg-zinc-900/80 backdrop-blur-md p-3 rounded-lg border border-zinc-800 flex items-center justify-between text-xs text-zinc-200">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse" />
                    <span className="font-semibold">Tech Keynote & Future Architecture 2026</span>
                  </div>
                  <span className="text-[11px] font-mono text-zinc-400">1080p 60fps • H.264 / AAC</span>
                </div>
              </div>
            </div>

            {/* Video Details & Sniffer Options */}
            <div className="bg-zinc-900/60 border border-zinc-800 p-5 rounded-xl space-y-3">
              <div className="flex justify-between items-start">
                <div>
                  <h2 className="text-lg font-bold text-zinc-100">Next-Generation Systems Keynote 2026</h2>
                  <p className="text-xs text-zinc-400 mt-1">Uploaded by Enterprise Media Studio • 450,210 views • 14:32 duration</p>
                </div>
              </div>

              {/* Quality Download Badges */}
              <div className="pt-3 border-t border-zinc-800">
                <div className="text-xs font-semibold text-zinc-300 mb-2 flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5 text-sky-400" />
                  <span>Available Media Streams Detected by SmartDownload Extension:</span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                  <div className="bg-zinc-950 p-3 rounded-lg border border-zinc-800 flex flex-col justify-between">
                    <div>
                      <div className="flex justify-between text-xs font-semibold text-zinc-100">
                        <span>1080p Full HD</span>
                        <span className="text-sky-400">257 MB</span>
                      </div>
                      <div className="text-[10px] text-zinc-500 mt-0.5">MP4 • 1920x1080 • Bitrate: 4500 kbps</div>
                    </div>
                    <button
                      id="btn-dl-1080p"
                      onClick={() => handleDownload({
                        url: '/api/test-files/sample_presentation_1080p.mp4',
                        filename: 'Tech_Keynote_2026_1080p.mp4',
                        size: 257000000,
                        quality: '1080p Full HD',
                        category: 'Videos'
                      })}
                      className="mt-2 py-1.5 bg-sky-600 hover:bg-sky-500 text-white rounded text-xs font-semibold flex items-center justify-center gap-1 shadow-sm"
                    >
                      <Download className="w-3.5 h-3.5" />
                      <span>Download 1080p</span>
                    </button>
                  </div>

                  <div className="bg-zinc-950 p-3 rounded-lg border border-zinc-800 flex flex-col justify-between">
                    <div>
                      <div className="flex justify-between text-xs font-semibold text-zinc-100">
                        <span>720p HD</span>
                        <span className="text-sky-400">145 MB</span>
                      </div>
                      <div className="text-[10px] text-zinc-500 mt-0.5">MP4 • 1280x720 • Bitrate: 2500 kbps</div>
                    </div>
                    <button
                      id="btn-dl-720p"
                      onClick={() => handleDownload({
                        url: '/api/test-files/sample_presentation_720p.mp4',
                        filename: 'Tech_Keynote_2026_720p.mp4',
                        size: 145000000,
                        quality: '720p HD',
                        category: 'Videos'
                      })}
                      className="mt-2 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded text-xs font-semibold flex items-center justify-center gap-1"
                    >
                      <Download className="w-3.5 h-3.5" />
                      <span>Download 720p</span>
                    </button>
                  </div>

                  <div className="bg-zinc-950 p-3 rounded-lg border border-zinc-800 flex flex-col justify-between">
                    <div>
                      <div className="flex justify-between text-xs font-semibold text-zinc-100">
                        <span>320k Audio</span>
                        <span className="text-sky-400">34 MB</span>
                      </div>
                      <div className="text-[10px] text-zinc-500 mt-0.5">MP3 / AAC • 48 kHz High Quality</div>
                    </div>
                    <button
                      id="btn-dl-audio"
                      onClick={() => handleDownload({
                        url: '/api/test-files/keynote_audio_320k.mp3',
                        filename: 'Tech_Keynote_2026_Audio.mp3',
                        size: 34500000,
                        quality: '320 kbps Audio',
                        category: 'Music'
                      })}
                      className="mt-2 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded text-xs font-semibold flex items-center justify-center gap-1"
                    >
                      <Music className="w-3.5 h-3.5" />
                      <span>Download Audio</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            {/* FLOATING MEDIA DETECTED OVERLAY BADGE */}
            {!floatingBadgeDismissed && (
              <div 
                id="floating-media-badge"
                className="fixed bottom-8 right-8 z-40 w-72 bg-[#18181c] border border-sky-500/50 rounded-xl shadow-2xl p-3.5 text-zinc-100 animate-slideUp backdrop-blur-md"
              >
                <div className="flex items-center justify-between pb-1.5 border-b border-zinc-800">
                  <div className="flex items-center gap-1.5 text-sky-400 font-bold text-xs">
                    <Film className="w-3.5 h-3.5" />
                    <span>Media Stream Detected</span>
                  </div>
                  <button 
                    onClick={() => setFloatingBadgeDismissed(true)} 
                    className="text-zinc-500 hover:text-white p-0.5"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                </div>

                <div className="py-2 text-xs">
                  <div className="font-semibold truncate text-zinc-200">Tech_Keynote_2026_1080p.mp4</div>
                  <div className="text-[11px] text-zinc-400 mt-0.5">1080p Full HD • 257 MB (H.264)</div>
                </div>

                <div className="flex gap-2 pt-1">
                  <button
                    id="floating-badge-btn-download"
                    onClick={() => {
                      handleDownload({
                        url: '/api/test-files/sample_presentation_1080p.mp4',
                        filename: 'Tech_Keynote_2026_1080p.mp4',
                        size: 257000000,
                        quality: '1080p Full HD',
                        category: 'Videos'
                      });
                      setFloatingBadgeDismissed(true);
                    }}
                    className="flex-1 py-1.5 bg-sky-600 hover:bg-sky-500 text-white rounded text-xs font-semibold flex items-center justify-center gap-1 shadow-sm"
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>Download</span>
                  </button>
                  <button
                    onClick={() => setFloatingBadgeDismissed(true)}
                    className="px-2.5 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded text-xs font-medium"
                  >
                    Ignore
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* TAB 2: FILE SHARING (UBUNTU RELEASES) */}
        {activeTab === 'fileshare' && (
          <div className="max-w-4xl mx-auto space-y-4">
            <div className="bg-zinc-900 border border-zinc-800 p-5 rounded-xl">
              <h2 className="text-base font-bold text-zinc-100">Ubuntu 24.04 LTS (Noble Numbat) Release Mirror</h2>
              <p className="text-xs text-zinc-400 mt-1">Official installation desktop and server ISO images with high-speed multi-connection HTTP range support.</p>
            </div>

            <div className="bg-zinc-900/80 border border-zinc-800 rounded-xl overflow-hidden">
              <div className="p-3 bg-zinc-950/60 border-b border-zinc-800 text-xs font-semibold text-zinc-300">
                Direct Download Links (Intercepted by Extension)
              </div>
              <div className="divide-y divide-zinc-800 text-xs">
                <div className="p-3 flex items-center justify-between hover:bg-zinc-800/40 transition-colors">
                  <div>
                    <div className="font-semibold text-zinc-200">ubuntu-24.04-desktop-amd64.iso</div>
                    <div className="text-[11px] text-zinc-500 font-mono">50.0 MB (Sample) • SHA-256 Verified • Accept-Ranges: bytes</div>
                  </div>
                  <button
                    onClick={() => handleDownload({
                      url: '/api/test-files/ubuntu-24.04-desktop-amd64.iso',
                      filename: 'ubuntu-24.04-desktop-amd64.iso',
                      size: 52428800,
                      category: 'Archives'
                    })}
                    className="px-3 py-1.5 bg-sky-600 hover:bg-sky-500 text-white rounded text-xs font-semibold flex items-center gap-1.5"
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>Download ISO</span>
                  </button>
                </div>

                <div className="p-3 flex items-center justify-between hover:bg-zinc-800/40 transition-colors">
                  <div>
                    <div className="font-semibold text-zinc-200">project_architecture_spec_2026.pdf</div>
                    <div className="text-[11px] text-zinc-500 font-mono">2.0 MB • Release Documentation PDF</div>
                  </div>
                  <button
                    onClick={() => handleDownload({
                      url: '/api/test-files/project_architecture_spec_2026.pdf',
                      filename: 'project_architecture_spec_2026.pdf',
                      size: 2097152,
                      category: 'Documents'
                    })}
                    className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded text-xs font-medium flex items-center gap-1.5"
                  >
                    <FileText className="w-3.5 h-3.5" />
                    <span>Download PDF</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TAB 3: DEVELOPER SOFTWARE HUB */}
        {activeTab === 'devportal' && (
          <div className="max-w-4xl mx-auto space-y-4">
            <div className="bg-zinc-900 border border-zinc-800 p-5 rounded-xl">
              <h2 className="text-base font-bold text-zinc-100">Developer Toolchain & Software Releases</h2>
              <p className="text-xs text-zinc-400 mt-1">Download native Windows binaries and installer setups.</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="bg-zinc-900/90 border border-zinc-800 p-4 rounded-xl flex flex-col justify-between">
                <div>
                  <div className="font-bold text-zinc-100">Developer Toolchain Setup v3.4.1</div>
                  <div className="text-[11px] text-zinc-400 mt-1">Windows x64 Executable Installer (15.0 MB)</div>
                </div>
                <button
                  onClick={() => handleDownload({
                    url: '/api/test-files/developer_toolchain_v3.4.1_setup.exe',
                    filename: 'developer_toolchain_v3.4.1_setup.exe',
                    size: 15728640,
                    category: 'Programs'
                  })}
                  className="mt-3 py-2 bg-sky-600 hover:bg-sky-500 text-white rounded-lg text-xs font-semibold flex items-center justify-center gap-1.5"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Download .EXE with SmartDownload</span>
                </button>
              </div>

              <div className="bg-zinc-900/90 border border-zinc-800 p-4 rounded-xl flex flex-col justify-between">
                <div>
                  <div className="font-bold text-zinc-100">Lofi Ambient Coding Session Soundtrack</div>
                  <div className="text-[11px] text-zinc-400 mt-1">High-Fidelity Stereo MP3 (5.0 MB)</div>
                </div>
                <button
                  onClick={() => handleDownload({
                    url: '/api/test-files/lofi_ambient_coding_session.mp3',
                    filename: 'lofi_ambient_coding_session.mp3',
                    size: 5242880,
                    category: 'Music'
                  })}
                  className="mt-3 py-2 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded-lg text-xs font-semibold flex items-center justify-center gap-1.5"
                >
                  <Music className="w-3.5 h-3.5 text-indigo-400" />
                  <span>Download MP3 Audio</span>
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
