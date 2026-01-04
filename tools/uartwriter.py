import serial
import time
import sys
import os
import argparse

# Constants
TARGET_WORD_COUNT = 8100 

def parse_mem_file(filename):
    """Parses .mem file, crops/pads to 8100 words, returns bytearray."""
    raw_values = [] 
    byte_data = bytearray()
    
    print(f"Reading file: {filename}...")
    
    try:
        with open(filename, 'r') as f:
            content = f.read()
            
        tokens = []
        for line in content.splitlines():
            # Cleanup comments
            line = line.split('//')[0].split('--')[0].strip()
            if not line or line.startswith('@'):
                continue
            tokens.extend(line.split())
            
        # 1. Parse string to int (13-bit mask)
        for token in tokens:
            try:
                val = int(token, 2) & 0x1FFF
                raw_values.append(val)
            except ValueError:
                print(f"Warning: Skipping invalid token '{token}'")

        current_count = len(raw_values)
        print(f"Words found: {current_count}")

        # 2. Limit to target size (Crop or Pad)
        if current_count > TARGET_WORD_COUNT:
            print(f"--> Cropping to {TARGET_WORD_COUNT}...")
            raw_values = raw_values[:TARGET_WORD_COUNT]
            
        elif current_count < TARGET_WORD_COUNT:
            diff = TARGET_WORD_COUNT - current_count
            print(f"--> Padding with {diff} zeros...")
            raw_values.extend([0] * diff)
        else:
            print("--> Size matches.")

        # 3. Pack to 16-bit (Big Endian)
        for val in raw_values:
            byte_data.append((val >> 8) & 0xFF) # High
            byte_data.append(val & 0xFF)        # Low

        print(f"Payload ready: {len(byte_data)} bytes.")
        return byte_data

    except FileNotFoundError:
        print(f"ERROR: '{filename}' not found.")
        sys.exit(1)

def send_uart(serial_port, baud_rate, data):
    total_bytes = len(data)
    sent_bytes = 0
    chunk_size = 2048
    
    print(f"Opening {serial_port} @ {baud_rate}...")
    
    try:
        with serial.Serial(serial_port, baud_rate, timeout=1, stopbits=serial.STOPBITS_ONE) as ser:
            time.sleep(0.5) 
            start_time = time.time()
            
            for i in range(0, total_bytes, chunk_size):
                chunk = data[i : i + chunk_size]
                ser.write(chunk)
                ser.flush() 
                
                sent_bytes += len(chunk)
                progress = (sent_bytes / total_bytes) * 100
                sys.stdout.write(f"\rSending: [{progress:.1f}%] - {sent_bytes}/{total_bytes} bytes")
                sys.stdout.flush()
                
            duration = time.time() - start_time
            print(f"\nDone! Sent in {duration:.2f}s.")
            
    except Exception as e:
        print(f"\nError: {e}")
    except KeyboardInterrupt:
        print("\nCancelled.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="FPGA Mem Loader")
    parser.add_argument('-f', '--file', required=True, type=str, help="Input .mem file")
    parser.add_argument('-p', '--port', default='COM9', type=str, help="Serial Port")
    parser.add_argument('-b', '--baud', default=115200, type=int, help="Baud Rate")

    args = parser.parse_args()

    if not os.path.exists(args.file):
        print(f"ERROR: '{args.file}' not found.")
        sys.exit(1)
    
    # Prepare data
    binary_data = parse_mem_file(args.file)
    
    if len(binary_data) > 0:
        # Input removed, sending immediately
        send_uart(args.port, args.baud, binary_data)