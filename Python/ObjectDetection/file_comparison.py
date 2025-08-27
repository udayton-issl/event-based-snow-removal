from __future__ import annotations
import csv
from typing import List, NamedTuple, Tuple

###############################################################################
# Data paths, replace with corresponding paths on your system
DETECTIONS_SNOW_CSV = ""            # Detections w/ snow CSV filepath
DETECTIONS_NOSNOW_CSV = ""          # Detections w/o snow CSV filepath
BOUNDING_BOX_LABELS_CSV = ""        # Labels CSV filepath
OUTPUT_FILE = ""                    # Save file path
###############################################################################

###############################################################################
# Settings, replace desired values
MATCH_VALUE = 0                     # IOU threshold for valid detections
FRAMES = 20                         # Maximum number of frames to analyze
TIME_PER_FRAME = 50000              # Frame duration in uS
SECONDS_IN_VIDEO = 153              # Total number of sequence in video
###############################################################################

class AnalysisResults:
    def __init__(self, num_labels: int) -> None:
        self.num_labels: int = num_labels
        self.true_positive: int = 0
        self.false_positive: int = 0
        self.running_percent_overlap: float = 0
        self.running_iou: float = 0

    def percent_overlap(self) -> float:
        return self.running_percent_overlap / (self.true_positive + self.false_positive)

    def intersection_over_union(self) -> float:
        return self.running_iou / (self.true_positive + self.false_positive)

    def precision(self) -> float:
        return self.true_positive / (self.true_positive + self.false_positive)

    def recall(self) -> float:
        return self.true_positive / self.num_labels

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

def calculate_intersection(box1: BoundingBox, box2: BoundingBox) -> int:
    val_x0 = max(box1.xcoord, box2.xcoord)
    val_x1 = min(box1.xcoord + box1.width, box2.xcoord + box2.width)
    val_y0 = max(box1.ycoord, box2.ycoord)
    val_y1 = min(box1.ycoord + box1.height, box2.ycoord + box2.height)

    return max(0, val_x1 - val_x0) * max(0, val_y1 - val_y0)

def calculate_union(box1: BoundingBox, box2: BoundingBox, intersection: int) -> int:
    box1_area = box1.width * box1.height
    box2_area = box2.width * box2.height

    return (box1_area + box2_area) - intersection

def calculate_metrics(detection: BoundingBox, label: BoundingBox) -> Tuple[float, float]:
    intersection = calculate_intersection(detection, label)
    union = calculate_union(detection, label, intersection)

    percent_overlap = intersection / (label.width * label.height)
    intersection_over_union = intersection / union

    return percent_overlap, intersection_over_union

def analyze_frame_set(
    frame_window: int,
    detections: List[BoundingBox],
    labels: List[BoundingBox],
    total_seconds: int,
    threshold: int
) -> AnalysisResults:
    results = AnalysisResults(len(labels))
    for second in range(total_seconds + 1):
        lims = ((second * 1e6) - frame_window, (second * 1e6) + frame_window)
        frame_detections = [x for x in detections if lims[0] <= x.timestamp < lims[1]]
        frame_labels = [x for x in labels if lims[0] <= x.timestamp < lims[1]]
        matched = [False for _ in labels]
        for detection in frame_detections:
            valid = False
            for idx, label in enumerate(frame_labels):
                percent_overlap, iou = calculate_metrics(detection, label)
                if iou > threshold:
                    valid = True
                    if not matched[idx]:
                        matched[idx] = True
                        results.true_positive += 1
                        results.running_percent_overlap += percent_overlap
                        results.running_iou += iou
                    break
            if not valid:
                results.false_positive += 1

    return results

def write_results(
    filename: str,
    num_frames: int,
    results_snow: AnalysisResults,
    results_nosnow: AnalysisResults
) -> None:
    text = [
        f"----------{num_frames}----------",
        "NO SNOW",
        f"    Avg Percent Overlap: {results_nosnow.percent_overlap() * 100}%",
        f"    Avg IOU: {results_nosnow.intersection_over_union() * 100}%",
        f"    Precision: {results_nosnow.precision()}",
        f"    Recall: {results_nosnow.recall()}",
        f"    Cars Found: {results_nosnow.true_positive}/{results_nosnow.num_labels}",
        f"    False Positives: {results_nosnow.false_positive}",
        "",
        "SNOW",
        f"    Avg Percent Overlap: {results_snow.percent_overlap() * 100}%",
        f"    Avg IOU: {results_snow.intersection_over_union() * 100}%",
        f"    Precision: {results_snow.precision()}",
        f"    Recall: {results_snow.recall()}",
        f"    Cars Found: {results_snow.true_positive}/{results_snow.num_labels}",
        f"    False Positives: {results_snow.false_positive}",
        "\n",
    ]
    with open(filename, "a", encoding="utf-8") as results_file:
        results_file.write("\n".join(text))

def main() -> None:
    detections_snow = read_csvfile(DETECTIONS_SNOW_CSV)
    detections_nosnow = read_csvfile(DETECTIONS_NOSNOW_CSV)
    labels = read_csvfile(BOUNDING_BOX_LABELS_CSV, is_label=True)
    for num_frames in range(1, FRAMES + 1):
        results_snow = analyze_frame_set(
            num_frames * TIME_PER_FRAME,
            detections_snow,
            labels,
            SECONDS_IN_VIDEO,
            MATCH_VALUE
        )
        results_nosnow = analyze_frame_set(
            num_frames * TIME_PER_FRAME,
            detections_nosnow,
            labels,
            SECONDS_IN_VIDEO,
            MATCH_VALUE
        )
        write_results(OUTPUT_FILE, num_frames, results_snow, results_nosnow)

if __name__ == "__main__":
    main()
