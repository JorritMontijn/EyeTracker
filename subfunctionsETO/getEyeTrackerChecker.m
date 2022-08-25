function sFile = getEyeTrackerChecker(sFile,strTempPath)
	%getEyeTrackerChecker Check eye-tracking quality
	%   sFile = getEyeTrackerChecker(sFile,strTempPath)
	
	%% globals
	global sFigETC;
	global sETC;
	sFigETC = [];
	sETC = [];
	
	%% find minivid
	strMiniVidFile = sFile.sPupil.sPupil.strMiniVidFile;
	strMiniVidPath = sFile.sPupil.sPupil.strMiniVidPath;
	[dummy,strMiniFile,strExt]=fileparts(strMiniVidFile);
	strMiniVidFile = [];
	cellUseExt = {'.mp4','.avi','.mj2'};
	cellUseExt{end+1}=strExt;
	cellUseExt = unique(cellUseExt);
	for intExt=1:numel(cellUseExt)
		strUseExt = cellUseExt{intExt};
		if exist([strMiniVidPath strMiniFile strUseExt],'file')
			strMiniVidFile = [strMiniFile strUseExt];
			strMiniVidPath = strMiniVidPath;
		elseif exist(fullfile(sFile.folder,[strMiniFile strUseExt]),'file')
			strMiniVidFile = [strMiniFile strUseExt];
			strMiniVidPath = sFile.folder;
		elseif exist(fullfile(strTempPath,[strMiniFile strUseExt]),'file')
			strMiniVidFile = [strMiniFile strUseExt];
			strMiniVidPath = strTempPath;
		elseif exist(fullfile(sFile.sPupil.folder,[strMiniFile strUseExt]),'file')
			strMiniVidFile = [strMiniFile strUseExt];
			strMiniVidPath = sFile.sPupil.folder;
		end
	end
	if isempty(strMiniVidFile)
		error([mfilename ':CannotFindMiniVid'],'Could not find mini vid file');
	end
	
	%% load tracking data
	sFigETC.sPupil = sFile.sPupil.sPupil;
	sFigETC.sPupil.strProcFile = sFile.sPupil.name;
	sFigETC.sPupil.strProcPath = sFile.sPupil.folder;
	if isfield(sFigETC.sPupil,'sEpochs') && isstruct(sFigETC.sPupil.sEpochs)
		sFigETC.sOldEpochs = sFigETC.sPupil.sEpochs;
	else
		sFigETC.sOldEpochs = ETC_GenEmptyEpochs();
	end
	sTrackParams = sFile.sParams.sET;
	sETC.dblGaussWidth = sTrackParams.dblGaussWidth;
	sETC.dblThreshReflect = sTrackParams.dblThreshReflect;
	sETC.dblThreshPupil = sTrackParams.dblThreshPupil;
	sETC.dblPupilMinRadius = sTrackParams.dblPupilMinRadius;
	sETC.dblStrEl = sTrackParams.dblStrEl;
	
	%prep derived parameters
	sETC.boolInvertImage = false;
	intRadStrEl = round(sETC.dblStrEl);
	vecChoose=[4 6 8];
	[dummy,intChooseIdx]=min(abs(vecChoose-intRadStrEl*2));
	intN = vecChoose(intChooseIdx);
	objSE = strel('disk',intRadStrEl,intN);
	sETC.objSE = objSE;
	
	try
		%% build GUI master parameters
		dblHeight = 720;
		dblWidth = 1280;
		vecMainColor = [0.97 0.97 0.97];
		%vecLocText = [0.02 0.96 0.4 0.1];
		dblPanelStartX = 0.01;
		dblPanelWidth = 0.44;
		vecPosGUI = [0,0,dblWidth,dblHeight];
		ptrMainGUI = figure('Visible','on','Units','pixels','Position',vecPosGUI,'Color',vecMainColor);
		set(ptrMainGUI,'CloseRequestFcn','ETC_DeleteFcn')
		set(ptrMainGUI, 'MenuBar', 'none','ToolBar', 'none');
		ptrMainGUI.Name = 'Tracker Checker';
		
		%set output
		sFigETC.output = ptrMainGUI;
		sETC.boolForceQuit = false;
		
		% Move the window to the center of the screen.
		movegui(ptrMainGUI,'center');
		
		%% message
		ptrMsg = dialog('Position',[600 400 250 50],'Name','Starting GUI');
		ptrText = uicontrol('Parent',ptrMsg,...
			'Style','text',...
			'Position',[20 00 210 40],...
			'FontSize',11,...
			'String',sprintf('Initializing...'));
		movegui(ptrMsg,'center')
		drawnow;
		
		%% access video
		ptrText.String = 'Accessing mini vid...';drawnow;
		strVidFile = ETP_prepareMovie(strMiniVidPath,strMiniVidFile,strTempPath);
		sETC.objVid = VideoReader(strVidFile);
		sFigETC.intCurFrame = 1;
		sFigETC.boolNormIm = true;
		
		%get data
		intTotFrames = sETC.objVid.NumberOfFrames;
		matFrame = read(sETC.objVid,1);
		
		%import frames
		[intY,intX,intC] = size(matFrame);
		sETC.intY = intY;
		sETC.intX = intX;
		sETC.intC = intC;
		sETC.intF = intTotFrames;
		
		%% video
		ptrText.String = 'Testing GPU...';drawnow;
		%main
		dblVidStartX = dblPanelStartX*2+dblPanelWidth;
		dblVidWidth = 1-dblVidStartX;
		vecLocVid = [dblVidStartX 0.4 dblVidWidth 0.7];
		sFigETC.ptrAxesMainVid = axes(ptrMainGUI,'Position',vecLocVid,'Units','normalized');
		axis(sFigETC.ptrAxesMainVid,'off');
		
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
		sETC.boolUseGPU = boolUseGPU;
		
		%blur width
		if sETC.dblGaussWidth == 0
			if sETC.boolUseGPU
				sETC.gMatFilt = gpuArray(single(1));
			else
				sETC.gMatFilt = single(1);
			end
		else
			intGaussSize = ceil(sETC.dblGaussWidth*2);
			vecFilt = normpdf(-intGaussSize:intGaussSize,0,sETC.dblGaussWidth);
			matFilt = vecFilt' * vecFilt;
			matFilt = matFilt / sum(matFilt(:));
			if sETC.boolUseGPU
				sETC.gMatFilt = gpuArray(single(matFilt));
			else
				sETC.gMatFilt = single(matFilt);
			end
		end
		
		vecLocText = [20 dblHeight-30 400 20];
		sFigETC.ptrTextVersion = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Position',vecLocText,...
			'String',strGPU);
		sFigETC.ptrTextVersion.Units = 'normalized';
		
		%help button
		vecLocButtonHelp = [vecLocText(1)+vecLocText(3)+20 vecLocText(2)-2 60 25];
		sFigETC.ptrButtonHelp = uicontrol(ptrMainGUI,'Style','pushbutton','Position',vecLocButtonHelp,'String','Help','Callback',@ETC_DisplayHelp,'FontSize',10);
		sFigETC.ptrButtonHelp.Units = 'normalized';
		
		%file name
		vecLocText1 = vecLocText - [0 vecLocText(4)+10 0 0];
		sFigETC.ptrTextRoot = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Position',vecLocText1,...
			'String',sprintf('File: %s',sFile.name));
		sFigETC.ptrTextRoot.Units = 'normalized';
		
		%recording
		if isfield(sFigETC.sPupil.sTrackParams,'strRecordingNI') && ~isempty(sFigETC.sPupil.sTrackParams.strRecordingNI)
			strRec = sFigETC.sPupil.sTrackParams.strRecordingNI;%: 'RecMA7_2021-02-11R01'
		else
			strRec = 'N/A';
		end
		vecLocText2 = vecLocText1 - [0 vecLocText1(4) 0 0];
		sFigETC.ptrTextRec = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Position',vecLocText2,...
			'String',sprintf('Rec: %s',strRec));
		sFigETC.ptrTextRec.Units = 'normalized';
		
		
		%% movie slider through frames
		ptrText.String = 'Generating GUI...';drawnow;
		vecLocationSlider = [dblPanelStartX 0 dblPanelWidth 0.06];
		fCallback = @ETC_GetCurrentFrame;
		[ptrPanelM,ptrSliderFrame,ptrEditFrame] = ETP_genMovieSlider(ptrMainGUI,vecLocationSlider,sETC,sFigETC,fCallback);
		sFigETC.ptrPanelM = ptrPanelM;
		sFigETC.ptrSliderFrame = ptrSliderFrame;
		sFigETC.ptrEditFrame = ptrEditFrame;
		%add click/scroll callbacks
		set(ptrMainGUI,'windowscrollWheelFcn',{fCallback,'Scroll'});
		
		%% time and norm
		%norm
		dblBarH = 0.03;
		vecLocationNormCheckTxt = [dblPanelStartX vecLocationSlider(2)+vecLocationSlider(4)+0.01 0.11 dblBarH];
		uitext('Parent',ptrMainGUI,...
			'Units','normalized','Position',vecLocationNormCheckTxt,...
			'HorizontalAlignment','Left','String','Normalize image:');
		vecLocationNormCheck = [vecLocationNormCheckTxt(1)+vecLocationNormCheckTxt(3) vecLocationNormCheckTxt(2)-0.005 0.03 dblBarH];
		sFigETC.ptrImNorm = uicontrol('Parent',ptrMainGUI,...
			'Style','checkbox','Units','normalized','Position',vecLocationNormCheck,...
			'Value',1,'BackgroundColor',vecMainColor,'Callback',@ETC_redraw,'UserData','open');
		
		%load
		vecLocPreload = [vecLocationNormCheck(1)+vecLocationNormCheck(3)+0.01 vecLocationNormCheck(2)-0.01 0.1 dblBarH+0.01];
		sFigETC.ptrButtonPreload = uicontrol('Parent',ptrMainGUI,...
			'Style','togglebutton','Units','normalized','Position',vecLocPreload,...
			'FontSize',10,'String','Preload movie','BackgroundColor',vecMainColor,'Callback',@ETC_preload,'UserData','open');
		
		%time
		dblTimeW = 0.07;
		dblTimeTxtW = 0.05;
		vecLocTime = [(dblPanelStartX+dblPanelWidth)-dblTimeW vecLocationNormCheckTxt(2) dblTimeW vecLocationNormCheckTxt(4)];
		vecLocTimeTxt = [vecLocTime(1)-dblTimeTxtW-0.01 vecLocationNormCheckTxt(2) dblTimeTxtW vecLocTime(4)];
		uitext('Parent',ptrMainGUI,...
			'Units','normalized','Position',vecLocTimeTxt,...
			'HorizontalAlignment','Left','String','Time (s):');
		sH = uitext('Parent',ptrMainGUI,...
			'Units','normalized','Position',vecLocTime,...
			'String',sprintf('%.3f',0));
		sFigETC.ptrTextTime = sH.txt;
		
		%% sync lum bottom left
		%filter sync lum & blink
		dblLowPass = 0.01/(1/median(diff(sFigETC.sPupil.vecPupilTime)));
		[fb,fa] = butter(2,dblLowPass,'high');
		sFigETC.sPupil.vecPupilFiltSyncLum = zscore(filtfilt(fb,fa, sFigETC.sPupil.vecPupilSyncLum));
		sFigETC.sPupil.vecPupilFiltAbsVidLum = zscore(filtfilt(fb,fa, sFigETC.sPupil.vecPupilAbsVidLum));
		
		% plot
		dblLeftGap = 0.03;
		vecAxLimT = [min(sFigETC.sPupil.vecPupilTime) max(sFigETC.sPupil.vecPupilTime)];
		dblAxSH = 0.13;
		dblStartY = vecLocationNormCheckTxt(2)+vecLocationNormCheckTxt(4)+dblLeftGap*2;
		%vecLocationS = [dblVidStartX+dblLeftGap+0.01 vecLocVid(2)-dblAxSH-0.03 dblVidWidth-dblLeftGap*2 dblAxSH];
		vecLocationS = [dblPanelStartX+dblLeftGap dblStartY dblPanelWidth-dblLeftGap dblAxSH];
		
		sFigETC.ptrAxesS = axes(ptrMainGUI,'Position',vecLocationS,'Units','normalized');
		hLine=plot(sFigETC.ptrAxesS,sFigETC.sPupil.vecPupilTime,sFigETC.sPupil.vecPupilFiltSyncLum);
		hold(sFigETC.ptrAxesS,'on');
		ylabel(sFigETC.ptrAxesS,'Sync lum','FontSize',12);
		xlabel(sFigETC.ptrAxesS,'Time (s)','FontSize',12);
		grid(sFigETC.ptrAxesS,'on');
		xlim(sFigETC.ptrAxesS,vecAxLimT);
		set(sFigETC.ptrAxesS,'ButtonDownFcn',{fCallback,'Click'});
		set(hLine,'ButtonDownFcn',{fCallback,'Click'});
		
		%vecLocationVL = [dblVidStartX+dblLeftGap+0.01 vecLocationS(2)-dblAxSH-0.03 dblVidWidth-dblLeftGap*2 dblAxSH];
		vecLocationVL = vecLocationS + [0 vecLocationS(4)+0.01 0 0];
		sFigETC.ptrAxesVL = axes(ptrMainGUI,'Position',vecLocationVL,'Units','normalized');
		hLine=plot(sFigETC.ptrAxesVL,sFigETC.sPupil.vecPupilTime,sFigETC.sPupil.vecPupilFiltAbsVidLum);
		hold(sFigETC.ptrAxesVL,'on');
		ylabel(sFigETC.ptrAxesVL,'Vid lum.','FontSize',12);
		grid(sFigETC.ptrAxesVL,'on');
		set(sFigETC.ptrAxesVL,'xticklabel','');
		xlim(sFigETC.ptrAxesVL,vecAxLimT);
		set(sFigETC.ptrAxesVL,'ButtonDownFcn',{fCallback,'Click'});
		set(hLine,'ButtonDownFcn',{fCallback,'Click'});
		
		%scatters + txt
		dblT = sFigETC.sPupil.vecPupilTime(sFigETC.intCurFrame);
		dblS = sFigETC.sPupil.vecPupilFiltSyncLum(sFigETC.intCurFrame);
		dblVL = sFigETC.sPupil.vecPupilFiltAbsVidLum(sFigETC.intCurFrame);
		sFigETC.ptrScatterL = scatter(sFigETC.ptrAxesS,dblT,dblS,48,'b.','LineWidth',2);
		sFigETC.ptrScatterTxtL = text(sFigETC.ptrAxesS,dblT,dblS+range(sFigETC.ptrAxesS.YLim)/7,sprintf('L=%.3f',dblS));
		sFigETC.ptrScatterVL = scatter(sFigETC.ptrAxesVL,dblT,dblVL,48,'k.','LineWidth',2);
		sFigETC.ptrScatterTxtVL = text(sFigETC.ptrAxesVL,dblT,dblVL+range(sFigETC.ptrAxesVL.YLim)/7,sprintf('B=%.3f',dblVL));
		
		%% x,y,r
		%dblAxH = 0.17;
		%vecLocationR = [dblPanelStartX+dblLeftGap vecLocationNormCheckTxt(2)+vecLocationNormCheckTxt(4)+0.1 dblPanelWidth-dblLeftGap dblAxH];%[dblPanelStartX 0.12 dblPanelWidth 0.1];
		vecLocationR = vecLocationVL + [0 vecLocationVL(4)+0.01 0 0];
		sFigETC.ptrAxesR = axes(ptrMainGUI,'Position',vecLocationR,'Units','normalized');
		hLine=plot(sFigETC.ptrAxesR,sFigETC.sPupil.vecPupilTime,sFigETC.sPupil.vecPupilFixedRadius);
		hold(sFigETC.ptrAxesR,'on');
		ylabel(sFigETC.ptrAxesR,'Radius (pixels)','FontSize',12);
		grid(sFigETC.ptrAxesR,'on');
		xlim(sFigETC.ptrAxesR,vecAxLimT);
		set(sFigETC.ptrAxesR,'xticklabel','');
		set(sFigETC.ptrAxesR,'ButtonDownFcn',{fCallback,'Click'});
		set(hLine,'ButtonDownFcn',{fCallback,'Click'});
		
		%vecLocationY = [dblPanelStartX+dblLeftGap vecLocationR(2)+vecLocationR(4)+0.04 dblPanelWidth-dblLeftGap dblAxH];%[dblPanelStartX 0.12 dblPanelWidth 0.1];
		vecLocationY = vecLocationR + [0 vecLocationR(4)+0.01 0 0];
		sFigETC.ptrAxesY = axes(ptrMainGUI,'Position',vecLocationY,'Units','normalized');
		hLine=plot(sFigETC.ptrAxesY,sFigETC.sPupil.vecPupilTime,sFigETC.sPupil.vecPupilFixedCenterY);
		hold(sFigETC.ptrAxesY,'on');
		ylabel(sFigETC.ptrAxesY,'Y (pixels)','FontSize',12);
		grid(sFigETC.ptrAxesY,'on');
		xlim(sFigETC.ptrAxesY,vecAxLimT);
		set(sFigETC.ptrAxesY,'xticklabel','');
		set(sFigETC.ptrAxesY,'ButtonDownFcn',{fCallback,'Click'});
		set(hLine,'ButtonDownFcn',{fCallback,'Click'});
		
		%vecLocationX = [dblPanelStartX+dblLeftGap vecLocationY(2)+vecLocationY(4)+0.04 dblPanelWidth-dblLeftGap dblAxH];%[dblPanelStartX 0.12 dblPanelWidth 0.1];
		vecLocationX = vecLocationY + [0 vecLocationY(4)+0.01 0 0];
		sFigETC.ptrAxesX = axes(ptrMainGUI,'Position',vecLocationX,'Units','normalized');
		hLine=plot(sFigETC.ptrAxesX,sFigETC.sPupil.vecPupilTime,sFigETC.sPupil.vecPupilFixedCenterX);
		hold(sFigETC.ptrAxesX,'on');
		grid(sFigETC.ptrAxesX,'on');
		ylabel(sFigETC.ptrAxesX,'X (pixels)','FontSize',12);
		xlim(sFigETC.ptrAxesX,vecAxLimT);
		set(sFigETC.ptrAxesX,'XAxisLocation', 'top');
		set(sFigETC.ptrAxesX,'ButtonDownFcn',{fCallback,'Click'});
		set(hLine,'ButtonDownFcn',{fCallback,'Click'});
		
		%scatters + txt
		dblT = sFigETC.sPupil.vecPupilTime(sFigETC.intCurFrame);
		dblR = sFigETC.sPupil.vecPupilFixedRadius(sFigETC.intCurFrame);
		dblY = sFigETC.sPupil.vecPupilFixedCenterY(sFigETC.intCurFrame);
		dblX = sFigETC.sPupil.vecPupilFixedCenterX(sFigETC.intCurFrame);
		sFigETC.ptrScatterR = scatter(sFigETC.ptrAxesR,dblT,dblR,48,'k.','LineWidth',2);
		sFigETC.ptrScatterTxtR = text(sFigETC.ptrAxesR,dblT,dblR+range(sFigETC.ptrAxesR.YLim)/7,sprintf('R=%.3f',dblR));
		sFigETC.ptrScatterY = scatter(sFigETC.ptrAxesY,dblT,dblY,48,'b.','LineWidth',2);
		sFigETC.ptrScatterTxtY = text(sFigETC.ptrAxesY,dblT,dblY+range(sFigETC.ptrAxesY.YLim)/7,sprintf('Y=%.3f',dblY));
		sFigETC.ptrScatterX = scatter(sFigETC.ptrAxesX,dblT,dblX,48,'r.','LineWidth',2);
		sFigETC.ptrScatterTxtX = text(sFigETC.ptrAxesX,dblT,dblX+range(sFigETC.ptrAxesX.YLim)/7,sprintf('X=%.3f',dblX));
		
		%% epoch annotation
		vecLocationEpochAnnotation = [vecLocVid(1) 0 vecLocVid(3)/4 1-vecLocVid(4)];
		ETC_genEpochPanel(ptrMainGUI,vecLocationEpochAnnotation);
		
		%% zoomed-in plot
		dblZoomPlotH = (vecLocationEpochAnnotation(4)-0.06)/3;
		vecLocationZoomPlot1 = [vecLocationEpochAnnotation(1)+vecLocationEpochAnnotation(3)+0.02 0.045 vecLocVid(3)*(3/4)-0.04 dblZoomPlotH];
		ptrZoomPlot1 = axes(ptrMainGUI,'Position',vecLocationZoomPlot1);
		ylabel(ptrZoomPlot1,'Sync Lum','FontSize',10);
		xlabel(ptrZoomPlot1,'Time (s)','FontSize',10);
		set(ptrZoomPlot1,'ytick',[]);
		hold(ptrZoomPlot1,'on');
		grid(ptrZoomPlot1,'on');
		
		vecLocationZoomPlot2 = vecLocationZoomPlot1 + [0 vecLocationZoomPlot1(4)+0.005 0 0];
		ptrZoomPlot2 = axes(ptrMainGUI,'Position',vecLocationZoomPlot2);
		ylabel(ptrZoomPlot2,'Radius','FontSize',10);
		ptrZoomPlot2.XAxis.Visible = 'off';
		set(ptrZoomPlot2,'ytick',[]);
		hold(ptrZoomPlot2,'on');
		grid(ptrZoomPlot2,'on');
		
		vecLocationZoomPlot3 = vecLocationZoomPlot2 + [0 vecLocationZoomPlot2(4)+0.005 0 0];
		ptrZoomPlot3 = axes(ptrMainGUI,'Position',vecLocationZoomPlot3);
		ylabel(ptrZoomPlot3,'Loc X/Y','FontSize',10);
		ptrZoomPlot3.XAxis.Visible = 'off';
		set(ptrZoomPlot3,'ytick',[]);
		hold(ptrZoomPlot3,'on');
		grid(ptrZoomPlot3,'on');
		
		%add to global
		sFigETC.ptrZoomPlot1 = ptrZoomPlot1; %sync lum
		sFigETC.ptrZoomPlot2 = ptrZoomPlot2; %radius
		sFigETC.ptrZoomPlot3 = ptrZoomPlot3; %x/y
		set(sFigETC.ptrZoomPlot1,'ButtonDownFcn',{fCallback,'Click'});
		set(sFigETC.ptrZoomPlot2,'ButtonDownFcn',{fCallback,'Click'});
		set(sFigETC.ptrZoomPlot3,'ButtonDownFcn',{fCallback,'Click'});
		
		%% normalize
		ptrMainGUI.Units = 'normalized';
		
		%% draw
		ETC_redraw();
		%close msg
		delete(ptrMsg);
		
		%% wait until user accepts settings
		while ~sETC.boolForceQuit
			pause(0.01);
		end
		
		%% update sFile
		boolSaveData = sETC.boolSaveData;
		if boolSaveData
			sFile.sPupil.sPupil = sFigETC.sPupil;
		end
	catch ME
		dispErr(ME);
	end
	
	
