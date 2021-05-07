function sTrackParams = getEyeTrackingParameters(sFile)
	%getEyeTrackingParameters Run offline pupil detection parameter setter
	%   sTrackParams = getEyeTrackingParameters(sFile)
	
	%% globals
	clearvars -except sFile;
	global sFigETP;
	global sETP;
	sFigETP = [];
	sETP = [];
	
	%% unpack inputs
	strPath = sFile.folder;
	strVideoFile = sFile.name;
	
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
	sETP = catstruct(sETP,sET);
	sETP.gMatFilt = [];
	
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
	%set(ptrMainGUI, 'MenuBar', 'none');
	%set(ptrMainGUI, 'ToolBar', 'none');
	
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
	strVidFile = fullfile(strPath,strVideoFile);
	sETP.objVid = VideoReader(strVidFile);
	
	%% data import/export
	vecLocation = [dblPanelStartX 0.01 dblPanelWidth 0.1];
	hPanelDatimex = ETP_genDataPanel(ptrMainGUI,vecLocation);
	hPanelDatimex.Units = 'pixels';
	
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
					
	%file name
	vecLocText = [20 dblHeight-40 400 20];
	sFigETP.ptrTextRoot = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Position',vecLocText,...
		'String',sprintf('File: %s',sFile.name));
	
	%recording
	if isfield(sETP,'strRecordingNI')
		strRec = sETP.strRecordingNI;%: 'RecMA7_2021-02-11R01'
	else
		strRec = 'N/A';
	end
	vecLocText2 = vecLocText - [0 vecLocText(4) 0 0];
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
	[hPanelP,hSLTP,hSRTP,hSLBP,hSRBP] = ETP_genQuadSliders(ptrMainGUI,vecLocation,'Pupil ROI');
	hSLTP.Value = sETP.vecRectROI(1);
	hSLBP.Value = sETP.vecRectROI(2);
	hSRTP.Value = sETP.vecRectROI(1)+sETP.vecRectROI(3);
	hSRBP.Value = sETP.vecRectROI(2)+sETP.vecRectROI(4);
	hPanelP.Units = 'pixels';
	
	%sync ROI
	%X: start / stop
	%Y: start / stop
	vecLocation = [dblPanelStartX 0.44 dblPanelWidth 0.2];
	[hPanelS,hSLTS,hSRTS,hSLBS,hSRBS] = ETP_genQuadSliders(ptrMainGUI,vecLocation,'Sync ROI');
	hSLTS.Value = sETP.vecRectSync(1);
	hSLBS.Value = sETP.vecRectSync(2);
	hSRTS.Value = sETP.vecRectSync(1)+sETP.vecRectSync(3);
	hSRBS.Value = sETP.vecRectSync(2)+sETP.vecRectSync(4);
	hPanelS.Units = 'pixels';
	
	%% detection settings
	%gain / gamma
	%temp avg / blur width / min radius
	%reflect lum / pupil lum
	vecLocation = [dblPanelStartX 0.23 dblPanelWidth 0.2];
	[hPanelD,sHandles] = ETP_genDetectPanel(ptrMainGUI,vecLocation,'Detection settings',sET);
	hPanelD.Units = 'pixels';
	sFigETP.sHandles = sHandles;
	
	%% movie slider through frames
	vecLocation = [dblPanelStartX 0.12 dblPanelWidth 0.1];
	[hPanelM,ptrSliderFrame,ptrEditFrame] = ETP_genMovieSlider(ptrMainGUI,vecLocation);
	hPanelM.Units = 'pixels';
	
	%% run initial pass
	ETP_DetectEdit();
	
	%% wait until user accepts settings
	sETP.boolAccept = false;
	while ~sETP.boolAccept && ~sETP.boolForceQuit
		pause(0.01);
	end
	
	%% save data
	if sETP.boolAccept
		%delete video data
		sETP = rmfield(sETP,{'objVid','matFrames'});
		
		%save file
		sET = sETP;
		
		%remove extension & build new name
		cellFile = strsplit(sFile.name,'.');
		strFileCore = strjoin(cellFile(1:end-1),'.');
		strName = [strFileCore 'TrackParams.mat'];
		strFolder = sFile.folder;
		save(fullfile(strFolder,strName),'sET');
		
		%compile structure
		sTrackParams = struct;
		sTrackParams.name = strName;
		sTrackParams.folder = strFolder;
		sTrackParams.sET = sET;
	else
		sTrackParams = [];
	end
	ETP_DeleteFcn;
%end

