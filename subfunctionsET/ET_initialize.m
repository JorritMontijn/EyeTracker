function [sEyeFig,sET] = ET_initialize(sEyeFig,sET)
	%OT_initialize initializes all fields when data paths are set
	global objCam
	%% initialize camera
	%set parameters
	intTriggerType = 1;
	
	%get devices
	sDevices = imaqhwinfo;
	
	%establish connection
	sCams = imaqhwinfo(sDevices.InstalledAdaptors{1});
	if isempty(sCams.DeviceIDs)
		cellText = {'No devices detected'};
		ET_updateTextInformation(cellText);
		return;
	end
	sChooseCam = imaqhwinfo(sDevices.InstalledAdaptors{1},1);
	objCam = eval(sChooseCam.VideoDeviceConstructor);%imaq.VideoDevice('gentl', 1)
	objVid = eval(sChooseCam.VideoInputConstructor);%videoinput('gentl', 1)
	
	%get cam properties
	if isprop(objCam.DeviceProperties,'ResultingFrameRate')
		dblRealFrameRate = objCam.DeviceProperties.ResultingFrameRate;
	else
		dblRealFrameRate = objCam.DeviceProperties.FrameRate;
	end
	if ischar(dblRealFrameRate)
		dblRealFrameRate = str2double(dblRealFrameRate);
	end
	
	%set trigger mode
	if intTriggerType == 1
		%set acquisition to be triggered manually form matlab
		triggerconfig(objVid,'immediate');
	elseif intTriggerType == 2
		%set acquisition to be triggered externally as ttl pulse to camera
		triggerconfig(objVid,'hardware','risingEdge','TTL');
	else
		
	end
	
	%set callback functions
	objVid.StartFcn = [];
	objVid.StopFcn = [];
	
	%set frames per trigger
	objVid.FramesPerTrigger = inf;
	
	%set disk logging to videowriter
	objVid.LoggingMode = 'memory';
	%video size
	sET.intOrigX = objCam.ROI(3); %video size x
	sET.intOrigY = objCam.ROI(4); %video size y
		
	%check if we rotate the image
	if sET.boolRotateImage
		%video size
		intMaxX = sET.intOrigY;
		intMaxY = sET.intOrigX;
	else
		%video size
		intMaxX = sET.intOrigX;
		intMaxY = sET.intOrigY;
	end
	%assign to global
	sET.intMaxX = intMaxX;
	sET.intMaxY = intMaxY;
	sET.sDevices = sDevices;
	sET.objCam = objCam;
	sET.objVid = objVid;
	sET.dblRealFrameRate = dblRealFrameRate;
	
	%% check GPU
	try
		gpuArray(true);
		boolUseGPU = true;
		objGPU = gpuDevice(1);
		strGPU = ['Using GPU-filtering on ' objGPU.Name];
	catch
		boolUseGPU = false;
		warning([mfilename ':CUDA_Error'],'Could not use gpuDevice; GPU-acceleration is disabled')
		strGPU = 'CUDA error: could not use gpuDevice!';
	end
	sET.boolUseGPU = boolUseGPU;
	
    %% set default output
    sET.strDirDataOut = strcat('C:\_Data\Exp',getDate());
    
	%% update figure controls to match data
	%set cam data
	set(sEyeFig.ptrListSelectAdaptor,'String',sDevices.InstalledAdaptors);
	set(sEyeFig.ptrListSelectDevice,'String',sChooseCam.DeviceName);
	set(sEyeFig.ptrTextCamFormat,'String',objCam.VideoFormat);
	set(sEyeFig.ptrTextCamVideoSize,'String',strcat(num2str(intMaxX),' x ',num2str(intMaxY),' (X by Y)'));
	set(sEyeFig.ptrTextCamFramerate,'String',sprintf('%.3f',dblRealFrameRate));
	
	%set pupil/sync ROI slider positions
	set(sEyeFig.ptrSliderPupilROIStartLocX,'Value',sET.vecRectROI(1)/intMaxX);
	set(sEyeFig.ptrSliderPupilROIStartLocY,'Value',sET.vecRectROI(2)/intMaxY);
	set(sEyeFig.ptrSliderPupilROIStopLocX,'Value',(sET.vecRectROI(3)+sET.vecRectROI(1))/intMaxX);
	set(sEyeFig.ptrSliderPupilROIStopLocY,'Value',(sET.vecRectROI(4)+sET.vecRectROI(2))/intMaxY);
	
	set(sEyeFig.ptrSliderSyncROIStartLocX,'Value',sET.vecRectSync(1)/intMaxX);
	set(sEyeFig.ptrSliderSyncROIStartLocY,'Value',sET.vecRectSync(2)/intMaxY);
	set(sEyeFig.ptrSliderSyncROIStopLocX,'Value',(sET.vecRectSync(3)+sET.vecRectSync(1))/intMaxX);
	set(sEyeFig.ptrSliderSyncROIStopLocY,'Value',(sET.vecRectSync(4)+sET.vecRectSync(2))/intMaxY);
	
	%set pupil detection settings
	set(sEyeFig.ptrEditTempAvg,'String',num2str(sET.intTempAvg));
	set(sEyeFig.ptrEditBlurWidth,'String',sprintf('%.1f',sET.dblGaussWidth));
	set(sEyeFig.ptrEditMinRadius,'String',sprintf('%.1f',sET.dblPupilMinRadius));
	set(sEyeFig.ptrEditReflectLum,'String',num2str(sET.dblThreshReflect));
	set(sEyeFig.ptrEditPupilLum,'String',num2str(sET.dblThreshPupil));
	set(sEyeFig.ptrEditSyncLum,'String',num2str(sET.dblThreshSync));
	set(sEyeFig.ptrButtonInvertPupilThreshold,'Value',sET.boolInvertImage);
	set(sEyeFig.ptrButtonRotateImage,'Value',sET.boolRotateImage);
	
	%SGL host address
	set(sEyeFig.ptrEditHostAddress,'String',sET.strHostSGL);
	
	%% finalize and set msg
	cellText = {'Eye Tracker initialized!',strGPU};
	ET_updateTextInformation(cellText);
end

