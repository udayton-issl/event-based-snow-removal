# EBSnoR Python Scripts

The following categories of Python scripts are provided for experimentation with EBSnoR:

- EBSnoR: Basic EBSnoR example
- ObjectDetection: Object detection using EBSnoR as a preprocessor
- RocCurveGeneration: Generate ROC curves for EBSnoR algorithm analysis
- SimulationAnalysis: Analysis tools for EBSnoR simulations

The minimum supported Python version is Python3.10. To install pip dependencies, run:

```
pip install requirements.txt
```

Some scripts may require additional dependencies. These will be detailed in the corresponding sections.

## EBSnoR

The EBSnoR script category provides a basic EBSnoR example. When run, the script will stream events from a `.raw` file, process the data using EBSnoR, and display the processed data in a viewer window. To run, modify the `EVENTS_FILEPATH` constant to point to the desired `.raw` file and use the command

```
python3 ebsnor.py
```

***Note:** This script requires the MetaVision SDK in order to run.*

## ObjectDetection

The ObjectDetection script category provides an example for using EBSnoR as a preprocessor to an object detection CNN. To run, modify the path and settings constants as desired and use the command

```
python3 detection_cnn.py
```

***Note:** This script requires the MetaVision SDK and the [Keigo we need to fill this in what is the dataset name](also we need URL)*

Additionally, this category contains two additional scripts to aid in benchmarking the detection algorithm. The first annotates event footage frames with boxes denoting detections and labels. To run, modify the paths and settings constants as desired and use the command

```
python3 det_vs_lbl.py
```

The second calculates statistical metrics, include accuracy, IOU, precision and recall. To run, modify the paths and settings constants as desired and use the command

```
python3 file_comparison.py
```

## RocCurveGeneration

The RocCurveGeneration script category provides an example for generating ROC curves for the EBSnoR algorithm. To run, modify the path and settings constants as desired and use the command

```
python3 generateRoc_main.py
```

***Note:** Generating ROC curves requires pre-processed data in MATLAB output format*

## SimulationAnalysis

The SimulationAnalysis script category provides an example for analyzing EBSnoR simulation data. To run, modify the path and settings constants as desired and use the command

```
python3 simAnalysis_main.py
```

***Note:** Performing simulation analysis requires pre-processed data in MATLAB output format*
