# EyeTracker
\
This MATLAB toolbox was created to work with SpikeGLX to detect the location and size of a pupil. It will run online pupil detection during video acquisition, and automatically synchronize videos by creating a lookup table that logs pairs of SpikeGLX timestamps with video frame numbers. It also provides easy functionality to extract light pulses in the video that can be used to provide zero-lag synchronization between video frames and light pulse onsets. However, you can also use this toolbox as a standalone recording program without SpikeGLX.
\
To install & run, clone this repository and install your camera interface plugin. Add all subfolders to your matlab path and run:\
`runEyeTracker`\
in the matlab prompt.\
\
To run the offline pupil detection, run:\
`runEyeTrackerOffline`\
\
Please read the manual for more information: https://github.com/JorritMontijn/EyeTracker/blob/master/user_manual_EyeTracker.pdf

## Sneak peek
Please read the manual for how to use the program. Look below for what to expect.

### Online Eye Tracker & Acquisition
![runeyetracker](https://user-images.githubusercontent.com/15422591/200864719-8d84b70c-d05e-4845-bc62-85f4b2909a76.jpg)

### Offline Processor
![ManualParams](https://user-images.githubusercontent.com/15422591/200864986-30fc6be9-8bf6-4615-a743-51bafe3a0d3e.png)

### Curate & correct
![TrackerChecker](https://user-images.githubusercontent.com/15422591/200865286-64cdf7f2-2ca4-4b30-8dfc-ef9eb54ab6a7.png)

## License
This repository is licensed under the GNU General Public License v3.0, meaning you are free to use, edit, and redistribute any part of this code, as long as you refer to the source (this repository) and apply the same non-restrictive license to any derivative work (GNU GPL v3).\
\
Created by Jorrit Montijn at the Circuits, Structure and Function laboratory (KNAW-NIN).
