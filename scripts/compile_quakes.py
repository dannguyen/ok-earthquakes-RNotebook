from glob import glob
from os.path import join
DUMP_DIR = "/tmp/usgs-quakes/"
OUTPUT_NAME = join(DUMP_DIR, '..',  "usgs-quakes-dump.csv")

files = glob(join(DUMP_DIR, '*.csv'))
with open(OUTPUT_NAME, 'w') as o:
    # write headers from the first file
    o.write(open(files[0]).readline())
    # then write the rest of the files, skipping the first line of each
    for fname in files:
        with open(fname) as f:
            print(fname)
            f.readline() # skip first line
            o.write(f.read())
