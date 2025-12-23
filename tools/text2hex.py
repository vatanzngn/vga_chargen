import argparse
import random

# 3-bit RGB
c_bg = "000"
c_fg = "110"

def convert(c):
    return f"{c_bg}{c_fg}{ord(c):07b}\n"

def generate(input_path, output_path, color):
    try:
        with open(input_path, "r") as input_file:
            with open(output_path, "w") as output_file:
                for il in input_file:
                    for c in il:
                        output_file.write(f"{color}{ord(c):07b}\n")
    except FileNotFoundError as e:
        print(e)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog='text2mem')
    parser.add_argument('-i', required=True, help='Input File')
    parser.add_argument('-o', default='charmem.mem', help='Output File (.mem)')
    parser.add_argument('-c', default='000111', help='Defined color value bg(3) font(3)')
    parser.add_argument('--random', action='store_true', help='Random value for colors')

    args = parser.parse_args()

    if args.random:
        args.c = "".join(random.choice("01") for _ in range(6))        

    generate(args.i, args.o, args.c)