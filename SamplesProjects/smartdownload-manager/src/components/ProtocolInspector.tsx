import React, { useState } from 'react';
import { 
  Cpu, 
  Send, 
  ShieldCheck, 
  ShieldAlert, 
  CheckCircle2, 
  RefreshCw, 
  Trash2, 
  Terminal, 
  Copy, 
  Sparkles,
  ArrowDown,
  ArrowUp
} from 'lucide-react';
import { NativeMessagePacket } from '../types';

interface ProtocolInspectorProps {
  packets: NativeMessagePacket[];
  onSendCustomPacket: (packet: Partial<NativeMessagePacket>) => void;
  onClearPackets: () => void;
}

export const ProtocolInspector: React.FC<ProtocolInspectorProps> = ({
  packets,
  onSendCustomPacket,
  onClearPackets,
}) => {
  const [selectedPacket, setSelectedPacket] = useState<NativeMessagePacket | null>(packets[packets.length - 1] || null);
  const [testUrl, setTestUrl] = useState('https://example.com/safe_file.zip');
  const [securityResult, setSecurityResult] = useState<string | null>(null);

  const handleSendPing = () => {
    onSendCustomPacket({
      direction: 'chrome_to_host',
      type: 'PING',
      payload: { protocolVersion: 1, origin: 'chrome-extension://ogkfpobcjkfkhdjjmjkpkdbkddglopom' },
      status: 'valid'
    });
  };

  const handleSendStatusReq = () => {
    onSendCustomPacket({
      direction: 'chrome_to_host',
      type: 'GET_STATUS',
      payload: { protocolVersion: 1 },
      status: 'valid'
    });
  };

  const handleTestSecurity = (urlToTest: string) => {
    setTestUrl(urlToTest);
    const isSafe = urlToTest.startsWith('http://') || urlToTest.startsWith('https://') || urlToTest.startsWith('/api/');
    if (!isSafe) {
      setSecurityResult(`[BLOCKED BY HOST] Security Violation: Disallowed scheme "${urlToTest.split(':')[0]}". Native Host rejected execution.`);
      onSendCustomPacket({
        direction: 'chrome_to_host',
        type: 'DOWNLOAD_REQUEST',
        payload: { url: urlToTest },
        status: 'blocked',
        error: 'Disallowed scheme injection attempt'
      });
    } else {
      setSecurityResult(`[PASSED] URL protocol validated as safe HTTP/HTTPS.`);
      onSendCustomPacket({
        direction: 'chrome_to_host',
        type: 'DOWNLOAD_REQUEST',
        payload: { url: urlToTest, filename: urlToTest.split('/').pop() },
        status: 'valid'
      });
    }
  };

  return (
    <div id="protocol-inspector" className="flex-1 bg-[#141416] p-4 flex flex-col gap-3 select-none overflow-hidden text-xs text-zinc-200">
      {/* Top Banner */}
      <div className="bg-[#1f1f23] border border-zinc-700 p-3 rounded-xl flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-sky-500/20 text-sky-400 border border-sky-500/30 flex items-center justify-center">
            <Cpu className="w-4 h-4" />
          </div>
          <div>
            <h3 className="font-bold text-sm text-zinc-100 flex items-center gap-2">
              Chrome Native Messaging Protocol Inspector
              <span className="text-[10px] bg-emerald-500/20 text-emerald-400 px-2 py-0.5 rounded-full font-semibold border border-emerald-500/30">
                Active Binary Channel
              </span>
            </h3>
            <p className="text-[11px] text-zinc-400 mt-0.5">
              Length-prefixed 32-bit integer binary JSON stream (<code className="text-sky-400">com.smartdownload.manager</code>)
            </p>
          </div>
        </div>

        {/* Quick Packet Triggers */}
        <div className="flex items-center gap-2">
          <button
            onClick={handleSendPing}
            className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded-md font-medium text-xs flex items-center gap-1.5"
          >
            <Send className="w-3 h-3 text-sky-400" />
            <span>Send PING</span>
          </button>

          <button
            onClick={handleSendStatusReq}
            className="px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700 rounded-md font-medium text-xs flex items-center gap-1.5"
          >
            <RefreshCw className="w-3 h-3 text-emerald-400" />
            <span>Request STATUS</span>
          </button>

          <button
            onClick={onClearPackets}
            className="p-1.5 text-zinc-500 hover:text-rose-400 rounded hover:bg-zinc-800 transition-colors"
            title="Clear Packets Log"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Main Two-Column View */}
      <div className="flex-1 flex gap-3 overflow-hidden">
        {/* Left Column: Packet List */}
        <div className="w-1/2 bg-[#1b1b1e] border border-zinc-800 rounded-xl flex flex-col overflow-hidden">
          <div className="p-2.5 bg-[#222226] border-b border-zinc-800 font-semibold text-xs text-zinc-300 flex justify-between">
            <span>Transmitted Packets ({packets.length})</span>
            <span className="text-[10px] text-zinc-500">Live JSON Stream</span>
          </div>

          <div className="flex-1 overflow-y-auto divide-y divide-zinc-800/80 p-1">
            {packets.map((pkt) => {
              const isSelected = selectedPacket?.id === pkt.id;
              const isChromeToHost = pkt.direction === 'chrome_to_host';

              return (
                <div
                  key={pkt.id}
                  onClick={() => setSelectedPacket(pkt)}
                  className={`p-2 rounded cursor-pointer transition-colors ${
                    isSelected ? 'bg-sky-950/60 border border-sky-500/40 text-zinc-100' : 'hover:bg-zinc-800/50 text-zinc-300'
                  }`}
                >
                  <div className="flex items-center justify-between mb-1 text-[10px]">
                    <div className="flex items-center gap-1.5 font-bold">
                      {isChromeToHost ? (
                        <span className="text-amber-400 flex items-center gap-1">
                          <ArrowDown className="w-3 h-3" /> Chrome → Host
                        </span>
                      ) : (
                        <span className="text-emerald-400 flex items-center gap-1">
                          <ArrowUp className="w-3 h-3" /> Host → Chrome
                        </span>
                      )}
                    </div>
                    <span className="text-zinc-500 font-mono">
                      {new Date(pkt.timestamp).toLocaleTimeString()}
                    </span>
                  </div>

                  <div className="flex items-center justify-between text-xs">
                    <span className="font-mono font-semibold text-sky-400">{pkt.type}</span>
                    <span className={`px-1.5 py-0.2 rounded text-[9px] font-mono ${
                      pkt.status === 'valid' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-rose-500/20 text-rose-400'
                    }`}>
                      {pkt.status.toUpperCase()}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Column: Packet Detail & Security Sandbox */}
        <div className="w-1/2 flex flex-col gap-3 overflow-hidden">
          {/* Packet JSON Payload Viewer */}
          <div className="flex-1 bg-[#1b1b1e] border border-zinc-800 rounded-xl flex flex-col overflow-hidden">
            <div className="p-2.5 bg-[#222226] border-b border-zinc-800 font-semibold text-xs text-zinc-300 flex justify-between items-center">
              <span>Packet Payload ({selectedPacket?.type || 'None selected'})</span>
              {selectedPacket && (
                <button
                  onClick={() => navigator.clipboard.writeText(JSON.stringify(selectedPacket.payload, null, 2))}
                  className="text-zinc-400 hover:text-white flex items-center gap-1 text-[11px]"
                >
                  <Copy className="w-3 h-3" />
                  <span>Copy JSON</span>
                </button>
              )}
            </div>

            <div className="flex-1 p-3 bg-zinc-950 font-mono text-[11px] text-sky-300 overflow-auto">
              {selectedPacket ? (
                <pre>{JSON.stringify(selectedPacket, null, 2)}</pre>
              ) : (
                <span className="text-zinc-600">Select a packet from the stream to inspect headers and payload</span>
              )}
            </div>
          </div>

          {/* Interactive Security Defense Tester */}
          <div className="bg-[#1b1b1e] border border-zinc-800 rounded-xl p-3.5 space-y-2">
            <div className="flex items-center gap-2 font-semibold text-xs text-zinc-200">
              <ShieldCheck className="w-4 h-4 text-emerald-400" />
              <span>Native Host Security & Scheme Validation Sandbox</span>
            </div>
            <p className="text-[11px] text-zinc-400">
              Test host defense against command injection, file URL schemes, and path traversal:
            </p>

            <div className="flex gap-2">
              <input
                type="text"
                value={testUrl}
                onChange={(e) => setTestUrl(e.target.value)}
                className="flex-1 bg-zinc-950 border border-zinc-700 px-2.5 py-1 text-[11px] font-mono text-zinc-200 rounded"
              />
              <button
                onClick={() => handleTestSecurity(testUrl)}
                className="px-3 py-1 bg-sky-600 hover:bg-sky-500 text-white font-medium rounded text-xs"
              >
                Validate
              </button>
            </div>

            {/* Test Payloads */}
            <div className="flex gap-1.5 flex-wrap pt-1">
              <button
                onClick={() => handleTestSecurity('https://example.com/safe_video.mp4')}
                className="px-2 py-0.5 bg-emerald-950/60 text-emerald-400 border border-emerald-800/60 rounded text-[10px]"
              >
                Safe HTTPS Test
              </button>
              <button
                onClick={() => handleTestSecurity('file:///C:/Windows/System32/cmd.exe')}
                className="px-2 py-0.5 bg-rose-950/60 text-rose-400 border border-rose-800/60 rounded text-[10px]"
              >
                Attack 1: Local file://
              </button>
              <button
                onClick={() => handleTestSecurity('powershell.exe -ExecutionPolicy Bypass')}
                className="px-2 py-0.5 bg-rose-950/60 text-rose-400 border border-rose-800/60 rounded text-[10px]"
              >
                Attack 2: Shell command
              </button>
            </div>

            {securityResult && (
              <div className={`p-2 rounded text-[11px] font-mono mt-1 ${
                securityResult.includes('[BLOCKED') 
                  ? 'bg-rose-950/50 text-rose-300 border border-rose-800/60' 
                  : 'bg-emerald-950/50 text-emerald-300 border border-emerald-800/60'
              }`}>
                {securityResult}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
