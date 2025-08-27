import csv
from enum import Enum
import os
from typing import Any, NamedTuple, Tuple
import numpy as np
from numpy.typing import NDArray
import torch
from metavision_sdk_ml import EventBbox
from metavision.core.event_io import EventsIterator
from metavision_ml.detection_tracking import ObjectDetector

MODELS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Models")
RED_EVENT_CUBE_PATH = os.path.join(MODELS_DIR, "red_event_cube_05_2020")
RED_HISTOGRAM_PATH = os.path.join(MODELS_DIR, "red_histogram_05_2020")

class CameraDims(NamedTuple):
    width: int
    height: int

class FilterWindows(NamedTuple):
    time_win: int
    spatial_win: int

class CNNType(Enum):
    RED_EVENT_CUBE = RED_EVENT_CUBE_PATH
    RED_HISTOGRAM = RED_HISTOGRAM_PATH

###############################################################################
# Data paths, replace with corresponding paths on your system
EVENTS_FILEPATH = ""                # Raw events filepath
OUTPUT_CSVPATH = ""                 # Results CSV filepath
###############################################################################

###############################################################################
# Settings, replace desired values
CAMERA_DIM_X = 1280                 # Camera resolution width
CAMERA_DIM_Y = 720                  # Camera resolution height
DELTA_T = 10000                     # Timestamp delta per iteration
EBSNOR_SPATIAL_WINDOW = 0           # EBSnoR filter spatial window
EBSNOR_TIME_WINDOW = 10000          # EBSnoR filter time window
CNN_MODEL = CNNType.RED_EVENT_CUBE  # CNN model
USE_ADAPTIVE_WIN = False            # Enable/Disable EBSnoR adaptive window
###############################################################################


class DetectionCNN:
    DOWNSCALE_FACTOR = 2
    DETECTOR_SCORE_THRESHOLD = 0.4
    IOU_THRESHOLD = 0.4
    def __init__(self, dimensions: CameraDims, model: CNNType, output_csv: str) -> None:
        detector = ObjectDetector(
            model.value,
            events_input_width=dimensions.width,
            events_input_height=dimensions.height,
            runtime="cuda" if torch.cuda.is_available() else "cpu",
            network_input_width=torch.div(
                dimensions.height,
                self.DOWNSCALE_FACTOR,
                rounding_mode="floor"
            ),
            network_input_height=torch.div(
                dimensions.height,
                self.DOWNSCALE_FACTOR,
                rounding_mode="floor"
            )
        )
        detector.set_detection_threshold(self.DETECTOR_SCORE_THRESHOLD)
        detector.set_iou_threshold(self.IOU_THRESHOLD)
        cd_processor = detector.get_cd_processor()
        frame_buffer = cd_processor.init_output_tensor()
        accumulation_time = detector.get_accumulation_time()
        csvfile = open(output_csv, "w", newline="")
        csvwriter = csv.writer(csvfile, delimiter=" ")


        self.accumulation_time = accumulation_time
        self.cd_processor = cd_processor
        self.detector = detector
        self.frame_buffer = frame_buffer
        self.csvfile = csvfile
        self.csvwriter = csvwriter

    def run(self, events: Any, timestamp: Any) -> None:
        start_ts = torch.div(timestamp - 1, self.accumulation_time, rounding_mode="floor")
        start_ts *= self.accumulation_time
        self.cd_processor.process_events(start_ts, events, self.frame_buffer)
        detections = np.empty(0, dtype=EventBbox)

        if timestamp % self.accumulation_time == 0:
            detections = self.detector.process(timestamp, self.frame_buffer)
            self.frame_buffer.fill(0)

        for detection in detections:
            self._write_row_to_csv(detection)

    def _write_row_to_csv(self, detection: Any) -> None:
        timestamp = detection[0]
        xcoord = detection[1]
        ycoord = detection[2]
        width = detection[3]
        height = detection[4]
        class_id = detection[5]
        track_id = detection[6]
        confidence = detection[7]

        row = (timestamp, class_id, track_id, xcoord, ycoord, width, height, confidence)
        self.csvwriter.writerow(row)

