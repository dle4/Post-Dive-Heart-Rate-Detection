# Post-Dive-Heart-Rate-Detection



News
------------

2022/06/13: Repository created.
2022/06/~: Paper submitted??

Requirements
------------
MATLAB version 2017b or newer

Overview
------------
This repository contains the code described in Hoang et al. 2022, Automated heart rate detection in post-dive precordial Doppler ultrasound recordings. Additionally, data and labels used to evaluate the algorithm is provided alongside the code. Doppler ultrasound precordial recordings were measured across 20 dives with varying degrees of venous gas emboli (VGE) presence. Furthermore, recordings were obtained at rest (stationary individual) or with leg flexions to induce VGE influx.

The code follows a short term autocorrelation algorithm shown in Fig 1. to calculate the period between cardiac cycles and estimate the instantaneous heart rate for each moment in a recording. 

Usage
------------
To perform HRD on all files in a directory use HeartRateEstimation_STAC_v1_2022_02_09.m
Point -datafilepath- to directory with DU audio files. Set parameters for desired window overlap (default is 0.5 or 50%) and window size (refer to paper for optimal window size, default = 2 seconds). 

License and Citation
------------
Hoang et al. 2022, Automated heart rate detection  in post-dive precordial Doppler ultrasound recordings
