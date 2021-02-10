%% starting function
function varargout = runEyeTracker(varargin)
	% runEyeTracker Acquire eye-tracking video while performing online
	% pupil detection with GUI
	%
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
	%	- to do: manual gain control of camera
	
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
	
	% set timer to query whether there is a data update every second
	objTimer = timer();
	objTimer.Period = 1;
	objTimer.StartDelay = 1;
	objTimer.ExecutionMode = 'fixedSpacing';
	objTimer.TimerFcn = @ET_timer;
	sEyeFig.objTimer = objTimer;
	%start(objTimer);
	
	% Update handles structure
	guidata(hObject, handles);
	
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
	%% globals
	global sET;
	global sEyeFig;
	
	%% set video writer
	%create videowriter object to save video using MPEG-4
	cellVidFormats = {'Motion JPEG AVI','Motion JPEG 2000','MPEG-4'};
	cellVidExtensions = {'.avi','.mj2','.mp4'};
	intUseFormat = 3;
	
	% get file location
	%switch path
	try
		if ~exist(sET.strDirDataOut,'dir')
			mkdir(sET.strDirDataOut);
		end
		oldPath = cd(sET.strDirDataOut);
	catch
		oldPath = cd();
	end
	
	%get file
	[strRecFile, strRecPath] = uiputfile(cellVidExtensions{intUseFormat}, sprintf('Save Video As (*.%s)',cellVidExtensions{intUseFormat}),strcat('EyeTrackingRaw',getDate,'_R'));
	
	%back to old path
	cd(oldPath);
	
	%check if output is okay
	if isempty(strRecFile) || ~ischar(strRecFile)
		return;
	end
	
	%check if previous video file exists and close it
	if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Filename') && ~isempty(sET.objVidWriter.Filename)
		close(sET.objVidWriter);
	end
	
	%save video writer data
	objVidWriter = VideoWriter(strcat(strRecPath,strRecFile), cellVidFormats{intUseFormat});
	objVidWriter.FrameRate = sET.dblRealFrameRate;
	sET.objVidWriter = objVidWriter;
	
	%switch raw video recording to on
	ptrPanelSwitchRecordVideo_SelectionChangedFcn('On');
	ptrPanelSwitchOnlineDetection_SelectionChangedFcn('On');
	
	%enable recording button
	set(sEyeFig.ptrToggleRecord,'Enable','on');
	
	%% update text
	set(sEyeFig.ptrTextVidOutFile,'String',objVidWriter.Filename);
	set(sEyeFig.ptrTextVidOutPath,'String',objVidWriter.Path);
end
function ptrEditTempAvg_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%% get globals
	global sET;
	
	%% set value
	%get value
	intVal = round(str2double(get(hObject,'String')));
	%set to within bounds
	sET.intTempAvg = max([min([intVal 10]) 1]); %range: 1-10
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
			%set recording text
			set(sEyeFig.ptrTextRecording,'String','Recording','ForegroundColor',[0 0.8 0]);
			%lock gui
			ET_lock(handles);
			set(sEyeFig.ptrToggleConnectSGL,'Enable','off');
			sET.boolRecording = true;
			sET.intSyncPulse = 0; %reset sync pulses
			sET.dblRecStart = str2double(get(sEyeFig.ptrTextVidTime,'String')); %reset recording start
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
		delete(sEyeFig.ptrMainGUI);
	end
end
function ptrPanelSwitchRecordVideo_SelectionChangedFcn(hObject, eventdata, handles)
	%% globals
	global sET
	global sEyeFig
	
	%get selected button
	if ischar(hObject)
		strSelected = hObject;
	else
		strSelected = get(hObject,'String');
	end
	
	%% update switch
	if strcmpi(strSelected,'On')
		if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Filename') && ~isempty(sET.objVidWriter.Filename)
			sET.boolSaveToDisk = true;
			open(sET.objVidWriter);
			set(sEyeFig.ptrButtonRecordVidOn,'Value',1);
		else
			set(sEyeFig.ptrButtonRecordVidOff,'Value',1);
		end
	elseif strcmpi(strSelected,'Off')
		sET.boolSaveToDisk = false;
		set(sEyeFig.ptrButtonRecordVidOff,'Value',1);
		close(sET.objVidWriter);
	end
