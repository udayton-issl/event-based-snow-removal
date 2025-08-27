from typing import Any, NamedTuple, Tuple
import numpy as np
from numpy.typing import NDArray
from metavision_sdk_core import OnDemandFrameGenerationAlgorithm
from metavision_sdk_ui import (
    BaseWindow,
    Window,
    UIAction,
    UIKeyEvent
)
from metavision_core.event_io import EventsIterator

###############################################################################
# Data paths, replace with corresponding paths on your system
EVENTS_FILEPATH = ""                # Raw events filepath
###############################################################################

###############################################################################
# Settings, replace desired values
CAMERA_DIM_X = 1280                 # Camera resolution width
CAMERA_DIM_Y = 720                  # Camera resolution height
DELTA_T = 10000                     # Timestamp delta per iteration
EBSNOR_SPATIAL_WINDOW = 0           # EBSnoR filter spatial window
EBSNOR_TIME_WINDOW = 10000          # EBSnoR filter time window
USE_ADAPTIVE_WIN = False            # Enable/Disable EBSnoR adaptive window
###############################################################################


class CameraDims(NamedTuple):
    width: int
    height: int

class FilterWindows(NamedTuple):
    time_win: int
    spatial_win: int

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
    iter_evts = EventsIterator(EVENTS_FILEPATH, delta_t=33333, relative_timestamps = False)

    with Window(
        title="EBSnoR example",
        width=camera_dimensions.width,
        height=camera_dimensions.height,
        mode=BaseWindow.RenderMode.BGR
    ) as viewer:
        def keyboard_cb(key, scancode, action, mods):
            if action != UIAction.RELEASE:
                return
            if key == UIKeyEvent.KEY_ESCAPE or key == UIKeyEvent.KEY_Q:
                viewer.set_close_flag()
        viewer.set_keyboard_callback(keyboard_cb)

        event_frame_gen = OnDemandFrameGenerationAlgorithm(
            camera_dimensions.width,
            camera_dimensions.height
        )
        def on_frame_cb(ts, cd_frame):
            viewer.show(cd_frame)
        event_frame_gen.set_output_callback(on_frame_cb)

        for evts in iter_evts:
            processed = preprocessor.process(evts, adaptive_window=USE_ADAPTIVE_WIN)
            event_frame_gen.process_events(processed)

            if viewer.should_close():
                break

if __name__ == "__main__":
    main()
