from dataclasses import dataclass
import os
import h5py
import matplotlib.pyplot as plt
import numpy as np

#--------------------------------------------------------------------
# FILENAMES
#--------------------------------------------------------------------
TIMEWIDTHS_FPATH = os.path.join("data", "tWidths_{}mph.mat")

#--------------------------------------------------------------------
# GENERATION SETTINGS
#--------------------------------------------------------------------
GEN_NO_IE = True
GEN_NO_LABEL_PROPAGATION = True
GEN_SPATIAL_WINDOW = True
GEN_PER_PIXEL = True
GEN_ADAPTIVE_WINDOW = True
RESULTS_PRINT_IDX = [8, 10, 1, 2, 9]

#--------------------------------------------------------------------
# TIME WINDOW SETTINGS
#--------------------------------------------------------------------
MAX_SNOW_DIAMETER = 0.2
CAR_VELOCITY = 30
ETAS = [
    55, 115, 150, 300, 500, 750,
    1000, 1755, 2065, 2185, 2500,
    5000, 7500, 10000, 50000, 100000
]

@dataclass
class ResultsStruct:
    precision: float
    recall: float
    accuracy: float
    tp_rate: float
    fp_rate: float
    tn_rate: float
    fn_rate: float

@dataclass
class PredictionData:
    tp: list[int | float] | int | float
    fp: list[int | float] | int | float
    tn: list[int | float] | int | float
    fn: list[int | float] | int | float
    gt_snow: int
    gt_nosnow: int

def calc_threshold() -> list[float]:
    snow_diameter_m = MAX_SNOW_DIAMETER/39.37
    car_velocity_mps = CAR_VELOCITY/2.237
    denominator = snow_diameter_m/car_velocity_mps
    tau_values = [numerator/denominator for numerator in ETAS]
    return tau_values

def get_timewidths(fname: str) -> np.ndarray:
    with h5py.File(fname, "r") as matfile:
        ground_truth = np.array(matfile.get("groundTruth")[0])
        spatial_win = np.array(matfile.get("tWidths_Window")[0])
        no_ie = np.array(matfile.get("tWidths_noIE")[0])
        no_lbl_prop = np.array(matfile.get("tWidths_noTE")[0])
        per_pixel = np.array(matfile.get("tWidths_noWindow")[0])
        adaptive_win = np.array(matfile.get("tWidths_smartWindow")[0])
    
    data = {
        "spatial_win" : spatial_win,
        "no_ie" : no_ie,
        "no_lbl_prop" : no_lbl_prop,
        "per_pixel" : per_pixel,
        "adaptive_win" : adaptive_win
    }
    return ground_truth, data

def get_tp_fp_tn_fn(data: PredictionData, pred, ground_truth) -> PredictionData:
    data.tp.append(
        np.count_nonzero(np.logical_and(ground_truth, pred))),
    data.fp.append(
        np.count_nonzero(np.logical_and(np.logical_not(ground_truth), pred))),
    data.tn.append(
        np.count_nonzero(np.logical_and(np.logical_not(ground_truth), np.logical_not(pred)))),
    data.fn.append(
        np.count_nonzero(np.logical_and(ground_truth, np.logical_not(pred)))),
    return data

def get_success_metrics(data: PredictionData) -> tuple[float, float, float]:
    length = len(data.tp)
    precision = [data.tp[x]/(data.tp[x] + data.fp[x]) for x in range(length)]
    recall = [data.tp[x]/(data.tp[x] + data.fn[x]) for x in range(length)]
    accuracy = [(data.tp[x] + data.tn[x])/(data.tp[x] + data.fp[x] + data.tn[x] + data.fn[x]) for x in range(length)]
    return precision, recall, accuracy

def get_success_rates(data: PredictionData) -> PredictionData:
    tp_rate = [tp/data.gt_snow for tp in data.tp]
    fp_rate = [fp/data.gt_nosnow for fp in data.fp]
    tn_rate = [tn/data.gt_nosnow for tn in data.tn]
    fn_rate = [fn/data.gt_snow for fn in data.fn]

    rates = PredictionData(
        tp=tp_rate,
        fp=fp_rate,
        tn=tn_rate,
        fn=fn_rate,
        gt_snow=0,
        gt_nosnow=0
    )
    return rates

if __name__ == "__main__":
    gen_results = {
        "no_ie" : GEN_NO_IE,
        "spatial_win" : GEN_SPATIAL_WINDOW,
        "no_lbl_prop" : GEN_NO_LABEL_PROPAGATION,
        "per_pixel" : GEN_PER_PIXEL,
        "adaptive_win" : GEN_ADAPTIVE_WINDOW
    }
    fpath = TIMEWIDTHS_FPATH.format(CAR_VELOCITY)
    ground_truth, twidth_data = get_timewidths(fpath)
    results: list[ResultsStruct] = []
    labels = [
        "No IE Filter",
        "No Label Propogation",
        "Spatial Window",
        "Adaptive Window",
        "Per Pixel"
    ]
    for idx, (key, enable) in enumerate(gen_results.items()):
        pred_data=PredictionData(
            tp=[],
            fp=[],
            tn=[],
            fn=[],
            gt_snow=np.sum(ground_truth),
            gt_nosnow=np.sum(np.logical_not(ground_truth))
        )
        if enable:
            twidths = twidth_data[key]
            for eta in ETAS:
                snow_pred = np.less(twidths, eta)
                pred_data = get_tp_fp_tn_fn(pred_data, snow_pred, ground_truth)
            precision, recall, accuracy = get_success_metrics(pred_data)
            rates = get_success_rates(pred_data)
            roc_data = ResultsStruct(
                precision=precision,
                recall=recall,
                accuracy=accuracy,
                tp_rate=rates.tp,
                fp_rate=rates.fp,
                tn_rate=rates.tn,
                fn_rate=rates.fn
            )
            print(f"\n{labels[idx]}\n=====\n")
            print(f"Eta = {ETAS[RESULTS_PRINT_IDX[idx]]}")
            print(f"\tFP Rate:   {rates.fp[RESULTS_PRINT_IDX[idx]]}")
            print(f"\tTP Rate:   {rates.tp[RESULTS_PRINT_IDX[idx]]}")
            print(f"\tAccuracy:   {accuracy[RESULTS_PRINT_IDX[idx]]}")
            results.append(roc_data)

    idx = 0
    colors = ["r", "b", "g", "c", "m"]
    plt.rcParams.update({'font.size': 20})
    for lbl_idx, enable in enumerate(gen_results.values()):
        if enable:
            plt.plot(
                results[idx].fp_rate,
                results[idx].tp_rate,
                "{}.-".format(colors[idx]),
                label=labels[lbl_idx]
            )
            plt.plot(
                [results[idx].fp_rate[-1], 1],
                [results[idx].tp_rate[-1], 1],
                "{}--".format(colors[idx]),
                label="_nolegend_"
            )
            labels.append(labels[idx])
            idx += 1
    plt.xlabel("False Positive")
    plt.ylabel("True Positive")
    plt.legend()

    plt.savefig("test.png")
    plt.show()
    plt.close()