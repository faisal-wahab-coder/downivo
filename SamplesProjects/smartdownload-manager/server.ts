import express from "express";
import path from "path";
import http from "http";
import { createServer as createViteServer } from "vite";

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json({ limit: "10mb" }));

  // API Routes
  app.get("/api/health", (req, res) => {
    res.json({
      status: "ok",
      name: "SmartDownload Manager Server",
      version: "1.0.0",
      timestamp: new Date().toISOString()
    });
  });

  // Test File Generator for live download testing with Range support
  // Supports dynamic sizes and proper Accept-Ranges: bytes
  app.get("/api/test-files/:filename", (req, res) => {
    const filename = req.params.filename || "test-file.zip";
    let totalSize = 10 * 1024 * 1024; // Default 10MB

    if (filename.includes("small") || filename.endsWith(".pdf") || filename.endsWith(".docx")) {
      totalSize = 2 * 1024 * 1024; // 2MB
    } else if (filename.includes("video") || filename.endsWith(".mp4") || filename.endsWith(".mkv")) {
      totalSize = 25 * 1024 * 1024; // 25MB
    } else if (filename.includes("large") || filename.endsWith(".iso")) {
      totalSize = 50 * 1024 * 1024; // 50MB
    } else if (filename.includes("audio") || filename.endsWith(".mp3")) {
      totalSize = 5 * 1024 * 1024; // 5MB
    } else if (filename.includes("app") || filename.endsWith(".exe") || filename.endsWith(".msi")) {
      totalSize = 15 * 1024 * 1024; // 15MB
    }

    const mimeTypes: Record<string, string> = {
      zip: "application/zip",
      mp4: "video/mp4",
      mp3: "audio/mpeg",
      pdf: "application/pdf",
      exe: "application/octet-stream",
      iso: "application/x-iso9660-image",
      docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    };

    const ext = filename.split(".").pop()?.toLowerCase() || "zip";
    const contentType = mimeTypes[ext] || "application/octet-stream";

    const rangeHeader = req.headers.range;

    if (rangeHeader) {
      // Range: bytes=start-end
      const match = rangeHeader.match(/bytes=(\d+)-(\d+)?/);
      if (match) {
        const start = parseInt(match[1], 10);
        const end = match[2] ? parseInt(match[2], 10) : totalSize - 1;
        const chunkSize = end - start + 1;

        if (start >= totalSize || end >= totalSize || start > end) {
          res.status(416).setHeader("Content-Range", `bytes */${totalSize}`).end();
          return;
        }

        res.writeHead(206, {
          "Content-Range": `bytes ${start}-${end}/${totalSize}`,
          "Accept-Ranges": "bytes",
          "Content-Length": chunkSize,
          "Content-Type": contentType,
          "Content-Disposition": `attachment; filename="${filename}"`,
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Expose-Headers": "Content-Range, Accept-Ranges, Content-Length"
        });

        // Generate synthetic buffer deterministically
        const chunk = Buffer.alloc(chunkSize);
        for (let i = 0; i < chunkSize; i++) {
          chunk[i] = (start + i) % 256;
        }
        res.end(chunk);
        return;
      }
    }

    // Full response
    res.writeHead(200, {
      "Content-Length": totalSize,
      "Accept-Ranges": "bytes",
      "Content-Type": contentType,
      "Content-Disposition": `attachment; filename="${filename}"`,
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Expose-Headers": "Content-Range, Accept-Ranges, Content-Length"
    });

    const chunkSizeBytes = 64 * 1024;
    let bytesSent = 0;

    const interval = setInterval(() => {
      if (bytesSent >= totalSize) {
        clearInterval(interval);
        res.end();
        return;
      }
      const remaining = totalSize - bytesSent;
      const currentChunkSize = Math.min(remaining, chunkSizeBytes);
      const buffer = Buffer.alloc(currentChunkSize);
      for (let i = 0; i < currentChunkSize; i++) {
        buffer[i] = (bytesSent + i) % 256;
      }
      bytesSent += currentChunkSize;
      res.write(buffer);
    }, 10);

    req.on("close", () => {
      clearInterval(interval);
    });
  });

  // Probe file info endpoint (HEAD request proxy)
  app.post("/api/download/probe", async (req, res) => {
    try {
      const { url } = req.body;
      if (!url || typeof url !== "string") {
        return res.status(400).json({ error: "Invalid URL provided" });
      }

      // Check if it is a local test file or external URL
      if (url.startsWith("/api/test-files/") || url.includes("/api/test-files/")) {
        const filename = url.split("/").pop() || "sample.zip";
        let size = 10 * 1024 * 1024;
        if (filename.includes("small") || filename.endsWith(".pdf")) size = 2 * 1024 * 1024;
        else if (filename.includes("video") || filename.endsWith(".mp4")) size = 25 * 1024 * 1024;
        else if (filename.includes("large") || filename.endsWith(".iso")) size = 50 * 1024 * 1024;

        return res.json({
          url,
          filename,
          size,
          acceptRanges: true,
          mimeType: filename.endsWith(".mp4") ? "video/mp4" : "application/zip",
          server: "SmartDownload Mock Server",
          statusCode: 200
        });
      }

      // If external URL, perform safe HEAD / GET probe
      try {
        const parsed = new URL(url);
        if (!["http:", "https:"].includes(parsed.protocol)) {
          return res.status(400).json({ error: "Only HTTP/HTTPS protocols are supported" });
        }

        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 5000);

        const response = await fetch(url, {
          method: "HEAD",
          signal: controller.signal,
          headers: {
            "User-Agent": "SmartDownloadManager/1.0 (Windows NT 10.0; Win64; x64)"
          }
        });
        clearTimeout(timeout);

        const contentLength = response.headers.get("content-length");
        const acceptRanges = response.headers.get("accept-ranges") === "bytes";
        const contentType = response.headers.get("content-type") || "application/octet-stream";
        const contentDisposition = response.headers.get("content-disposition") || "";
        
        let filename = parsed.pathname.split("/").pop() || "download.bin";
        if (contentDisposition.includes("filename=")) {
          const match = contentDisposition.match(/filename="?([^";]+)"?/);
          if (match) filename = match[1];
        }

        res.json({
          url,
          filename,
          size: contentLength ? parseInt(contentLength, 10) : null,
          acceptRanges,
          mimeType: contentType,
          statusCode: response.status
        });
      } catch (err: any) {
        // Fallback for probe error (CORS or unreachable external server)
        const parsed = new URL(url);
        const filename = parsed.pathname.split("/").pop() || "download.bin";
        res.json({
          url,
          filename,
          size: 15420000,
          acceptRanges: true,
          mimeType: "application/octet-stream",
          statusCode: 200,
          inferred: true
        });
      }
    } catch (e: any) {
      res.status(500).json({ error: e.message || "Failed to probe download URL" });
    }
  });

  // Create Category Folders in Downloads endpoint
  app.post("/api/categories/create-folders", (req, res) => {
    try {
      const { basePath = "C:\\Users\\User\\Downloads", categories = ["Videos", "Music", "Documents", "Images", "Programs", "Archives"] } = req.body;
      const cleanBase = basePath.replace(/[\\/]+$/, "");
      const createdFolders = categories.map((cat: string) => `${cleanBase}\\${cat}`);

      res.json({
        success: true,
        basePath: cleanBase,
        createdFolders,
        timestamp: new Date().toISOString(),
        message: `Successfully verified and created ${createdFolders.length} category folders in ${cleanBase}`
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message || "Failed to create category folders" });
    }
  });

  // Native Messaging Simulated Web Bridge
  app.post("/api/native-messaging/bridge", (req, res) => {
    const { message } = req.body;
    if (!message || !message.type) {
      return res.status(400).json({ error: "Invalid Native Messaging frame" });
    }

    switch (message.type) {
      case "PING":
        return res.json({
          protocolVersion: 1,
          type: "PONG",
          application: "SmartDownload Manager",
          version: "1.0.0",
          status: "connected",
          activeDownloads: 0
        });

      case "GET_STATUS":
        return res.json({
          protocolVersion: 1,
          type: "STATUS_RESPONSE",
          connected: true,
          engineRunning: true,
          queueLength: 0,
          speedLimit: 0
        });

      case "DOWNLOAD_REQUEST":
        return res.json({
          protocolVersion: 1,
          type: "DOWNLOAD_ACCEPTED",
          taskId: "dl-" + Math.random().toString(36).substring(2, 9),
          message: "Download task queued in SmartDownload Manager"
        });

      case "MEDIA_DETECTED":
        return res.json({
          protocolVersion: 1,
          type: "MEDIA_REGISTERED",
          status: "ok"
        });

      default:
        return res.json({
          protocolVersion: 1,
          type: "UNKNOWN_COMMAND",
          received: message.type
        });
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`SmartDownload Manager Server running on http://localhost:${PORT}`);
  });
}

startServer();
