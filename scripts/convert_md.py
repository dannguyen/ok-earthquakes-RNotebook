# run like this:
#   python3 scripts/convert_md.py
# expects md/ to exist

from glob import glob
from re import findall
from os import makedirs
from os.path import join, basename, realpath, expanduser
from shutil import copyfile

FINAL_PATH = realpath(expanduser("~/blogme"))
REL_FINAL_IMAGE_PATH = "./files/images/posts/ok-earthquakes"
FINAL_IMAGE_PATH = join(FINAL_PATH, REL_FINAL_IMAGE_PATH)
PRODUCTION_IMAGE_PATH = REL_FINAL_IMAGE_PATH[1:]
makedirs(FINAL_IMAGE_PATH, exist_ok = True)

FINAL_MD_PATH = join(FINAL_PATH, '_posts', '2015-09-01-oklahoma-earthquakes-r-ggplot2.md')


PROJECTS = ['chapter-2-basic-r-concepts']

base_dir = realpath('.')
for project_name in PROJECTS:
    print("Converting", project_name)
    md_path = join(base_dir, 'build_md', project_name + '.md')
    fig_path = join(base_dir, 'build_md', project_name + '_files', 'figure-markdown_github')
    # open the markdown file
    with open(md_path) as f:
        mdtext = f.read()
    # replace image paths
    final_mdtext = mdtext.replace(fig_path, PRODUCTION_IMAGE_PATH).replace(
            "``` r", "```R"
        ).replace("```", "~~~").replace(
            "./images", PRODUCTION_IMAGE_PATH
        )

    # write new file
    with open(FINAL_MD_PATH, 'w') as f:
        f.write(final_mdtext)
    # copy over images
    for figname in glob(join(fig_path, '*.png')):
        dest_figname = join(FINAL_IMAGE_PATH, basename(figname))
        copyfile(figname, dest_figname)
    # copy over static images
    for img in glob(join("./images", '*.*')):
        dest_imgname = join(FINAL_IMAGE_PATH, basename(img))
        copyfile(img, dest_imgname)

