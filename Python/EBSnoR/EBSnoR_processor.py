from typing import Tuple
import numpy as np
import numpy.lib.recfunctions as rfn

class EBSnoRProcessor:
    """
    add docstring
    """
    def __init__(
        self,
        time_window: int,
        spatial_window: int = 0,
        camera_dimensions: Tuple[int, int] = (1280, 720)
    ) -> None:
        self.time_window = time_window
        self.spatial_window = spatial_window
        self.cam_x, self.cam_y = camera_dimensions

    def ie_filter(self, events, time_window: int = 10000, te_depth: int = 10):
        ie_idx = np.zeros((self.cam_x, self.cam_y + 2), dtype=int)
        prev_ts = np.zeros((self.cam_x, self.cam_y + 2), dtype=int)
        prev_p = np.zeros((self.cam_x, self.cam_y + 2), dtype=int)

        ie_data = np.zeros((events['x']), dtype=bool)
        te_data = -1*np.ones(len(events['x'], te_depth), dtype=int)
        te_idx = np.zeros(len(events['x']), dtype=int)

        iter_ev = zip(events['x'], events['y'], events['p'], events['t'])
        for idx, (xval, yval, pval, tval) in enumerate(iter_ev):
            if pval != prev_p[xval][yval] or tval - prev_ts[xval][yval] > time_window:
                ie_data[idx] = True
                ie_idx[xval][yval] = idx
            else:
                if te_idx[ie_idx[xval][yval]] > te_depth:
                    continue
                te_data[ie_idx[xval][yval]][te_idx[xval][yval]] = idx
                te_idx[ie_idx[xval][yval]] += 1
            prev_ts[xval][yval] = tval
            prev_p[xval][yval] = pval

        return ie_data, te_data

    def ebsnor_filter(self, events, ie_data, te_data, adaptive_win: bool = False):
        events['x'] += self.spatial_window
        events['y'] += self.spatial_window
        pos_ts = -np.inf*np.ones(
            self.cam_x + 2*self.spatial_window, self.cam_y + 2*self.spatial_window)
        pos_idx = np.zeros(
            self.cam_x + 2*self.spatial_window, self.cam_y + 2*self.spatial_window)
        win = np.arange(-self.spatial_window, self.spatial_window + 1, dtype=int)
        snow = np.zeros(len(events['x']), dtype=bool)
        iter_ev = zip(events['x'], events['y'], events['p'], events['t'])

        for idx, (xval, yval, pval, tval) in enumerate(iter_ev):
            if ie_data[idx] and pval < 0:
                in_range = False
                if adaptive_win:
                    in_range = tval - pos_ts[xval][yval] < self.time_window
                    positions = pos_idx[xval][yval]
                if not in_range:
                    in_range = np.less(tval - pos_ts[xval + win][yval + win], self.time_window)
                    positions = pos_idx[xval + win][yval + win]
                if in_range.any():
                    snow[idx] = True
                    te_idx = te_data[idx]
                    snow[te_idx[te_idx > -1]] = True
                    snow[positions[in_range]] = True
                    te_idx = te_data[positions[in_range]]
                    snow[te_idx[te_idx > 0]] = True
            elif ie_data[idx]:
                pos_idx[xval][yval] = idx
                pos_ts[xval][yval] = idx

        return snow

    def process(self, events, adaptive_win: bool = False):
        """Process an event stream with EBSnoR."""
        ie_data, te_data = self.ie_filter(events)
        snow = self.ebsnor_filter(events, ie_data, te_data, adaptive_win=adaptive_win)

        new_length = len(events['x']) - np.count_nonzero(snow)
        x = events['x'][np.logical_not(snow)]
        y = events['y'][np.logical_not(snow)]
        t = events['t'][np.logical_not(snow)]
        p = events['p'][np.logical_not(snow)]

        events = np.resize(events, new_length)
        events['x'] = x
        events['y'] = y
        events['t'] = t
        events['p'] = p

        return events
