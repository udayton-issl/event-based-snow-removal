from __future__ import annotations
from dataclasses import dataclass
import os
from typing import List, NamedTuple, Optional, Tuple

import csv
import cv2

###############################################################################
# Data paths, replace with corresponding paths on your system
DETECTIONS_SNOW_CSV: str = ""       # Detections w/ snow CSV filepath
DETECTIONS_NOSNOW_CSV: str = ""     # Detections w/o snow CSV filepath
BOUNDING_BOX_LABELS_CSV: str = ""   # Labels CSV filepath
IMAGE_DIR: str = ""                 # Video frames directory path
SAVE_DIR: str = ""                  # Annotated frames save directory path
###############################################################################

###############################################################################
# Settings, replace desired values
LABEL_WINDOW: int = 0               # Labels time window (+/- value)
DETECTION_WINDOW: int = 50000       # Detections time window (+/- value)
###############################################################################

@dataclass(init=False, frozen=True)
class BoxColors:
    BLUE: Tuple[float, float, float] = (255.0, 0.0, 0.0)
    GREEN: Tuple[float, float, float] = (0.0, 255.0, 0.0)
    RED: Tuple[float, float, float] = (0.0, 0.0, 255.0)

class BoundingBox(NamedTuple):
    timestamp: int
    xcoord: int
    ycoord: int
    width: int
    height: int

    @staticmethod
    def from_csv_data(data: List[str], is_label: bool) -> BoundingBox:
        if is_label:
            return BoundingBox(
                timestamp=round(float(data[0])),
                xcoord=max(0, round(float(data[1]))),
                ycoord=max(0, round(float(data[2]))),
                width=round(float(data[3])),
                height=round(float(data[4]))
            )
        return BoundingBox(
            timestamp=round(float(data[0])),
            xcoord=max(0, round(float(data[3]))),
            ycoord=max(0, round(float(data[4]))),
            width=round(float(data[5])),
            height=round(float(data[6]))
        )

def read_csvfile(csvpath: str, is_label: bool = False) -> List[BoundingBox]:
    data = []
    with open(csvpath, "r") as csvfile:
        reader = csv.reader(csvfile, delimiter=" ")
        for row in reader:
            data.append(BoundingBox.from_csv_data(row, is_label))
    return data

def get_image_filename(imgs: List[str], timestamp: int, win: int) -> Optional[str]:
    segment_lower = f"_{timestamp - win}"
    segment_upper = f"_{timestamp + win}"
    for img in imgs:
        if segment_lower in img or segment_upper in img:
            return img
    return None

def draw_boxes(
    boxes: List[BoundingBox],
    imgdir: str,
    savedir: str,
    window: int,
    color: Tuple[float, float, float]
) -> None:
    imglist = os.listdir(imgdir)
    for box in boxes:
        imgfile = get_image_filename(imglist, box.timestamp, window)
        if imgfile is None:
            continue
        imgpath = os.path.join(imgdir, imgfile)
        savepath = os.path.join(savedir, imgfile)
        if os.path.isfile(savepath):
            imgpath = savepath
        img = cv2.imread(imgpath)
        if img is not None:
            pt1 = (box.xcoord, box.ycoord)
            pt2 = (box.xcoord + box.width, box.ycoord + box.height)
            cv2.rectangle(img, pt1, pt2, color, thickness=2)
            cv2.imwrite(savepath, img)

def main() -> None:
    detections_snow = read_csvfile(DETECTIONS_SNOW_CSV)
    detections_nosnow = read_csvfile(DETECTIONS_NOSNOW_CSV)
    labels = read_csvfile(BOUNDING_BOX_LABELS_CSV, is_label=True)

    draw_boxes(labels, IMAGE_DIR, SAVE_DIR, LABEL_WINDOW, BoxColors.BLUE)
    draw_boxes(detections_snow, IMAGE_DIR, SAVE_DIR, DETECTION_WINDOW, BoxColors.GREEN)
    draw_boxes(detections_nosnow, IMAGE_DIR, SAVE_DIR, DETECTION_WINDOW, BoxColors.RED)

if __name__ == "__main__":
    main()
