import argparse
import random
import os
import sys

def process_mem_file(filepath):
    # Check if file exists
    if not os.path.exists(filepath):
        print(f"Error: The file '{filepath}' was not found.")
        sys.exit(1)

    print(f"Reading file: {filepath}...")
    
    processed_lines = []
    changes_count = 0

    try:
        # Read the entire file content
        with open(filepath, 'r') as file:
            lines = file.readlines()

        # Process each line
        for line in lines:
            clean_line = line.strip()
            
            # Check for standard 13-bit format
            if len(clean_line) == 13:
                prefix = clean_line[0:3]      # Fixed bits (000)
                rgb = clean_line[3:6]         # RGB bits
                ascii_part = clean_line[6:13] # ASCII bits
                
                # Logic: If RGB is '111', randomize it (excluding 000)
                # This applies to ALL characters (numbers included)
                if rgb == "111":
                    # Generate random integer between 1 and 7 (binary 001 to 111)
                    random_val = random.randint(1, 7)
                    new_rgb = bin(random_val)[2:].zfill(3)
                    
                    new_line = prefix + new_rgb + ascii_part
                    processed_lines.append(new_line)
                    changes_count += 1
                else:
                    processed_lines.append(clean_line)
            else:
                # Preserve empty lines or lines with different lengths
                processed_lines.append(clean_line)

        # Overwrite the original file
        with open(filepath, 'w') as file:
            for line in processed_lines:
                file.write(line + '\n')

        print(f"Success! Overwrote '{filepath}'.")
        print(f"Total lines modified: {changes_count}")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    # Initialize argument parser
    parser = argparse.ArgumentParser(description="Randomize RGB bits (111) in a 13-bit memory file.")
    
    # Add the -f argument
    parser.add_argument("-f", "--file", required=True, help="Path to the .mem file to process")

    # Parse arguments
    args = parser.parse_args()

    # Run the function
    process_mem_file(args.file)