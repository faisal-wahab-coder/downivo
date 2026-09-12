import React, { useEffect, useRef } from 'react';
import { formatSpeed } from '../services/downloadEngine';
import { Activity } from 'lucide-react';

interface SpeedGraphProps {
  currentSpeed: number; // Bytes per second
  speedLimitBytesPerSec?: number;
  historyPoints?: number[];
}

export const SpeedGraph: React.FC<SpeedGraphProps> = ({
  currentSpeed,
  speedLimitBytesPerSec = 0,
  historyPoints = [],
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const speedHistoryRef = useRef<number[]>(new Array(40).fill(0));

  useEffect(() => {
    // Append current speed to rolling history
    speedHistoryRef.current.push(currentSpeed);
    if (speedHistoryRef.current.length > 50) {
      speedHistoryRef.current.shift();
    }

    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const width = canvas.width;
    const height = canvas.height;

    // Clear
    ctx.clearRect(0, 0, width, height);

    const history = speedHistoryRef.current;
    const maxVal = Math.max(...history, speedLimitBytesPerSec || 0, 1024 * 1024); // Minimum scale 1 MB/s

    // Draw Grid Lines
    ctx.strokeStyle = '#27272a';
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let y = 0; y <= height; y += height / 3) {
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
    }
    ctx.stroke();

    // Draw Speed Limit Line if active
    if (speedLimitBytesPerSec > 0) {
      const limitY = height - (speedLimitBytesPerSec / maxVal) * (height - 10) - 5;
      ctx.strokeStyle = 'rgba(245, 158, 11, 0.6)';
      ctx.setLineDash([4, 4]);
      ctx.beginPath();
      ctx.moveTo(0, limitY);
      ctx.lineTo(width, limitY);
      ctx.stroke();
      ctx.setLineDash([]);
    }

    // Draw Gradient Area Under Graph
    const gradient = ctx.createLinearGradient(0, 0, 0, height);
    gradient.addColorStop(0, 'rgba(2, 132, 199, 0.4)');
    gradient.addColorStop(1, 'rgba(2, 132, 199, 0.0)');

    ctx.beginPath();
    const step = width / (history.length - 1);

    history.forEach((val, i) => {
      const x = i * step;
      const y = height - (val / maxVal) * (height - 12) - 4;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });

    ctx.lineTo(width, height);
    ctx.lineTo(0, height);
    ctx.closePath();
    ctx.fillStyle = gradient;
    ctx.fill();

    // Draw Line
    ctx.beginPath();
    ctx.strokeStyle = '#38bdf8';
    ctx.lineWidth = 2;
    history.forEach((val, i) => {
      const x = i * step;
      const y = height - (val / maxVal) * (height - 12) - 4;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();
  }, [currentSpeed, speedLimitBytesPerSec]);

  // Handle Canvas Resize
  useEffect(() => {
    const handleResize = () => {
      if (containerRef.current && canvasRef.current) {
        canvasRef.current.width = containerRef.current.clientWidth;
        canvasRef.current.height = containerRef.current.clientHeight;
      }
    };
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return (
    <div 
      ref={containerRef} 
      id="speed-graph-container"
      className="relative w-full h-16 bg-[#161618] border-t border-[#27272a] overflow-hidden"
    >
      <canvas ref={canvasRef} className="w-full h-full block" />
      <div className="absolute top-1.5 left-2 flex items-center gap-1.5 text-[10px] text-zinc-400 bg-zinc-900/80 px-1.5 py-0.5 rounded border border-zinc-800">
        <Activity className="w-3 h-3 text-sky-400" />
        <span>Throughput: <strong className="text-sky-400 font-semibold">{formatSpeed(currentSpeed)}</strong></span>
        {speedLimitBytesPerSec > 0 && (
          <span className="text-amber-400 font-medium ml-1">
            (Limit: {formatSpeed(speedLimitBytesPerSec)})
          </span>
        )}
      </div>
    </div>
  );
};
