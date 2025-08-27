# EBSnoR Matlab Scripts

The following categories of MATLAB scripts are provided for experimentation with EBSnoR

- GetTimewidths: Format raw event data into timewidths
- ImageGeneration: Generate image frames from raw event data
- RocCurveGeneration: Generate ROC curves for EBSnoR algorithm analysis
- VideoGeneration: Convert raw event data into a viewable video

## GetTimewidths

The GetTimewidths category provides scripts for converting raw event data into timewidth data files. Performing this conversion can allow for faster processing in later experimentation stages. Two scripts are provided in this category:

- getTimeWidths_main.m: Convert a raw event file to timewidth, optionally merge simulation data
- getTimewidthsSimOnly_main.m: Perform timewidth conversion for simulation data only

## ImageGeneration

The ImageGeneration category provides scripts for creating results images from raw event data. Two scripts are provided in this category:

- imageGeneration_main.m: Create results images from raw event data
- imageGenerationByMethod_main.m: Create results images comparing two or more preprocessing methods from raw event data

## RocCurveGeneration

The RocCurveGeneration category provides scripts for generating ROC curves for the EBSnoR algorithm. Pregenerated timewidths are needed to run ROC curve generation. One script is provided in this category:

- rocGeneration_main.m: Generate a ROC curve

## VideoGeneration

The VideoGeneration category provides scripts for generating videos and frames from raw event data. Three scripts are provided in this category:

- saveFrames_main.m: Convert a raw event file into frame images
- videoGeneration_main.m: Generate a video from raw event data, optionally add preprocessing
- videoGenerationByMethod_main.m: Generate a video comparing two or more preprocessing methods from raw event data