end
function ptrPanelSwitchOnlineDetection_SelectionChangedFcn(hObject, eventdata, handles)
	%% globals
	global sET;
	global sEyeFig;
	
	%get selected button
	if ischar(hObject)
		strSelected = hObject;
	else
		strSelected = get(hObject,'String');
	end
	
	%% update switch
	if strcmpi(strSelected,'On')
		set(sEyeFig.ptrButtonDetectPupilOn,'Value',1);
		sET.boolDetectPupil = true;
		%check if an output file has been defined
		if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Filename') && ~isempty(sET.objVidWriter.Filename)
			%build filename
			strFile = sET.objVidWriter.Filename;
			cellFile = strsplit(strFile,'.');
			strNoExt = strjoin(cellFile(1:(end-1)),'.');
			sET.strDataOutFile = strcat(strNoExt,'.csv');
			sET.strDataOutPath = sET.objVidWriter.Path;
			
			%open file
			if ~isfield(sET,'ptrDataOut')
				sET.ptrDataOut = fopen(strcat(sET.strDataOutPath,filesep,sET.strDataOutFile),'wt+');
				%write variable names
				strData = '"Time","VidFrame","SyncLum","SyncPulse","CenterX","CenterY","MajorAx","MinorAx","Orient","Eccentric","Roundness","FrameNI","SecsNI"';
				strData = strcat(strData,'\n');
				fprintf(sET.ptrDataOut,strData);
			else
				try,fclose(sET.ptrDataOut);catch,end %try to close, just in case
				sET.ptrDataOut = fopen(strcat(sET.strDataOutPath,filesep,sET.strDataOutFile),'at+');
			end
		end
	elseif strcmpi(strSelected,'Off')
		set(sEyeFig.ptrButtonDetectPupilOff,'Value',1);
		sET.boolDetectPupil = false;
		%close file
		if isfield(sET,'ptrDataOut') && ftell(sET.ptrDataOut) >= 0
			fclose(sET.ptrDataOut);
		end
	end
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
	intConnect = get(hObject,'Value');
	if intConnect == 1
		%connect
		set(sEyeFig.ptrTextConnectedSGL,'String','Connecting','ForegroundColor',[0 0 0]);
		drawnow;
		
		%get host address
		strHost = get(sEyeFig.ptrEditHostAddress,'String');
		try
			%connect
			sET.hSGL = SpikeGL(strHost);
			%retrieve name & NI sampling rate
			sET.intStreamNI = -1;
			sET.strRecordingNI = GetRunName(sET.hSGL);
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
			set(sEyeFig.ptrTextConnectedSGL,'String','Linked','ForegroundColor',[0 0 0]);
			set(sEyeFig.ptrTextRecordingNI,'String',sET.strRecordingNI,'ForegroundColor',[0 0 0]);
			ET_updateTextInformation('Connection to SpikeGLX established');
		else
			%connection failed
			set(hObject,'Value',0);
			set(sEyeFig.ptrTextRecordingNI,'String','...','ForegroundColor',[0 0 0]);
			set(sEyeFig.ptrTextConnectedSGL,'String','Available','ForegroundColor',[0 0 0]);
			ET_updateTextInformation('Connection failed; check host address');
		end
	else
		%disconnect
		ET_updateTextInformation('Disconnected from SpikeGLX');
		set(sEyeFig.ptrTextConnectedSGL,'String','Available','ForegroundColor',[0 0 0]);
	end
end
function ptrEditHostAddress_Callback(hObject, eventdata, handles) %#ok<DEFNU>
	%update structure
	global sET;
	sET.strHostSGL = get(hObject,'String');
end
%% dummies
function ptrButtonDetectPupilOn_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonDetectPupilOff_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonRecordVidOn_Callback(hObject, eventdata, handles),end %#ok<DEFNU>
function ptrButtonRecordVidOff_Callback(hObject, eventdata, handles),end %#ok<DEFNU>

function ptrEditHostAddress_CreateFcn(hObject, eventdata, handles),end %#ok<DEFNU>
