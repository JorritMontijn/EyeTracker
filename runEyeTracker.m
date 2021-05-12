function varargout = runEyeTracker(varargin)
	%runEyeTracker Acquire eye-tracking video while performing detection
	%
	%This GUI interfaces with SpikeGLX to enable automatic cross-platform
	%synchronization. It can run online pupil tracking and allows you to
	%set a reasonable estimate for the parameters requires for accurate
	%offline pupil tracking. It outputs files that can be used by
	%"runEyeTrackerOffline" to provide higher-quality offline tracking.
	%
	%	Created by Jorrit Montijn, 2019-09-16 (YYYY-MM-DD)

	%Version 1.0 [2019-09-16]
	%	Created by Jorrit Montijn
	%Version 1.1 [2019-11-11] by JM
	%	Major update:
	%	-Added offline analysis
	%	-Tweaked default parameters
	%	-Added regressive location selection if no primaries are found
	%	-Added weighting by distance to previous location
	%	-Updated recording program to reset variables at recording start and save all variables at recording end
	%	-Some other minor changes
	%	-To do: fix sliders...
	%Version 2.0 [2020-10-19] by JM
	%	Major, non-backwards compatible update:
	%	-Updated to use new detection algorithm
	%	-Added luminance inversion to detect bright pupils
	%	-Added CPU-based processing as backup to GPU-accelerated detection
	%	-Can now use cameras that have no "RealFrameRate" property
	%	-To do: add selectable pupil range, e.g. -2 ... +1 around base lum
	%	-To do: fix sync lum sliders?
	%Version 2.1 [2020-12-08] by JM
	%	Minor update:
	%	-Added 90-degree rotation button
	%	-Fixed sync lum sliders
	%Version 2.2 [2021-02-08] by JM
	%	Major update:
	%	-Added SpikeGLX timestamp logging
	%Version 2.2.1 [2021-02-10] by JM
	%	Several bug fixes
	%	- to do: manual gain: objProps.Gain = 29.904700000000002;
	%	- to do: manual gamma: objProps.Gamma = 1;
	%	- to do: add NaN removal of sync file
	%	- to do: automatically start recording when spikeglx records
	%Version 2.3 [2021-02-15] by JM
	%	Added features: 
	%	- gain control
	%	- gamma control
	%	- NaN removal
	%	- auto-start
	% - to do: add automatic filename when autostart is on; will pick spikeglx name
	%Version 2.3.1 [2021-02-15] by JM
	%	Bug fix:
	%	- auto-start
	%	Added features: 
	%	- automatic file naming
	%	To do:
	%	- multi-camera support
	
	%set tags
	%#ok<*INUSL>
	%#ok<*INUSD>
	
	% Begin initialization code - DO NOT EDIT
	gui_Singleton = 1;
	gui_State = struct('gui_Name',       mfilename, ...
		'gui_Singleton',  gui_Singleton, ...
		'gui_OpeningFcn', @runEyeTracker_OpeningFcn, ...
		'gui_OutputFcn',  @runEyeTracker_OutputFcn, ...
		'gui_LayoutFcn',  [] , ...
		'gui_Callback',   []);
	if nargin && ischar(varargin{1})
		gui_State.gui_Callback = str2func(varargin{1});
	end
	
	if nargout
		[varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
	else
		gui_mainfcn(gui_State, varargin{:});
	end
	% End initialization code - DO NOT EDIT
	
end
%% these are functions that don't do anything, but are required by matlab
function ptrSliderSyncROIStartLocX_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrSliderSyncROIStartLocY_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrSliderSyncROIStopLocX_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrSliderSyncROIStopLocY_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrSliderPupilROIStartLocX_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrSliderPupilROIStartLocY_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrSliderPupilROIStopLocX_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrSliderPupilROIStopLocY_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrEditTempAvg_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrEditBlurWidth_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrEditPupilLum_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrEditReflectLum_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrEditSyncLum_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrEditMinRadius_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrListSelectAdaptor_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>
function ptrListSelectDevice_CreateFcn(hObject, eventdata, handles),end%#ok<DEFNU>

%% opening function; initializes output
function runEyeTracker_OpeningFcn(hObject, eventdata, handles, varargin)
	%opening actions
	
	%define globals
	global sEyeFig;
	global sET;
	sEyeFig = [];
	sET = [];
	
	%set closing function
	set(hObject,'DeleteFcn','ET_DeleteFcn')
	
	% set logo
	I = imread('EyeTracker.jpg');
	axes(handles.ptrAxesLogo);
	imshow(I);
	drawnow;
	
	% set default output
	handles.output = hObject;
	guidata(hObject, handles);
	
	%set default values
	sET = struct;
	sET = ET_populateStructure(sET);
	
	%populate figure
	boolInit = true;
	sEyeFig = ET_populateFigure(handles,boolInit);
	
	%initialize figure
	[sEyeFig,sET] = ET_initialize(sEyeFig,sET);
	
	% Update handles structure
	guidata(hObject, handles);
	
	%ask for file output
	ptrButtonSetVidOutFile_Callback();
	
	%connect
	set(sEyeFig.ptrToggleConnectSGL,'Value',1);
	ptrToggleConnectSGL_Callback();
	
	%run
	ET_main();
end
%% defines output variables
function varargout = runEyeTracker_OutputFcn(hObject, eventdata, handles)
	%output
	varargout{1} = [];
end
%% slider callback functions
%% sync ROI
function ptrSliderSyncROIStartLocX_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get global
	global sET;
	
	%% update ROI
	%ROI: [x-from-left y-from-top x-width y-height]
	vecMax = [sET.intMaxX sET.intMaxY];
	intDim = 1;
	
	%get new loc
	dblVal = get(hObject,'Value');
	dblMin = get(hObject,'Min');
	dblMax = get(hObject,'Max');
	
	%set new loc
	dblNewLocFrac = (dblVal-dblMin) / (dblMax-dblMin);
	intNewStart = round(dblNewLocFrac*vecMax(intDim));
	intOldStart = sET.vecRectSync(intDim);
	sET.vecRectSync([intDim intDim+2]) = [intNewStart (sET.vecRectSync(intDim+2)+intOldStart - intNewStart)];
end
function ptrSliderSyncROIStartLocY_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get global
	global sET;
	
	%% update ROI
	%ROI: [x-from-left y-from-top x-width y-height]
	vecMax = [sET.intMaxX sET.intMaxY];
	intDim = 2;
	
	%get new loc
	dblVal = get(hObject,'Value');
	dblMin = get(hObject,'Min');
	dblMax = get(hObject,'Max');
	
	%set new loc
	dblNewLocFrac = (dblVal-dblMin) / (dblMax-dblMin);
	intNewStart = round(dblNewLocFrac*vecMax(intDim));
	intOldStart = sET.vecRectSync(intDim);
	sET.vecRectSync([intDim intDim+2]) = [intNewStart (sET.vecRectSync(intDim+2)+intOldStart - intNewStart)];
end
function ptrSliderSyncROIStopLocX_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get global
	global sET;
	
	%% update ROI
	%ROI: [x-from-left y-from-top x-width y-height]
	vecMax = [sET.intMaxX sET.intMaxY];
	intDim = 1;
	
	%get new loc
	dblVal = get(hObject,'Value');
	dblMin = get(hObject,'Min');
	dblMax = get(hObject,'Max');
	
	%set new loc
	dblNewLocFrac = (dblVal-dblMin) / (dblMax-dblMin);
	intNewStop = round(dblNewLocFrac*vecMax(intDim)-sET.vecRectSync(intDim));
	sET.vecRectSync(intDim+2) = intNewStop;
end
function ptrSliderSyncROIStopLocY_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get global
	global sET;
	
	%% update ROI
	%ROI: [x-from-left y-from-top x-width y-height]
	vecMax = [sET.intMaxX sET.intMaxY];
	intDim = 2;
	
	%get new loc
	dblVal = get(hObject,'Value');
	dblMin = get(hObject,'Min');
	dblMax = get(hObject,'Max');
	
	%set new loc
	dblNewLocFrac = (dblVal-dblMin) / (dblMax-dblMin);
	intNewStop = round(dblNewLocFrac*vecMax(intDim)-sET.vecRectSync(intDim));
	sET.vecRectSync(intDim+2) = intNewStop;
	
end
%% pupil ROI
function ptrSliderPupilROIStartLocX_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get global
	global sET;
	
	%% update ROI
	%ROI: [x-from-left y-from-top x-width y-height]
	vecMax = [sET.intMaxX sET.intMaxY];
	intDim = 1;
	
	%get new loc
	dblVal = get(hObject,'Value');
	dblMin = get(hObject,'Min');
	dblMax = get(hObject,'Max');
	
	%set new loc
	dblNewLocFrac = (dblVal-dblMin) / (dblMax-dblMin);
	intNewStart = round(dblNewLocFrac*vecMax(intDim));
	intOldStart = sET.vecRectROI(intDim);
	sET.vecRectROI([intDim intDim+2]) = [intNewStart (sET.vecRectROI(intDim+2)+intOldStart - intNewStart)];
	
end
function ptrSliderPupilROIStartLocY_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get global
	global sET;
	
	%% update ROI
	%ROI: [x-from-left y-from-top x-width y-height]
	vecMax = [sET.intMaxX sET.intMaxY];
	intDim = 2;
	
	%get new loc
	dblVal = get(hObject,'Value');
	dblMin = get(hObject,'Min');
	dblMax = get(hObject,'Max');
	
	%set new loc
	dblNewLocFrac = (dblVal-dblMin) / (dblMax-dblMin);
	intNewStart = round(dblNewLocFrac*vecMax(intDim));
	intOldStart = sET.vecRectROI(intDim);
	sET.vecRectROI([intDim intDim+2]) = [intNewStart (sET.vecRectROI(intDim+2)+intOldStart - intNewStart)];
end
function ptrSliderPupilROIStopLocX_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get global
	global sET;
	
	%% update ROI
	%ROI: [x-from-left y-from-top x-width y-height]
	vecMax = [sET.intMaxX sET.intMaxY];
	intDim = 1;
	
	%get new loc
	dblVal = get(hObject,'Value');
	dblMin = get(hObject,'Min');
	dblMax = get(hObject,'Max');
	
	%set new loc
	dblNewLocFrac = (dblVal-dblMin) / (dblMax-dblMin);
	intNewStop = round(dblNewLocFrac*vecMax(intDim)-sET.vecRectROI(intDim));
	sET.vecRectROI(intDim+2) = intNewStop;
end
function ptrSliderPupilROIStopLocY_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get global
	global sET;
	
	%% update ROI
	%ROI: [x-from-left y-from-top x-width y-height]
	vecMax = [sET.intMaxX sET.intMaxY];
	intDim = 2;
	
	%get new loc
	dblVal = get(hObject,'Value');
	dblMin = get(hObject,'Min');
	dblMax = get(hObject,'Max');
	
	%set new loc
	dblNewLocFrac = (dblVal-dblMin) / (dblMax-dblMin);
	intNewStop = round(dblNewLocFrac*vecMax(intDim)-sET.vecRectROI(intDim));
	sET.vecRectROI(intDim+2) = intNewStop;
end
%% list/edit callbacks
function ptrButtonSetVidOutFile_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% use external function
	ET_setVidOut();
end
function ptrEditTempAvg_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get globals
	global sET;
	
	%% set value
	%get value
	intVal = round(str2double(get(hObject,'String')));
	%set to within bounds
	sET.intTempAvg = max([min([intVal 100]) 1]); %range: 1-10
	%re-assign, just in case
	set(hObject,'String',num2str(sET.intTempAvg));
end
function ptrEditBlurWidth_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get globals
	global sET;
	
	%% set value
	%get value
	dblVal = str2double(get(hObject,'String'));
	dblVal = max([min([dblVal 100]) 0]); %range: 0-100
	%set to within bounds
	sET.dblGaussWidth = roundi(dblVal,1);
	%re-assign, just in case
	set(hObject,'String',sprintf('%.1f',sET.dblGaussWidth));
end
function ptrEditPupilLum_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get globals
	global sET;
	
	%% set value
	%get value
	dblVal = str2double(get(hObject,'String'));
	%set to within bounds
	sET.dblThreshPupil = max([min([dblVal 256]) 0]); %range: 0-256
	%re-assign, just in case
	set(hObject,'String',num2str(sET.dblThreshPupil));
end
function ptrEditReflectLum_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get globals
	global sET;
	
	%% set value
	%get value
	dblVal = str2double(get(hObject,'String'));
	%set to within bounds
	sET.dblThreshReflect = max([min([dblVal 256]) 0]); %range: 0-256
	%re-assign, just in case
	set(hObject,'String',num2str(sET.dblThreshReflect));
end
function ptrEditSyncLum_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get globals
	global sET;
	
	%% set value
	%get value
	dblVal = str2double(get(hObject,'String'));
	%set to within bounds
	sET.dblThreshSync = roundi(dblVal,1);
	%re-assign, just in case
	set(hObject,'String',sprintf('%.1f',sET.dblThreshSync));
end
function ptrEditMinRadius_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get globals
	global sET;
	
	%% set value
	%get value
	dblVal = str2double(get(hObject,'String'));
	%set to within bounds
	sET.dblPupilMinRadius = roundi(dblVal,1);
	%re-assign, just in case
	set(hObject,'String',sprintf('%.1f',sET.dblPupilMinRadius));
end
function ptrListSelectAdaptor_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	% hObject    handle to ptrListSelectAdaptor (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Hints: contents = cellstr(get(hObject,'String')) returns ptrListSelectAdaptor contents as cell array
	%        contents{get(hObject,'Value')} returns selected item from ptrListSelectAdaptor
end
function ptrListSelectDevice_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	% hObject    handle to ptrListSelectDevice (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Hints: contents = cellstr(get(hObject,'String')) returns ptrListSelectDevice contents as cell array
	%        contents{get(hObject,'Value')} returns selected item from ptrListSelectDevice
end

%% switch button callbacks
function ptrToggleRecord_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get globals
	global sEyeFig;
	global sET;
	
	%% set string
	intRecording = get(hObject,'Value');
	if intRecording == 1
		%check if file has been defined
		if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Filename') && ~isempty(sET.objVidWriter.Filename)
			%start recording
			ET_startRecording();
		else
			set(hObject,'Value',0);
		end
	else
		set(sEyeFig.ptrTextRecording,'String','Idle','ForegroundColor',[0 0 0]);
		ET_unlock(handles);
		set(sEyeFig.ptrToggleConnectSGL,'Enable','on');
		sET.boolRecording = false;
		ET_stopRecording();
	end
end
function ptrButtonToggleSubSize_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get globals
	global sET;
	global sEyeFig;
	
	%% set string
	dblPrevSubSample = sET.intSubSample;
	if get(hObject,'Value') == 0 && ~sET.boolRecording
		sET.intSubSample = 1;
		set(sEyeFig.ptrTextSubSample,'String','Full Res','ForegroundColor',[0 0 0]);
	elseif get(hObject,'Value') == 1 && ~sET.boolRecording
		sET.intSubSample = 2;
		set(sEyeFig.ptrTextSubSample,'String','SuperSpeed','ForegroundColor',[0 0.8 0]);
	end
	%% update variables
	%update values
	dblChangeFactor = dblPrevSubSample/sET.intSubSample;
	sET.dblPupilMinRadius = sET.dblPupilMinRadius * dblChangeFactor;
	sET.dblGaussWidth = sET.dblGaussWidth * dblChangeFactor;
	sET.vecRectROI = round(sET.vecRectROI * dblChangeFactor);
	sET.vecRectSync = round(sET.vecRectSync * dblChangeFactor);
	%update GUI
	set(sEyeFig.ptrEditBlurWidth,'String',sprintf('%.1f',sET.dblGaussWidth));
	set(sEyeFig.ptrEditMinRadius,'String',sprintf('%.1f',sET.dblPupilMinRadius));
end
function figure1_CloseRequestFcn(hObject, eventdata, handles) %#ok<DEFNU>
	%% get global
	global sEyeFig;
	
	%% closing actions
	%set running switch to false
	sEyeFig.boolIsRunning = false;
	
	%wait for main() to finish
	
	%check if busy, otherwise close after 1 second
	if sEyeFig.boolIsBusy
		% set timer to wait for one second, otherwise allow force-quit
		objTimer = timer();
		objTimer.StartDelay = 1;
		objTimer.ExecutionMode = 'singleShot';
		objTimer.TimerFcn = @ET_enableForceQuit;
		start(objTimer);
	else
		delete(hObject);
	end
end
function ptrPanelSwitchRecordVideo_SelectionChangedFcn(hObject, eventdata, handles)
	%% get selected button
	if ischar(hObject)
		strSelected = hObject;
	else
		strSelected = get(hObject,'String');
	end
	
	%% run external function
	ET_SwitchRecordVideo(strSelected);
end
function ptrPanelSwitchOnlineDetection_SelectionChangedFcn(hObject, eventdata, handles)
	%% get selected button
	if ischar(hObject)
		strSelected = hObject;
	else
		strSelected = get(hObject,'String');
	end
	
	%% run external function
	ET_SwitchOnlineDetection(strSelected);
end
function ptrButtonInvertPupilThreshold_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% globals
	global sET
	
	%% set inversion
	sET.boolInvertImage = hObject.Value;
end
function ptrButtonRotateImage_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% globals
	global sET
	
	%% set rotation
	sET.boolRotateImage = hObject.Value;
	
	%check if we rotate the image
	if sET.boolRotateImage == 1
		%video size
		sET.intMaxX = sET.intOrigY;
		sET.intMaxY = sET.intOrigX;
	else
		%video size
		sET.intMaxX = sET.intOrigX;
		sET.intMaxY = sET.intOrigY;
	end
	
	%% swap boxes
	sET.vecRectSync = sET.vecRectSync([2 1 4 3]);
	sET.vecRectROI = sET.vecRectROI([2 1 4 3]);
end
function ptrToggleConnectSGL_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	% hObject    handle to ptrToggleConnectSGL (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	%% get globals
	global sEyeFig;
	global sET;
	
	%% set string
	intConnect = get(sEyeFig.ptrToggleConnectSGL,'Value');
	if intConnect == 1
		%connect
		set(sEyeFig.ptrTextConnectedSGL,'String','Connecting','ForegroundColor',[0.3 0.3 0]);
		drawnow;
		
		%get host address
		strHost = get(sEyeFig.ptrEditHostAddress,'String');
		try
			%connect
			sET.hSGL = SpikeGL(strHost);
			%retrieve name & NI sampling rate
			sET.intStreamNI = -1;
			%sET.strRecordingNI = GetRunName(sET.hSGL);
			sET.dblSampFreqNI = GetSampleRate(sET.hSGL, sET.intStreamNI);
			%success
			boolSuccess = true;
		catch
			sET.hSGL = [];
			boolSuccess = false;
		end
		
		%set message
		if boolSuccess
			%connected
			set(sEyeFig.ptrTextConnectedSGL,'String','Linked','ForegroundColor',[0 0.8 0]);
			%set(sEyeFig.ptrTextRecordingNI,'String',sET.strRecordingNI,'ForegroundColor',[0 0 0]);
			ET_updateTextInformation('Connection to SpikeGLX established');
		else
			%connection failed
			set(sEyeFig.ptrToggleConnectSGL,'Value',0);
			%set(sEyeFig.ptrTextRecordingNI,'String','...','ForegroundColor',[0 0 0]);
			set(sEyeFig.ptrTextConnectedSGL,'String','Idle','ForegroundColor',[0 0 0]);
			ET_updateTextInformation('Connection failed; check host address');
		end
	else
		%disconnect
		ET_updateTextInformation('Disconnected from SpikeGLX');
		set(sEyeFig.ptrTextConnectedSGL,'String','Idle','ForegroundColor',[0 0 0]);
	end
end
function ptrEditHostAddress_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%update structure
	global sET;
	sET.strHostSGL = get(hObject,'String');
end
function ptrButtonAutoStart_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% globals
	global sET
	global sEyeFig
	
	%% set auto-start
	sET.boolAutoStart = sEyeFig.ptrButtonAutoStart.Value;
end

%% dummies
function ptrButtonDetectPupilOn_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonDetectPupilOff_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonRecordVidOn_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonRecordVidOff_Callback(hObject, eventdata, handles),end %#ok<DEFNU>

function ptrEditHostAddress_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditGamma_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrEditGain_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>



%% gain
function ptrEditGain_Callback(hObject, eventdata, handles)
	%update gain
	ET_setGain(str2double(get(hObject,'String')));
end
function ptrButtonGainPlus_Callback(hObject, eventdata, handles)
	%globals
	global sET;
	%update gain
	ET_setGain(sET.dblGain+0.5);
end
function ptrButtonGainMinus_Callback(hObject, eventdata, handles)
	%globals
	global sET;
	%update gain
	ET_setGain(sET.dblGain-0.5);
end

%% gamma
function ptrEditGamma_Callback(hObject, eventdata, handles)
	%update gamma
	ET_setGamma(str2double(get(hObject,'String')));
end
function ptrButtonGammaPlus_Callback(hObject, eventdata, handles)
	%globals
	global sET;
	%update gain
	ET_setGamma(sET.dblGamma+0.05);
end
function ptrButtonGammaMinus_Callback(hObject, eventdata, handles)
	%globals
	global sET;
	%update gain
	ET_setGamma(sET.dblGamma-0.05);
end
