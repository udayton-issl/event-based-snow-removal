import argparse
import os
from datreader import DatReader
from events import EventFieldBytes
import math

SIMULATION_30MPH = os.path.join("data", "simulation_snowEvents_30mph.dat")
SIMULATION_40MPH = os.path.join("data", "simulation_snowEvents_40mph.dat")
BASELINE_30MPH = os.path.join("data", "baseline_backgroundEvents_30mph.dat")
BASELINE_40MPH = os.path.join("data", "baseline_backgroundEvents_40mph.dat")

RESULTS_SAVEFILE = "event_analysis.txt"

def get_percent_match(
    baseline_reader: DatReader,
    simulation_reader: DatReader,
    max_time: int = None
) -> float:
    total_events = 0
    total_matches = 0
    first_done = False
    max_time = max_time if max_time is not None else math.inf
    while not baseline_reader.finished():
        if first_done:
            curr_ts = baseline_reader.read_event().ts
            if curr_ts > max_time:
                break
            simulation_reader.set_ts_offset(curr_ts)
            baseline_reader.set_pos(baseline_reader.pos() - EventFieldBytes.TOTAL)
        prev_sim_ts = 0
        while not simulation_reader.finished():
            sim_evts = simulation_reader.read_events(10000)
            base_evts = baseline_reader.read_events(sim_evts[-1].ts - prev_sim_ts, by_ts=True)
            prev_sim_ts = sim_evts[-1].ts
            total_events += len(sim_evts) + len(base_evts)
            total_matches += len(set(sim_evts).intersection(set(base_evts)))
            if prev_sim_ts > max_time:
                break
        first_done = True
        simulation_reader.reset_read()
    return total_matches/total_events, total_events

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Find percent of identical events in simulation vs. baseline data.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "--30mph", dest="run_30mph", action="store_true", help="Analyze 30MPH sequence")
    parser.add_argument(
        "--40mph", dest="run_40mph", action="store_true", help="Analyze 40MPH sequence")
    parser.add_argument(
        "--all", dest="run_both", action="store_true", help="Analyze 30MPH and 40MPH sequence")
    args = parser.parse_args()
    run30 = args.run_30mph or args.run_both
    run40 = args.run_40mph or args.run_both

    n_sec = int(3.6*1e6)
    resfile = open(RESULTS_SAVEFILE, "w", encoding="utf-8")

    if run30:
        with DatReader(BASELINE_30MPH) as base_reader:
            with DatReader(SIMULATION_30MPH) as sim_reader:
                percent_match, total_ev = get_percent_match(base_reader, sim_reader, n_sec)
        print(f"30MPH Sequence: {percent_match:.2f}%")
        resfile.write(f"30MPH Sequence: {percent_match:.2f}% match, {total_ev} events analyzed\n")
    if run40:
        with DatReader(BASELINE_40MPH) as base_reader:
            with DatReader(SIMULATION_40MPH) as sim_reader:
                percent_match, total_ev = get_percent_match(base_reader, sim_reader, n_sec)
        print(f"40MPH Sequence: {percent_match:.2f}%")
        resfile.write(f"40MPH Sequence: {percent_match:.2f}% match, {total_ev} events analyzed\n")

    resfile.close()
