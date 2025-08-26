import h5py
import numpy as np

FILEPATH = "data/simulation_snowEvents_40mph.mat"

HEADER_DATA = "% Height 720\n% Version 2\n% Width 1280\n% date 2023-11-26 19:27:11\n"
EVT_DATA = int.to_bytes(0x0C, byteorder="little") + int.to_bytes(0x08, byteorder="little")

def read_matfile_data(fname: str) -> tuple[list[int], list[int], list[int], list[int]]:
    with h5py.File(fname, "r") as matfile:
        xdata = np.array(matfile.get("x")[0]).astype(int).tolist()
        ydata = np.array(matfile.get("y")[0]).astype(int).tolist()
        pdata = np.array(matfile.get("p")[0]).astype(int).tolist()
        tdata = np.array(matfile.get("ts")[0]).astype(int).tolist()
        
    return xdata, ydata, pdata, tdata

def create_datfile_evt(x: int, y: int, p: int, ts: int) -> bytes:
    rval = int.to_bytes(ts, length=4, byteorder="little")
    rval += int.to_bytes(
        (p & 0x0001) << 28 | (y & 0x3FFF) << 14 | (x & 0x3FFF) << 0,
        length=4,
        byteorder="little"
    )
    return rval
        

if __name__ == "__main__":
    xdata, ydata, pdata, tdata = read_matfile_data(FILEPATH)
    savepath = FILEPATH.replace(".mat", ".dat")
    with open(savepath, "wb") as datfile:
        datfile.write(HEADER_DATA.encode("ascii"))
        datfile.write(EVT_DATA)
        
        for x, y, p, ts in zip(xdata, ydata, pdata, tdata):
            datfile.write(create_datfile_evt(x, y, p, ts))

    print("Finished! Saved to " + savepath)