from io import BufferedReader
import os
from typing import Callable

from events import Event2d, EventExtTrigger, EventFieldBytes, EventTypes

def _read_Event2d(datfile: BufferedReader, ts_offs: int) -> Event2d:
        timestamp = int.from_bytes(datfile.read(EventFieldBytes.TIMESTAMP), byteorder="little")
        addr = int.from_bytes(datfile.read(EventFieldBytes.ADDR), byteorder="little")
        evt = Event2d(
            x=(addr & 0x00003FFF) >> 0,
            y=(addr & 0x0FFFC000) >> 14,
            p=(addr & 0x10000000) >> 28,
            ts=timestamp + ts_offs
        )
        return evt

def _read_EventExtTrigger(datfile: BufferedReader, ts_offs: int) -> EventExtTrigger:
    timestamp = int.from_bytes(datfile.read(EventFieldBytes.TIMESTAMP), byteorder="little")
    addr = int.from_bytes(datfile.read(EventFieldBytes.ADDR), byteorder="little")
    evt = EventExtTrigger(
        id=(addr & 0x0000003F) >> 0,
        pad1=(addr & 0x0FFFFFC0) >> 6,
        p=(addr & 0x10000000) >> 28,
        ts=timestamp + ts_offs
    )
    return evt

class DatReader:
    def __init__(self, fname: str) -> None:
        self._datfile: BufferedReader = None #type: ignore
        self._at_eof: bool = False
        self._eof: int = None # type: ignore
        self._read_single: Callable[[BufferedReader, int], Event2d | EventExtTrigger] = None # type: ignore
        self._ts_offs = 0

        self._datfile = open(fname, "rb")
        self._eof, evtype = self._get_fileinfo()
        if evtype in [EventTypes.EVENT_2D, EventTypes.EVENT_CD]:
            self._read_single = _read_Event2d
        elif evtype == EventTypes.EVENT_EXT_TRIGGER:
            self._read_single = _read_EventExtTrigger
        else:
            raise ValueError(f"Unknown event type: {evtype}")

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        del exc_type, exc_value, traceback
        self.close()

    def close(self) -> None:
        self._datfile.close()

    def pos(self) -> int:
        return self._datfile.tell()

    def set_pos(self, pos: int) -> None:
        self._datfile.seek(pos)

    def read_event(self) -> Event2d | EventExtTrigger:
        evt = self._read_single(self._datfile, self._ts_offs)
        return evt

    def read_events(self, lim: int, by_ts: bool = False) -> list[Event2d | EventExtTrigger]:
        evts = self._read_win(lim) if by_ts else self._read_num(lim)
        return evts

    def set_ts_offset(self, offs: int) -> None:
        self._ts_offs = offs

    def finished(self) -> bool:
        return self._at_eof

    def reset_read(self) -> None:
        self._datfile.seek(0)

    def _get_fileinfo(self) -> tuple[int, int]:
        self._datfile.seek(0, os.SEEK_END)
        eof = self._datfile.tell()
        self._datfile.seek(0)
        while True:
            char = self._datfile.read(1)
            try:
                if char.decode("ascii") == "%":
                    self._datfile.readline()
                    continue
            except UnicodeDecodeError:
                pass
            self._datfile.read(1)
            break
        return eof, int.from_bytes(char, byteorder="little")

    def _read_num(self, num_evts: int) -> list[Event2d | EventExtTrigger]:
        evts = []
        for _ in range(num_evts):
            evt = self._read_single(self._datfile, self._ts_offs)
            evts.append(evt)
            if self._datfile.tell() >= self._eof:
                self._at_eof = True
                break
        return evts

    def _read_win(self, t_window: int) -> list[Event2d | EventExtTrigger]:
        evts = []
        evt = self._read_single(self._datfile, self._ts_offs)
        max_ts = evt.ts + t_window
        evts.append(evt)
        while True:
            evt = self._read_single(self._datfile, self._ts_offs)
            if evt.ts > max_ts:
                self._datfile.seek(-EventFieldBytes.TOTAL, os.SEEK_CUR)
                break
            evts.append(evt)
            if self.pos() >= self._eof:
                self._at_eof = True
                break
        return evts
