function [sTrackParams,sLabels] = getEyeTrackingParameters(sFile,strTempPath,boolAutoRun,boolOnlyLabels)
	%getEyeTrackingParameters Run offline pupil detection parameter setter
	%   sTrackParams = getEyeTrackingParameters(sFile)
	
	%sFile=sETO.sFiles(intFile);
	%strTempPath=sETO.strTempPath;
	
	%% globals
	global sFigETP;
	global sETP;
	global ETP_sLabels;
	sFigETP = [];
	sETP = [];
	ETP_sLabels = [];
	
	%% unpack inputs
	strPath = sFile.folder;
	strVideoFile = sFile.name;
	if ~exist('boolAutoRun','var') || isempty(boolAutoRun)
		boolAutoRun = false;
	end
	sFigETP.boolAutoRun = boolAutoRun;
	if ~exist('boolOnlyLabels','var') || isempty(boolOnlyLabels)
		boolOnlyLabels = false;
	end
	sFigETP.boolOnlyLabels = boolOnlyLabels;
	
	%% load data
	sETP = ET_populateStructure([]);
	if isfield(sFile,'sTrackParams') && isfield(sFile.sTrackParams,'sET') && ~isempty(sFile.sTrackParams.sET)
		sET = sFile.sTrackParams.sET;
	else
		if isfield(sFile,'sParams') && isfield(sFile.sParams,'sET')
			sET = sFile.sParams.sET;
		end
		sET.dblGain = 1;
		sET.dblGamma = 1;
		sET.boolInvertImage = 0;
		sET.boolRotateImage = 0;
	end
	if isfield(sFile,'sSync') && isfield(sFile.sSync,'sSyncData')
		sSyncData = sFile.sSync.sSyncData;
	else
		sSyncData = [];
	end
	if isfield(sFile,'sLabels') && isfield(sFile.sLabels,'T')
		ETP_sLabels = sFile.sLabels;
	end
	sETP = catstruct(sETP,sET);
	sETP.gMatFilt = [];
	sETP.strTempPath = strTempPath;
	sETP.strPath = strPath;
	sETP.strVideoFile = strVideoFile;
	sETP.boolAccept = false;
	
	try
		%% build GUI master parameters
		dblHeight = 600;
		dblWidth = 1000;
		vecMainColor = [0.97 0.97 0.97];
		%vecLocText = [0.02 0.96 0.4 0.1];
		dblPanelStartX = 0.01;
		dblPanelWidth = 0.44;
		vecPosGUI = [0,0,dblWidth,dblHeight];
		ptrMainGUI = figure('Visible','on','Units','pixels','Position',vecPosGUI,'Color',vecMainColor);
		set(ptrMainGUI,'DeleteFcn','ETP_DeleteFcn')
		set(ptrMainGUI, 'MenuBar', 'none','ToolBar', 'none','NumberTitle','off');
		ptrMainGUI.Name = 'Parameter Setter';
		
		%set output
		sFigETP.output = ptrMainGUI;
		sETP.boolForceQuit = false;
		
		% Move the window to the center of the screen.
		movegui(ptrMainGUI,'center');
		
		%% check GPU
		try
			gTest = gpuArray(eye(10));
			sETP.boolUseGPU = true;
			delete(gTest);
		catch
			sETP.boolUseGPU = false;
		end
		
		%% access video
		if sFigETP.boolAutoRun
			strAnswer = 'Yes';
		else
			strAnswer = [];
		end
		strVidFile = ETP_prepareMovie(strPath,strVideoFile,strTempPath,strAnswer);
		sETP.objVid = VideoReader(strVidFile);
		
		%% data import/export
		vecLocation = [dblPanelStartX 0.01 dblPanelWidth 0.1];
		ptrPanelDatimex = ETP_genDataPanel(ptrMainGUI,vecLocation);
		ptrPanelDatimex.Units = 'pixels';
		sFigETP.ptrPanelDatimex = ptrPanelDatimex;
		
		%% video
		%main
		dblVidStartX = dblPanelStartX*2+dblPanelWidth;
		dblVidWidth = 1-dblVidStartX;
		vecLocVid = [dblVidStartX 0.4 dblVidWidth 0.6];
		sFigETP.ptrAxesMainVid = axes(ptrMainGUI,'Position',vecLocVid,'Units','normalized');
		axis(sFigETP.ptrAxesMainVid,'off');
		sFigETP.intCurFrame = 1;
		
		%sub1
		vecLocVid1 = [dblVidStartX 0 dblVidWidth/2 vecLocVid(2)];
		sFigETP.ptrAxesSubVid1 = axes(ptrMainGUI,'Position',vecLocVid1,'Units','normalized');
		axis(sFigETP.ptrAxesSubVid1,'off');
		
		%sub2
		vecLocVid2 = [vecLocVid1(1)+vecLocVid1(3) 0 1-(vecLocVid1(1)+vecLocVid1(3)) vecLocVid(2)];
		sFigETP.ptrAxesSubVid2 = axes(ptrMainGUI,'Position',vecLocVid2,'Units','normalized');
		axis(sFigETP.ptrAxesSubVid2,'off');
		
		%gpu acceleration
		try
			gpuArray(true);
			boolUseGPU = true;
			objGPU = gpuDevice(1);
			strGPU = ['GPU-acceleration on ' objGPU.Name];
		catch
			boolUseGPU = false;
			strGPU = 'CUDA test failed: will not use gpu acceleration.';
		end
		sETP.boolUseGPU = boolUseGPU;
		
		vecLocText = [20 dblHeight-30 400 20];
		sFigETP.ptrTextVersion = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Position',vecLocText,...
			'String',strGPU);
		
		%file name
		vecLocText1 = vecLocText - [0 vecLocText(4)+10 0 0];
		sFigETP.ptrTextRoot = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Position',vecLocText1,...
			'String',sprintf('File: %s',sFile.name));
		
		%recording
		if isfield(sETP,'strRecordingNI')
			strRec = sETP.strRecordingNI;%: 'RecMA7_2021-02-11R01'
		else
			strRec = 'N/A';
		end
		vecLocText2 = vecLocText1 - [0 vecLocText1(4) 0 0];
		sFigETP.ptrTextRec = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Position',vecLocText2,...
			'String',sprintf('Rec: %s',strRec));
		
		%% create rect vectors & draw image
		if any(sETP.vecRectSync > 1) || any(sETP.vecRectROI > 1)
			sETP.vecRectSync([1 3]) = sETP.vecRectSync([1 3])./sETP.intX;
			sETP.vecRectSync([2 4]) = sETP.vecRectSync([2 4])./sETP.intY;
			sETP.vecRectROI([1 3]) = sETP.vecRectROI([1 3])./sETP.intX;
			sETP.vecRectROI([2 4]) = sETP.vecRectROI([2 4])./sETP.intY;
		end
		
		%% slider panels
		%X: start / stop
		%Y: start / stop
		vecLocation = [dblPanelStartX 0.65 dblPanelWidth 0.2];
		[ptrPanelP,ptrSliderLTP,ptrSliderRTP,ptrSliderLBP,ptrSliderRBP] = ETP_genQuadSliders(ptrMainGUI,vecLocation,'Pupil ROI');
		ptrSliderLTP.Value = sETP.vecRectROI(1);
		ptrSliderLBP.Value = sETP.vecRectROI(2);
		ptrSliderRTP.Value = sETP.vecRectROI(1)+sETP.vecRectROI(3);
		ptrSliderRBP.Value = sETP.vecRectROI(2)+sETP.vecRectROI(4);
		ptrPanelP.Units = 'pixels';
		sFigETP.ptrPanelP = ptrPanelP;
		sFigETP.ptrSliderLTP = ptrSliderLTP;
		sFigETP.ptrSliderLBP = ptrSliderLBP;
		sFigETP.ptrSliderRTP = ptrSliderRTP;
		sFigETP.ptrSliderRBP = ptrSliderRBP;
		
		%sync ROI
		%X: start / stop
		%Y: start / stop
		vecLocation = [dblPanelStartX 0.44 dblPanelWidth 0.2];
		[ptrPanelS,hSLTS,hSRTS,hSLBS,hSRBS] = ETP_genQuadSliders(ptrMainGUI,vecLocation,'Sync ROI');
		hSLTS.Value = sETP.vecRectSync(1);
		hSLBS.Value = sETP.vecRectSync(2);
		hSRTS.Value = sETP.vecRectSync(1)+sETP.vecRectSync(3);
		hSRBS.Value = sETP.vecRectSync(2)+sETP.vecRectSync(4);
		ptrPanelS.Units = 'pixels';
		sFigETP.ptrPanelS = ptrPanelS;
		
		%% detection settings
		%gain / gamma
		%temp avg / blur width / min radius
		%reflect lum / pupil lum
		vecLocation = [dblPanelStartX 0.23 dblPanelWidth 0.2];
		[ptrPanelD,sHandles] = ETP_genDetectPanel(ptrMainGUI,vecLocation,'Detection settings',sET);
		ptrPanelD.Units = 'pixels';
		sFigETP.sHandles = sHandles;
		sFigETP.ptrPanelD = ptrPanelD;
		
		%% movie slider through frames
		vecLocation = [dblPanelStartX 0.12 dblPanelWidth 0.1];
		fCallback = @ETP_GetCurrentFrame;
		[ptrPanelM,ptrSliderFrame,ptrEditFrame] = ETP_genMovieSlider(ptrMainGUI,vecLocation,sETP,sFigETP,fCallback);
		ptrPanelM.Units = 'pixels';
		sFigETP.ptrPanelM = ptrPanelM;
		sFigETP.ptrSliderFrame = ptrSliderFrame;
		sFigETP.ptrEditFrame = ptrEditFrame;
		
		%% run initial pass
		ETP_DetectEdit();
		
		%% check if only labelling is enabled
		if boolOnlyLabels
			%set labels
			ETP_sLabels = ETP_SetLabels();
			%quit
			ETP_DeleteFcn;
		end
		
		%% check if autorun is enabled
		if boolAutoRun
			%run auto detection
			ETP_AutoSettings();
			
			%accept parameters
			ETP_AcceptParameters();
		end
		
		%% wait until user accepts settings
		while ~sETP.boolAccept && ~sETP.boolForceQuit
			pause(0.01);
		end
	catch ME
		dispErr(ME);
	end
	
	%% save data
	if ~sETP.boolAccept
		sTrackParams = [];
	else
		sTrackParams = sETP.sTrackParams;
	end
	sLabels = ETP_sLabels;
	ETP_DeleteFcn;
	%end
	
