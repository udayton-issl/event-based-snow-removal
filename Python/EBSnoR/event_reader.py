import os
from metavision_core.event_io.raw_reader import RawReader
from metavision_core.event_io.py_reader import EventDatReader
from metavision_core.utils import get_sample


class EventReader():
    def __init__(self, fname):
        f = get_sample(fname)
        if fname.endswith('.raw'):
            self.file_data = RawReader(f)
        elif fname.endswith('.dat'):
            self.file_data = EventDatReader(f)

    def read_by_num(self, evNum):
        return self.file_data.load_n_events(evNum)

    def read_by_delta_t(self, delta_t):
        return self.file_data.load_delta_t(delta_t)
