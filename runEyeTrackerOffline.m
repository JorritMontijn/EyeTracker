%runEyeTrackerOffline GUI to perform eye-tracking on pre-recorded videos
%
%This GUI interfaces with the outputs of "runEyeTracker" and provides an
%easy to use interface for managing your library of eye-tracking videos.
%You can set the algorithm's parameters manually, or set a limited number
%of labelled frames and let the algorithm optimize by itself.
%
%	Created by Jorrit Montijn, 2021-05-12 (YYYY-MM-DD)

%Version history:
%1.0 - 12 May 2021
%	Created by Jorrit Montijn

%% add subfolder to path
cellPaths = strsplit(path(),';');
strPathFile=mfilename('fullpath');
cellCodePath = strsplit(strPathFile,filesep);
strCodePath = fullfile(strjoin(cellCodePath(1:(end-1)),filesep),'subfunctionsETO');
if isempty(find(contains(cellPaths,strCodePath),1))
	addpath(strCodePath);
end

%% check if dependencies are present
if ~exist('uilock','file')
	error([mfilename ':MissingDependency'],sprintf('This function requires the "GeneralAnalysis" repository to function. You can get it here: %s','https://github.com/JorritMontijn/GeneralAnalysis'));
end

%% define globals
global sFigETO;
global sETO;

%% load defaults
sETO = ETO_populateStructure();
sFigETO = struct;

%% run
%check if instance is already running
if isstruct(sFigETO) && isfield(sFigETO,'IsRunning') && sFigETO.IsRunning == 1
	error([mfilename ':SingularGUI'],'EyeTrackerModule instance is already running; only one simultaneous GUI is allowed');
end

%clear data & disable new instance
sFigETO.IsRunning = true;

%generate gui
[sFigETO,sETO] = ETO_genGUI(sFigETO,sETO);


