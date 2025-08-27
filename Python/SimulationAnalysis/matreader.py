from typing import Callable
import h5py
import numpy as np

from events import Event2d, EventExtTrigger, EventTypes

def _read_Event2d(matfile: h5py.File, idx: int, ts_offs: int) -> Event2d:
    evt = Event2d(
        x=matfile.get("x")[0][idx],            # type: ignore
        y=matfile.get("y")[0][idx],            # type: ignore
        p=matfile.get("p")[0][idx],            # type: ignore
        ts=matfile.get("ts")[0][idx] + ts_offs # type: ignore
    )
    return evt

def _read_EventExtTrigger(matfile: h5py.File, idx: int, ts_offs: int) -> EventExtTrigger:
    evt = EventExtTrigger(
        id=matfile.get("id")[0][idx],                                               # type: ignore
        pad1=matfile.get("pad1")[0][idx] if matfile.get("pad1") is not None else 0, # type: ignore
        p=matfile.get("p")[0][idx],                                                 # type: ignore
        ts=matfile.get("ts")[0][idx] + ts_offs                                      # type: ignore
    )
    return evt

class MatReader:
    def __init__(self, fname: str) -> None:
        self._matfile: h5py.File = None # type: ignore
        self._at_eof: bool = False
        self._eof: int = None           # type: ignore
        self._idx: int = 0
        self._read_single: Callable[[h5py.File, int, int], Event2d | EventExtTrigger] = None # type: ignore
        self._ts_offs = 0

        self._matfile = h5py.File(fname, "r")
        self._eof, evtype = self._get_fileinfo()
        if evtype in [EventTypes.EVENT_2D, EventTypes.EVENT_CD]:
            self._read_single = _read_Event2d
        elif evtype in [EventTypes.EVENT_EXT_TRIGGER]:
            self._read_single = _read_EventExtTrigger
        else:
            raise ValueError(f"Unknown event type: {evtype}")

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        del exc_type, exc_value, traceback
        self._matfile.close()

    def close(self) -> None:
        self._matfile.close()

    def pos(self) -> int:
        return self._idx

    def set_pos(self, pos: int) -> None:
        self._idx = pos

    def read_event(self) -> Event2d | EventExtTrigger:
        evt, self._idx = self._read_single(self._matfile, self._idx, self._ts_offs)
        return evt

    def read_events(self, lim: int, by_ts: bool = False) -> list[Event2d | EventExtTrigger]:
        evts = self._read_win(lim) if by_ts else self._read_num(lim)
        return evts

    def finished(self) -> bool:
        return self._at_eof

    def reset_read(self) -> None:
        self._idx = 0

    def set_ts_offset(self, ts_offs: int) -> None:
        self._ts_offs = ts_offs

    def _get_fileinfo(self) -> tuple[int, int]:
        exp_len = len(self._matfile.get("ts")[0]) # type: ignore
        evtype = 0x0C
        for key, val in self._matfile.items():
            if key == "ts":
                continue
            if key == "id":
                evtype = 0x0E
            if len(val[0]) != exp_len:
                raise ValueError("Invalid matfile. All data fields must have the same length.")
        return exp_len, evtype

    def _read_num(self, num_evts: int) -> list[Event2d | EventExtTrigger]:
        evts = []
        for _ in range(num_evts):
            evt = self._read_single(self._matfile, self._idx, self._ts_offs)
            evts.append(evt)
            self._idx += 1
            if self._idx >= self._eof:
                self._at_eof = True
                break
        return evts

    def _read_win(self, t_window: int) -> list[Event2d | EventExtTrigger]:
        evts = []
        evt = self._read_single(self._matfile, self._idx, self._ts_offs)
        self._idx += 1
        print(evt.ts)
        max_ts = evt.ts + t_window
        evts.append(evt)
        while True:
            evt = self._read_single(self._matfile, self._idx, self._ts_offs)
            if evt.ts > max_ts:
                print(f"{evt.ts} > {max_ts}")
                break
            evts.append(evt)
            self._idx += 1
            if self._idx >= self._eof:
                print("Eof")
                self._at_eof = True
                break
        return evts
