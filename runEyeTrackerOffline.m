%master path
strRootPath = 'P:\Montijn\DataNeuropixels\';
strTempPath = 'E:\_TempData'; %fast & reliable ssd;
strSearchFormat = '\d{4}[-_]?\d{2}[-_]?\d{2}';
cellExt = {'mp4','avi'};

%compile list of all video files in subfolders of master path
%list names & parameters from meta file
%list whether preprocessed
%select which to process
%path = pop up

%click to check parameters
%> new gui

%once all params are set for all videos, run


%% add subfolder to path
cellPaths = strsplit(path(),';');
strPathFile=mfilename('fullpath');
cellCodePath = strsplit(strPathFile,filesep);
strCodePath = fullfile(strjoin(cellCodePath(1:(end-1)),filesep),'subfunctionsETO');
if isempty(find(contains(cellPaths,strCodePath),1))
	addpath(strCodePath);
end

%% parameter gui
%define globals
global sFigETO;
global sETO;
sFigETO = struct;
sETO = struct;
sETO.strTempPath = strTempPath;
sETO.strRootPath = strRootPath;

%check if instance is already running
if isstruct(sFigETO) && isfield(sFigETO,'IsRunning') && sFigETO.IsRunning == 1
	error([mfilename ':SingularGUI'],'EyeTrackerModule instance is already running; only one simultaneous GUI is allowed');
end

%clear data & disable new instance
sFigETO.IsRunning = true;

%generate gui
[sFigETO,sETO] = ETO_genGUI(sFigETO,sETO);


