# Post-Dive-Heart-Rate-Detection



News
------------

2022/06/13: Repository created.
2022/10/03: Paper accepted
2022/11/14: Paper publish?

Requirements
------------
MATLAB version 2017b or newer, verified to work with Windows 10

Overview
------------
This repository contains the code described in Hoang et al. 2023, Automated heart rate detection in post-dive precordial Doppler ultrasound recordings. Doppler ultrasound (DU) precordial recordings were measured across 20 dives with varying degrees of venous gas emboli (VGE) presence. Furthermore, recordings were obtained at rest (stationary individual) or with leg flexions to induce VGE influx.

The code follows a short term autocorrelation algorithm to calculate the period between cardiac cycles and estimate the instantaneous heart rate (IHR) for each moment in a recording. 

Usage
------------
To perform heart rate detection on all files in a directory use HeartRateEstimation_STAC_v1_2022_02_09.m
Point -datafilepath- to directory with DU audio files. Set parameters for desired window overlap (default is 0.5 or 50%) and window size (refer to paper for optimal window size, default = 2 seconds). Run script and IHR plots will be made for each DU audio in the file and found in the variable "all_heartrates". 

Code for generating figures from the paper exist in "ForFigures" directory allowing for performing the code on DU audio files with varying or single window sizes. 

License and Citation
------------
The codes are licensed under GPL-2.0 license.

For any utilization of the code content of this repository, the following paper needs to be cited by the user:

> Hoang A, Le DQ, Blogg SL, et al. A fully automated algorithm for heart rate detection in post-dive precordial Doppler ultrasound. Undersea Hyperb Med. 2023 First Quarter; 50(1):43-53.
