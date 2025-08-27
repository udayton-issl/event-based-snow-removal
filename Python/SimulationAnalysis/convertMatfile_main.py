from typing import List, Tuple
import h5py
import numpy as np

###############################################################################
# Data paths, replace with corresponding paths on your system
MAT_FILEPATH = ""                   # MAT data filepath
###############################################################################

HEADER_DATA = "% Height 720\n% Version 2\n% Width 1280\n% date 2023-11-26 19:27:11\n"
EVT_DATA = int.to_bytes(0x0C, byteorder="little", length=1) \
    + int.to_bytes(0x08, byteorder="little", length=1)

def read_matfile_data(fname: str) -> Tuple[List[int], List[int], List[int], List[int]]:
    with h5py.File(fname, "r") as matfile:
        xdata = np.array(matfile.get("x")[0]).astype(int).tolist()  # type: ignore
        ydata = np.array(matfile.get("y")[0]).astype(int).tolist()  # type: ignore
        pdata = np.array(matfile.get("p")[0]).astype(int).tolist()  # type: ignore
        tdata = np.array(matfile.get("ts")[0]).astype(int).tolist() # type: ignore

    return xdata, ydata, pdata, tdata

def create_datfile_evt(xval: int, yval: int, pval: int, tval: int) -> bytes:
    rval = int.to_bytes(tval, length=4, byteorder="little")
    rval += int.to_bytes(
        (pval & 0x0001) << 28 | (yval & 0x3FFF) << 14 | (xval & 0x3FFF) << 0,
        length=4,
        byteorder="little"
    )
    return rval

def main() -> None:
    xdata, ydata, pdata, tdata = read_matfile_data(MAT_FILEPATH)
    savepath = MAT_FILEPATH.replace(".mat", ".dat")
    with open(savepath, "wb") as datfile:
        datfile.write(HEADER_DATA.encode("ascii"))
        datfile.write(EVT_DATA)
        for xval, yval, pval, tval in zip(xdata, ydata, pdata, tdata):
            datfile.write(create_datfile_evt(xval, yval, pval, tval))

    print(f"Conversion complete. Saved to {savepath}")

if __name__ == "__main__":
    main()
