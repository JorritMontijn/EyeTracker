function sET = ET_populateStructure(sET)
	%ET_populateStructure Prepares EyeTracker parameters by loading ini file,
	%						or creates one with default values
	
	%check for ini file
	strPathFile = mfilename('fullpath');
	cellDirs = strsplit(strPathFile,filesep);
	strPath = strjoin(cellDirs(1:(end-2)),filesep);
	strIni = strcat(strPath,filesep,'config.ini');
	
	%get defaults
	sDET = ET_defaultValues();
	
	%load ini
	if exist(strIni,'file')
		%load data
		fFile = fopen(strIni,'rt');
		vecData = fread(fFile);
		fclose(fFile);
		%convert
		strData = cast(vecData','char');
		[cellStructs,cellStructNames] = ini2struct(strData);
		eval([cellStructNames{1} '= cellStructs{1};']);
		%merge structures
		warning('off','catstruct:DuplicatesFound');
		sET=catstruct(sDET,sET);
		warning('on','catstruct:DuplicatesFound');
	else
		sET=sDET;
	end
	
	%set additional parameters
	sET.IsInitialized = false;
	sET.boolRecording = false;
	sET.boolDetectPupil = true;
	sET.boolSaveToDisk = false;
end
function sET = ET_defaultValues()
	%define defaults
	sET.intTempAvg = 1; %number of frames to average over; higher values limit detection rates
	sET.dblGaussWidth = 0.5; %blur width
	sET.vecRectROI = [100 50 450 400]; %crop
	sET.vecRectSync = [50 50 100 100];
	sET.dblThreshReflect = 255;%threshold for reflection (invert brightness if above)
	sET.dblThreshPupil = 8;%threshold for pupil (potential pupil if below)
	sET.dblPupilMinRadius = 2; %minimum radius of pupil (remove area if below)
	sET.dblThreshSync = 18;%threshold for sync pulse
	sET.intSubSample = 1;%subsample factor
	sET.boolInvertImage = 0;%invert image for albinos
	sET.boolRotateImage = 0;%rotate image by 90 degrees
	sET.strHostSGL = '192.87.10.238'; %default host address
	sET.hSGL = []; %SGL object placeholder
	sET.strRecordingNI = '...';
	
	sET.boolAutoStart = 1;
	sET.dblGain = 29.9;
	sET.dblGamma = 0.4;
end