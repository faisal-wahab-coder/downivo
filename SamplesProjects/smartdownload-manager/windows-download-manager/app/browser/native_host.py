"""
SmartDownload Manager - Native Messaging Host
Interprets standard 32-bit binary length-prefixed JSON from Chrome/Edge Extension
Strict security: rejects arbitrary shell commands and validates URL schemas
"""
import sys
import json
import struct
import logging
from urllib.parse import urlparse

# Set binary mode for standard I/O on Windows
if sys.platform == "win32":
    import msvcrt
    msvcrt.setmode(sys.stdin.fileno(), os.O_BINARY)
    msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)

logging.basicConfig(filename="native_host.log", level=logging.INFO)

def read_message():
    raw_length = sys.stdin.buffer.read(4)
    if len(raw_length) == 0:
        return None
    message_length = struct.unpack('@I', raw_length)[0]
    message_bytes = sys.stdin.buffer.read(message_length)
    return json.loads(message_bytes.decode('utf-8'))

def send_message(message_dict):
    encoded = json.dumps(message_dict).encode('utf-8')
    sys.stdout.buffer.write(struct.pack('@I', len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()

def validate_url(url: str) -> bool:
    """Security check: Only allow http and https schemas."""
    try:
        parsed = urlparse(url)
        return parsed.scheme in ('http', 'https')
    except Exception:
        return False

def handle_message(msg):
    msg_type = msg.get('type')
    
    if msg_type == 'PING':
        send_message({
            'protocolVersion': 1,
            'type': 'PONG',
            'application': 'SmartDownload Manager',
            'version': '1.0.0',
            'status': 'ready'
        })
    elif msg_type == 'DOWNLOAD_REQUEST':
        url = msg.get('url', '')
        if not validate_url(url):
            send_message({
                'protocolVersion': 1,
                'type': 'DOWNLOAD_REJECTED',
                'error': 'Invalid or forbidden URL protocol'
            })
            return
        
        # Send forward to local IPC / named pipe to desktop window
        send_message({
            'protocolVersion': 1,
            'type': 'DOWNLOAD_ACCEPTED',
            'taskId': 'win-' + str(int(time.time()))
        })
    elif msg_type == 'MEDIA_DETECTED':
        logging.info("Media sniffer resource detected: %s", msg.get('data'))
        send_message({'protocolVersion': 1, 'type': 'MEDIA_REGISTERED', 'status': 'ok'})
    else:
        send_message({'protocolVersion': 1, 'type': 'UNKNOWN_REQUEST'})

def main():
    while True:
        try:
            msg = read_message()
            if msg is None:
                break
            handle_message(msg)
        except Exception as e:
            logging.error("Native host exception: %s", str(e))
            break

if __name__ == '__main__':
    main()
