import math
import subprocess

def generate(path, r, f):
    rw, rh = map(int, r.split('x'))
    fw, fh = map(int, f.split('x'))
    w = math.floor(rw / fw)
    h = math.floor(rh / fh)

    with open(path, "w") as output_file:
        i = 0
        for _ in range(0, h):
            for _ in range(0, w):
                output_file.write(chr((i % 95) + 32))
                i = i + 1
            output_file.write("\n")

if __name__ == "__main__":
    SUPPORTED_RES = ["640x480", "800x600", "1600x900", "1920x1080"]
    SUPPORTED_FON = ["16x16", "32x32", "64x64"]

    for r in SUPPORTED_RES:
        for f in SUPPORTED_FON:
            path = f"charmem_{r}_{f}.txt"
            generate(path, r, f)

            args = ["-i", path, "-o", path.replace(".txt", ".mem"), "--random"]
            subprocess.run(["python", "text2mem.py"] + args)