class EBSnoRFilter:
    def __init__(self, dimensions: CameraDims, windows: FilterWindows) -> None:
        self.time_window = windows.time_win
        self.spatial_window = windows.spatial_win
        self.cam_x = dimensions.width
        self.cam_y = dimensions.height

    def ie_filter(
        self,
        events: Any,
        time_window: int = 10000,
        te_depth: int = 10
    ) -> Tuple[NDArray[np.bool], NDArray[np.uint64]]:
        datalen = len(events["t"])
        ie_idx = np.zeros((self.cam_x, self.cam_y), dtype=int)
        prev_ts = np.zeros((self.cam_x, self.cam_y), dtype=int)
        prev_p = np.zeros((self.cam_x, self.cam_y), dtype=int)

        is_ie = np.zeros(datalen, dtype=bool)
        te_data = -1*np.ones((datalen, te_depth), dtype=int)
        te_idx = np.zeros(datalen, dtype=int)

        iter_ev = zip(events["x"], events["y"], events["p"], events["t"])
        for idx, (xval, yval, pval, tval) in enumerate(iter_ev):
            if pval != prev_p[xval][yval] or tval - prev_ts[xval][yval] > time_window:
                is_ie[idx] = True
                ie_idx[xval][yval] = idx
            else:
                if te_idx[ie_idx[xval][yval]] > te_depth:
                    continue
                te_data[ie_idx[xval][yval]][te_idx[xval][yval]] = idx
                te_idx[ie_idx[xval][yval]] += 1
            prev_ts[xval][yval] = tval
            prev_p[xval][yval] = pval

        return is_ie, te_data

    def ebsnor_filter(
        self,
        events: Any,
        is_ie: NDArray[np.bool],
        te_data: NDArray[np.uint64],
        adaptive_window: bool = False
    ) -> NDArray[np.bool]:
        datalen = len(events["t"])
        events["x"] += self.spatial_window
        events["y"] += self.spatial_window
        pos_ts = -np.inf * np.ones(
            (self.cam_x + 2 * self.spatial_window, self.cam_y + 2 * self.spatial_window),
            dtype=int
        )
        pos_idx = np.zeros(
            (self.cam_x + 2 * self.spatial_window, self.cam_y + 2 * self.spatial_window),
            dtype=int
        )
        win = np.arange(-self.spatial_window, self.spatial_window + 1, dtype=int)
        is_snow = np.zeros(datalen, dtype=bool)

        iter_ev = zip(events["x"], events["y"], events["p"], events["t"])
        for idx, (xval, yval, pval, tval) in enumerate(iter_ev):
            if is_ie[idx] and pval < 0:
                in_range = False
                if adaptive_window:
                    in_range = tval - pos_ts[xval][yval] < self.time_window
                    positions = pos_idx[xval][yval]
                if not in_range:
                    in_range = np.less(tval - pos_ts[xval + win][yval + win], self.time_window)
                    positions = pos_idx[xval + win][yval + win]
                if in_range.any():
                    is_snow[idx] = True
                    te_idx = te_data[idx]
                    is_snow[te_idx[te_idx > -1]] = True
                    is_snow[positions[in_range]] = True # type: ignore
                    te_idx = te_data[positions[in_range]] # type: ignore
                    is_snow[te_idx[te_idx > 0]] = True
            elif is_ie[idx]:
                pos_idx[xval][yval] = idx
                pos_ts[xval][yval] = idx

        return is_snow

    def process(self, events: Any, adaptive_window: bool = False) -> Any:
        is_ie, te_data = self.ie_filter(events)
        is_snow = self.ebsnor_filter(events, is_ie, te_data, adaptive_window)

        new_length = len(events["t"]) - np.count_nonzero(is_snow)
        new_x = events["x"][np.logical_not(is_snow)]
        new_y = events["y"][np.logical_not(is_snow)]
        new_t = events["t"][np.logical_not(is_snow)]
        new_p = events["p"][np.logical_not(is_snow)]

        events = np.resize(events, new_length)
        events["x"] = new_x
        events["y"] = new_y
        events["t"] = new_t
        events["p"] = new_p

        return events


def main() -> None:
    camera_dimensions = CameraDims(CAMERA_DIM_X, CAMERA_DIM_Y)
    filter_windows = FilterWindows(EBSNOR_TIME_WINDOW, EBSNOR_SPATIAL_WINDOW)
    preprocessor = EBSnoRFilter(camera_dimensions, filter_windows)
    cnn = DetectionCNN(camera_dimensions, CNN_MODEL, OUTPUT_CSVPATH)
    iter_evts = EventsIterator(
        EVENTS_FILEPATH,
        start_ts=0,
        delta_t=DELTA_T,
        relative_timestamps=False
    )

    idx = 0
    for evts in iter_evts:
        timestamp = iter_evts.get_current_time()
        processed = preprocessor.process(evts, USE_ADAPTIVE_WIN)
        cnn.run(processed, timestamp)
        print(f"Iteration{idx} done. Timestamp={timestamp - DELTA_T}")
        idx += 1

if __name__ == "__main__":
    main()
