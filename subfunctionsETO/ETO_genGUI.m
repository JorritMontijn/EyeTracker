function [sFigETO,sETO] = ETO_genGUI(varargin)
	%ETO_genGUI Main function for offline eye tracker
	%   [sFigETO,sETO] = ETO_genGUI(sFigETO,sETO)
	%
	%Workflow:
	%compile list of all video files in subfolders of master path
	%list names & parameters from meta file
	%list whether preprocessed
	%select which to process
	%path = pop up
	%
	%click to check parameters
	%> new gui
	%
	%once all params are set for all videos, run
	
	%% construct gui
	global sETO;
	global sFigETO;
	
	%default parameters
	%master path
	if ~isfield(sETO,'strRootPath')
		sETO.strRootPath = 'D:\Data\Raw\';
	end
	if ~isfield(sETO,'strTempPath')
		sETO.strTempPath = 'E:\_TempData'; %fast & reliable ssd;
	end
	cellExt = {'mp4','avi'};
	
	%% generate main GUI
	%locations: [from-left from-bottom width height]
	vecPosGUI = [0,0,600,500];
	ptrMainGUI = figure('Visible','on','Units','pixels','Position',vecPosGUI,'Resize','off');
	%set main gui properties
	set(ptrMainGUI,'DeleteFcn','ETO_DeleteFcn');
	set(ptrMainGUI, 'MenuBar', 'none','ToolBar', 'none','NumberTitle','off');
	
	%change icon
	strPathET = ET_getIniPath();
	try
		warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
		warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
		jframe=get(ptrMainGUI,'javaframe');
		jIcon=javax.swing.ImageIcon(fullpath(strPathET,'icon.png'));
		jframe.setFigureIcon(jIcon);
	catch
	end
	
	% set mouse & scroll wheel callback
	set(ptrMainGUI,'windowscrollWheelFcn',@ETO_Scrollwheel);
	
	%set output
	sFigETO.output = ptrMainGUI;
	
	%% build GUI master parameters
	vecMainColor = [0.97 0.97 0.97];
	sFigETO.ptrPanelPaths = uipanel('Parent',ptrMainGUI,'BackgroundColor',vecMainColor,...
		'Units','pixels','Title','Master paths','FontSize',10);
	dblHeight = 120;
	vecLocPanelMP = [10 vecPosGUI(4)-dblHeight-10 580 dblHeight];
	set(sFigETO.ptrPanelPaths,'Position',vecLocPanelMP);
	
	%root path
	vecLocSetRoot = [20 dblHeight-50 80 25];
	sFigETO.ptrButtonSetRoot = uicontrol(sFigETO.ptrPanelPaths,'Style','pushbutton','FontSize',11,...
		'String','Set root:',...
		'Position',vecLocSetRoot,...
		'Tooltip','Set path to root directory that contains videos in subfolders',...
		'Callback',@ptrButtonSetRoot_Callback);
	
	vecLocText = [vecLocSetRoot(1)+vecLocSetRoot(3)+10 vecLocSetRoot(2)+2 450 20];
	sFigETO.ptrTextRoot = uicontrol(sFigETO.ptrPanelPaths,'Style','text','HorizontalAlignment','left','String','','FontSize',10,'BackgroundColor',[1 1 1],...
		'Position',vecLocText);
	
	%temp path
	vecLocSetTemp = vecLocSetRoot + [0 -30 0 0];
	sFigETO.ptrButtonSetTemp = uicontrol(sFigETO.ptrPanelPaths,'Style','pushbutton','FontSize',11,...
		'String','Set temp:',...
		'Position',vecLocSetTemp,...
		'Tooltip','Set path to directory on fast SSD',...
		'Callback',@ptrButtonSetTemp_Callback);
	
	vecLocText = [vecLocSetTemp(1)+vecLocSetTemp(3)+10 vecLocSetTemp(2)+2 450 20];
	sFigETO.ptrTextTemp = uicontrol(sFigETO.ptrPanelPaths,'Style','text','HorizontalAlignment','left','String','','FontSize',10,'BackgroundColor',[1 1 1],...
		'Position',vecLocText);
	
	%compile button
	vecLocCompileButton = vecLocSetTemp + [0 -30 100 0];
	sFigETO.ptrButtonCompileLibrary = uicontrol(sFigETO.ptrPanelPaths,'Style','pushbutton','FontSize',11,...
		'String','Compile video library',...
		'Position',vecLocCompileButton,...
		'Tooltip','Search root path for videos',...
		'Callback',@ptrButtonCompileLibrary_Callback);
	
	%free temp space
	vecLocTempSpace = [vecLocCompileButton(1)+vecLocCompileButton(3)+5 vecLocCompileButton(2) 150 20];
	sFigETO.ptrStaticTextTempSpace = uicontrol(sFigETO.ptrPanelPaths,'Style','text','FontSize',10,...
		'String','Temp space available:',...
		'Position',vecLocTempSpace,'BackgroundColor',vecMainColor);
	vecLocTempSpace = [vecLocTempSpace(1)+vecLocTempSpace(3)+5 vecLocTempSpace(2) 100 20];
	sFigETO.ptrTextTempSpace = uicontrol(sFigETO.ptrPanelPaths,'Style','text','FontSize',10,...
		'String','',...
		'Position',vecLocTempSpace,'BackgroundColor',[1 1 1]);
	
	%set tracking parameters
	vecLocPresetButton = [20 20 110 25];
	sFigETO.ptrButtonSetParams = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Set manually',...
		'Position',vecLocPresetButton,...
		'Tooltip','Change eye-tracking parameters manually',...
		'Callback',@ptrButtonSetParams_Callback);
	
	vecLocLabelButton = [vecLocPresetButton(1)+vecLocPresetButton(3)+5 vecLocPresetButton(2:4)];
	sFigETO.ptrButtonSetLabels = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Label frames',...
		'Position',vecLocLabelButton,...
		'Tooltip','Label frames for training the algorithm''s parameter',...
		'Callback',@ptrButtonSetLabels_Callback);
	
	vecLocAutopilotButton = [vecLocLabelButton(1)+vecLocLabelButton(3)+5 vecLocLabelButton(2:4)];
	sFigETO.ptrButtonAutopilot = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Train & track',...
		'Position',vecLocAutopilotButton,...
		'Tooltip','Optimize parameters using labelled frames & start tracking after training',...
		'Callback',@ptrButtonAutopilot_Callback);
	
	vecLocTrackingButton = [vecLocAutopilotButton(1)+vecLocAutopilotButton(3)+5 vecLocAutopilotButton(2:4)];
	sFigETO.ptrButtonStartTracking = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Start tracking',...
		'Position',vecLocTrackingButton,...
		'Tooltip','Start tracking using pre-defined parameters',...
		'Callback',@ptrButtonStartTracking_Callback);
	
	vecLocCheckTrackButton = [vecLocTrackingButton(1)+vecLocTrackingButton(3)+5 vecLocTrackingButton(2:4)];
	sFigETO.ptrButtonCheckTracking = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Check results',...
		'Position',vecLocCheckTrackButton,...
		'Tooltip','Check tracking results using mini-vid',...
		'Callback',@ptrButtonCheckTracking_Callback);
	
	%% run initial callbacks
	ptrButtonSetRoot_Callback(sETO.strRootPath);
	ptrButtonSetTemp_Callback(sETO.strTempPath);
	
	%% set properties
	% Assign a name to appear in the window title.
	ptrMainGUI.Name = 'EyeTracking Library';
	
	% Move the window to the center of the screen.
	movegui(ptrMainGUI,'center')
	
	% Make the UI visible.
	ptrMainGUI.Visible = 'on';
	sFigETO.ptrMainGUI = ptrMainGUI;
	
	%unlock
	uiunlock(sFigETO);
	
	
	%% callbacks
	function ptrButtonCheckTracking_Callback(hObject, eventdata)
		%get checked
		indUseFiles = ETO_CheckSelection(sFigETO);
		if ~any(indUseFiles),return;end
		
		%go through files
		vecRunFiles = find(indUseFiles);
		
		%check if all files have minivids and tracking data
		indReady = false(size(vecRunFiles));
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			try 
				strMiniVid = sETO.sFiles(intFile).sPupil.sPupil.strMiniVidFile;
				[dummy,strMiniFile,strExt]=fileparts(strMiniVid);
				strMiniVidPath = sETO.sFiles(intFile).sPupil.sPupil.strMiniVidPath;
				cellUseExt = {'.mp4','.avi','.mj2'};
				cellUseExt{end+1}=strExt;
				cellUseExt = unique(cellUseExt);
				for intExt=1:numel(cellUseExt)
					strUseExt = cellUseExt{intExt};
					if exist([strMiniVidPath strMiniFile strUseExt],'file')
						indReady(intFileIdx) = true;
					elseif exist(fullfile(sETO.sFiles(intFile).folder,[strMiniFile strUseExt]),'file')
						indReady(intFileIdx) = true;
					elseif exist(fullfile(sETO.strTempPath,[strMiniFile strUseExt]),'file')
						indReady(intFileIdx) = true;
					elseif exist(fullfile(sETO.sFiles(intFile).sPupil.folder,[strMiniFile strUseExt]),'file')
						indReady(intFileIdx) = true;
					end
				end
			catch
				indReady(intFileIdx) = false;
			end
		end
		if ~all(indReady)
			ptrMsg = dialog('Position',[600 400 250 100],'Name','Not all files ready');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[20 50 210 40],...
				'FontSize',11,...
				'String','Some files are missing tracking data and/or mini vids');
			ptrButton = uicontrol('Parent',ptrMsg,...
				'Position',[100 20 50 30],...
				'String','OK',...
				'FontSize',10,...
				'Callback','delete(gcf)');
			movegui(ptrMsg,'center')
			drawnow;
			return
		else
			%run
			uilock(sFigETO);
			drawnow;
			
			%auto-set parameters
			for intFileIdx=1:numel(vecRunFiles)
				intFile = vecRunFiles(intFileIdx);
				try
					%run auto-parameters
					sETO.sFiles(intFile) = getEyeTrackerChecker(sETO.sFiles(intFile),sETO.strTempPath);
				catch ME
					dispErr(ME);
				end
			end
			
			%enable
			uiunlock(sFigETO);
			drawnow;
		end
	end
	function ptrButtonSetLabels_Callback(hObject, eventdata)
		%get checked
		indUseFiles = ETO_CheckSelection(sFigETO);
		if ~any(indUseFiles),return;end
		%run
		uilock(sFigETO);
		drawnow;
		
		%go through files
		vecRunFiles = find(indUseFiles);
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			%label images
			[dummy,sLabels] = getEyeTrackingParameters(sETO.sFiles(intFile),sETO.strTempPath,false,true);
			
			if ~isempty(sLabels) && isfield(sLabels,'T')
				%update labels
				sETO.sFiles(intFile).sLabels = sLabels;
				sFigETO.sPointers(intFile).Labels.String = 'Y';
				sFigETO.sPointers(intFile).Labels.ForegroundColor = [0 0.8 0];
				sFigETO.sPointers(intFile).Labels.Tooltip = 'Image labels are present';
			end
		end
		
		%unlock
		uiunlock(sFigETO);
	end
	function ptrButtonAutopilot_Callback(hObject, eventdata)
		%get checked
		indUseFiles = ETO_CheckSelection(sFigETO);
		if ~any(indUseFiles),return;end
		vecRunFiles = find(indUseFiles);
		
		%check if all files have labels
		indReady = false(size(vecRunFiles));
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			if isfield(sETO.sFiles(intFile),'sLabels') && isfield(sETO.sFiles(intFile).sLabels,'T')
				indReady(intFileIdx) = true;
			end
		end
		if ~all(indReady)
			ptrMsg = dialog('Position',[600 400 250 100],'Name','Not all files ready');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[20 50 210 40],...
				'FontSize',11,...
				'String','Some files are missing image labels');
			ptrButton = uicontrol('Parent',ptrMsg,...
				'Position',[100 20 50 30],...
				'String','OK',...
				'FontSize',10,...
				'Callback','delete(gcf)');
			movegui(ptrMsg,'center')
			drawnow;
			return
		else
			%run
			uilock(sFigETO);
			drawnow;
			
			%auto-set parameters
			for intFileIdx=1:numel(vecRunFiles)
				intFile = vecRunFiles(intFileIdx);
				try
					%run auto-parameters
					sTrackParams = getEyeTrackingParameters(sETO.sFiles(intFile),sETO.strTempPath,true);
					
					%update parameter list
					sETO.sFiles(intFile).sTrackParams = sTrackParams;
					sFigETO.sPointers(intFile).TrackParams.String = 'Y';
					sFigETO.sPointers(intFile).TrackParams.ForegroundColor = [0 0.8 0];
					sFigETO.sPointers(intFile).TrackParams.Tooltip = 'Tracking parameters have been set';
				catch ME
					dispErr(ME);
				end
			end
			
			%run tracking
			for intFileIdx=1:numel(vecRunFiles)
				try
					intFile = vecRunFiles(intFileIdx);
					sFile = sETO.sFiles(intFile);
					sPupil = getEyeTrackingOffline(sFile,sETO.strTempPath);
					
					%update library
					if ~isempty(sPupil)
						%update parameter list
						sETO.sFiles(intFile).sPupil = sPupil;
						sFigETO.sPointers(intFile).Tracked.String = 'Y';
						sFigETO.sPointers(intFile).Tracked.ForegroundColor = [0 0.8 0];
						sFigETO.sPointers(intFile).Tracked.Tooltip = ['Tracked data at: ' sPupil.name];
						drawnow;
					end
				catch ME
					dispErr(ME);
				end
			end
			uiunlock(sFigETO);
		end
	end
	function ptrButtonSetRoot_Callback(hObject, eventdata)
		%retrieve root
		if ischar(hObject)
			strRoot = hObject;
		else
			try
				strRoot = uigetdir(sETO.strRootPath,'Select root path:');
			catch
				strRoot = uigetdir('','Select root path:');
			end
		end
		if ischar(strRoot)
			%update
			sFigETO.ptrTextRoot.String = strRoot;
			sETO.strRootPath = strRoot;
		end
	end
	function ptrButtonSetTemp_Callback(hObject, eventdata)
		%retrieve root
		if ischar(hObject)
			strTemp = hObject;
		else
			try
				strTemp = uigetdir(sETO.strTempPath,'Select temp path:');
			catch
				strTemp = uigetdir('','Select temp path:');
			end
		end
		
		if ischar(strTemp)
			%update
			sFigETO.ptrTextTemp.String = strTemp;
			sETO.strTempPath = strTemp;
			%add free space
			objFile      = java.io.File(strTemp(1:2));
			dblFreeGB   = objFile.getFreeSpace/(1024.^3);
			sFigETO.ptrTextTempSpace.String = sprintf('%.1f GB',dblFreeGB);
		end
	end
	function ptrButtonCompileLibrary_Callback(hObject, eventdata)
		%message
		ptrMsg = dialog('Position',[600 400 250 50],'Name','Library Compilation');
		ptrText = uicontrol('Parent',ptrMsg,...
			'Style','text',...
			'Position',[20 00 210 40],...
			'FontSize',11,...
			'String','Compiling video library...');
		movegui(ptrMsg,'center')
		drawnow;
		
		%get data
		sETO.sFiles = ETO_CompileVideoLibrary(sETO.strRootPath,cellExt,ptrText);
		
		%close msg
		delete(ptrMsg);
		
		%populate gui
		if isfield(sFigETO,'ptrPanelLibrary') && ~isempty(sFigETO.ptrPanelLibrary)
			delete(sFigETO.ptrPanelLibrary);
			delete(sFigETO.ptrSliderLibrary);
			delete(sFigETO.ptrTitleLibrary);
			sFigETO.ptrPanelLibrary=[];
		end
		
		
		%% populate new panel
		%get main GUI size and define subpanel size
		dblPanelX = 0.01;
		dblPanelY = 0.12;
		dblPanelHeight = 0.6;
		dblPanelWidth = 0.94;
		vecLocation = [dblPanelX dblPanelY dblPanelWidth dblPanelHeight];
		
		%generate slider panel
		[sFigETO.ptrPanelLibrary,sFigETO.ptrSliderLibrary,sFigETO.ptrTitleLibrary,sFigETO.sPointers] = ETO_genSliderPanel(ptrMainGUI,vecLocation,sETO.sFiles);
		
	end
	function ptrButtonSetParams_Callback(hObject, eventdata)
		%get checked
		indUseFiles = ETO_CheckSelection(sFigETO);
		if ~any(indUseFiles),return;end
		%run
		uilock(sFigETO);
		drawnow;
		
		%go through files
		vecRunFiles = find(indUseFiles);
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			[sTrackParams,sLabels] = getEyeTrackingParameters(sETO.sFiles(intFile),sETO.strTempPath);
			if ~isempty(sTrackParams)
				%update parameter list
				sETO.sFiles(intFile).sTrackParams = sTrackParams;
				sFigETO.sPointers(intFile).TrackParams.String = 'Y';
				sFigETO.sPointers(intFile).TrackParams.ForegroundColor = [0 0.8 0];
				sFigETO.sPointers(intFile).TrackParams.Tooltip = 'Tracking parameters have been set';
			end
			if ~isempty(sLabels) && isfield(sLabels,'T')
				%update labels
				sETO.sFiles(intFile).sLabels = sLabels;
				sFigETO.sPointers(intFile).Labels.String = 'Y';
				sFigETO.sPointers(intFile).Labels.ForegroundColor = [0 0.8 0];
				sFigETO.sPointers(intFile).Labels.Tooltip = 'Image labels are present';
			end
		end
		%unlock
		uiunlock(sFigETO);
		drawnow;
		
	end
	function ptrButtonStartTracking_Callback(hObject, eventdata)
		%get checked
		indUseFiles = ETO_CheckSelection(sFigETO);
		if ~any(indUseFiles),return;end
		
		%check if all files have parameter presets
		vecRunFiles = find(indUseFiles);
		indReady = false(size(vecRunFiles));
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			if isfield(sETO.sFiles(intFile),'sTrackParams') && ~isempty(sETO.sFiles(intFile).sTrackParams)
				indReady(intFileIdx) = true;
			end
		end
		if ~all(indReady)
			ptrMsg = dialog('Position',[600 400 250 100],'Name','Not all files ready');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[20 50 210 40],...
				'FontSize',11,...
				'String','Some files are missing parameter settings');
			ptrButton = uicontrol('Parent',ptrMsg,...
				'Position',[100 20 50 30],...
				'String','OK',...
				'FontSize',10,...
				'Callback','delete(gcf)');
			movegui(ptrMsg,'center')
			drawnow;
			return
		else
			%run
			uilock(sFigETO);
			drawnow;
			
			for intFileIdx=1:numel(vecRunFiles)
				try
					intFile = vecRunFiles(intFileIdx);
					sFile = sETO.sFiles(intFile);
					sPupil = getEyeTrackingOffline(sFile,sETO.strTempPath);
					
					%update library
					if ~isempty(sPupil)
						%update parameter list
						sETO.sFiles(intFile).sPupil = sPupil;
						sFigETO.sPointers(intFile).Tracked.String = 'Y';
						sFigETO.sPointers(intFile).Tracked.ForegroundColor = [0 0.8 0];
						sFigETO.sPointers(intFile).Tracked.Tooltip = 'Tracking parameters have been set';
						drawnow;
					end
				catch ME
					dispErr(ME);
				end
			end
			uiunlock(sFigETO);
		end
	end
end
