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
	sETO.strRootPath = 'D:\Data\Raw\';
	sETO.strTempPath = 'E:\_TempData'; %fast & reliable ssd;
	sETO.strSearchFormat = '\d{4}[-_]?\d{2}[-_]?\d{2}';
	cellExt = {'mp4','avi'};
	
	%% generate main GUI
	%locations: [from-left from-bottom width height]
	vecPosGUI = [0,0,600,500];
	ptrMainGUI = figure('Visible','on','Units','pixels','Position',vecPosGUI,'Resize','off');
	%set main gui properties
	%set(ptrMainGUI, 'MenuBar', 'none');
	%set(ptrMainGUI, 'ToolBar', 'none');
	set(ptrMainGUI,'DeleteFcn','ETO_DeleteFcn')
	
	%set output
	sFigETO.output = ptrMainGUI;
	
	%% build GUI master paramters
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
		'UserData','lock',...
		'Callback',@ptrButtonSetRoot_Callback);
	
	vecLocText = [vecLocSetRoot(1)+vecLocSetRoot(3)+10 vecLocSetRoot(2)+2 450 20];
	sFigETO.ptrTextRoot = uicontrol(sFigETO.ptrPanelPaths,'Style','text','HorizontalAlignment','left','String','','FontSize',10,'BackgroundColor',[1 1 1],...
		'Position',vecLocText);
	
	%temp path
	vecLocSetTemp = vecLocSetRoot + [0 -30 0 0];
	sFigETO.ptrButtonSetTemp = uicontrol(sFigETO.ptrPanelPaths,'Style','pushbutton','FontSize',11,...
		'String','Set temp:',...
		'Position',vecLocSetTemp,...
		'UserData','lock',...
		'Callback',@ptrButtonSetTemp_Callback);
	
	vecLocText = [vecLocSetTemp(1)+vecLocSetTemp(3)+10 vecLocSetTemp(2)+2 450 20];
	sFigETO.ptrTextTemp = uicontrol(sFigETO.ptrPanelPaths,'Style','text','HorizontalAlignment','left','String','','FontSize',10,'BackgroundColor',[1 1 1],...
		'Position',vecLocText);
	
	%compile button
	vecLocCompileButton = vecLocSetTemp + [0 -30 100 0];
	sFigETO.ptrButtonCompileLibrary = uicontrol(sFigETO.ptrPanelPaths,'Style','pushbutton','FontSize',11,...
		'String','Compile video library',...
		'Position',vecLocCompileButton,...
		'UserData','lock',...
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
	vecLocPresetButton = [20 20 120 25];
	sFigETO.ptrButtonSetParams = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Set parameters',...
		'Position',vecLocPresetButton,...
		'UserData','lock',...
		'Callback',@ptrButtonSetParams_Callback);
	vecLocTrackingButton = [vecLocPresetButton(1)+vecLocPresetButton(3)+5 vecLocPresetButton(2:4)];
	sFigETO.ptrButtonStartTracking = uicontrol(ptrMainGUI,'Style','pushbutton','FontSize',11,...
		'String','Start tracking',...
		'Position',vecLocTrackingButton,...
		'UserData','lock',...
		'Callback',@ptrButtonStartTracking_Callback);
	
	%% run initial callbacks
	ptrButtonSetRoot_Callback(sETO.strRootPath);
	ptrButtonSetTemp_Callback(sETO.strTempPath);
	
	
	%% set properties
	%set to resize
	%ptrMainGUI.Units = 'normalized';
	%sFigETO.ptrTextStimSet.Units = 'normalized';
	%sFigETO.ptrListSelectStimulusSet.Units = 'normalized';
	
	% Assign a name to appear in the window title.
	ptrMainGUI.Name = 'Offline Eyetracker GUI';
	
	% Move the window to the center of the screen.
	movegui(ptrMainGUI,'center')
	
	% Make the UI visible.
	ptrMainGUI.Visible = 'on';
	sFigETO.ptrMainGUI = ptrMainGUI;
	
	%unlock
	SC_unlock(sFigETO);
	
	
	%% callbacks
	function ptrButtonSetRoot_Callback(hObject, eventdata)
		%retrieve root
		if ischar(hObject)
			strRoot = hObject;
		else
			strRoot = uigetdir(sETO.strRootPath,'Select root path:');
		end
		
		%update
		sFigETO.ptrTextRoot.String = strRoot;
		sETO.strRootPath = strRoot;
	end
	function ptrButtonSetTemp_Callback(hObject, eventdata)
		%retrieve root
		if ischar(hObject)
			strTemp = hObject;
		else
			strTemp = uigetdir(sETO.strTempPath,'Select temp path:');
		end
		
		%update
		sFigETO.ptrTextTemp.String = strTemp;
		sETO.strTempPath = strTemp;
		%add free space
		objFile      = java.io.File(strTemp(1:2));
		dblFreeGB   = objFile.getFreeSpace/(1024.^3);
		sFigETO.ptrTextTempSpace.String = sprintf('%.1f GB',dblFreeGB);
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
		sETO.sFiles = ETO_CompileVideoLibrary(sETO.strRootPath,cellExt);
		
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
		
		%unlock
		%set(sFigETO.ptrButtonCheckStimPresets,...
		%	'Enable','on',...
		%	'UserData','unlock');
		%set(sFigETO.ptrButtonStartExperiment,...
		%	'Enable','on',...
		%	'UserData','unlock');
		
	end
	function ptrButtonSetParams_Callback(hObject, eventdata)
		%get checked 
		if isfield(sFigETO,'sPointers') && isfield(sFigETO.sPointers,'CheckRun')
			indUseFiles = cellfun(@(x) x.Value==1,{sFigETO.sPointers.CheckRun});
		end
		
		%check if any
		if ~any(indUseFiles)
			ptrMsg = dialog('Position',[600 400 250 100],'Name','No files selected');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[20 50 210 40],...
				'FontSize',11,...
				'String','You did not select any files');
			ptrButton = uicontrol('Parent',ptrMsg,...
				'Position',[100 20 50 30],...
				'String','OK',...
				'FontSize',10,...
				'Callback','delete(gcf)');
			
			movegui(ptrMsg,'center')
			drawnow;
			return
		end
		
		%go through files
		vecRunFiles = find(indUseFiles);
		for intFileIdx=1:numel(vecRunFiles)
			intFile = vecRunFiles(intFileIdx);
			sTrackParams = getEyeTrackingParameters(sETO.sFiles(intFile));
			if isempty(sTrackParams)
				break;
			else
				%update parameter list
				sETO.sFiles(intFile).sTrackParams = sTrackParams;
				sFigETO.sPointers(intFile).TrackParams.String = 'Y';
				sFigETO.sPointers(intFile).TrackParams.ForegroundColor = [0 0.8 0];
				sFigETO.sPointers(intFile).TrackParams.Tooltip = 'Tracking parameters have been set';
			end
		end
	end
	function ptrButtonStartTracking_Callback(hObject, eventdata)
		%get checked 
		if isfield(sFigETO,'sPointers') && isfield(sFigETO.sPointers,'CheckRun')
			indUseFiles = cellfun(@(x) x.Value==1,{sFigETO.sPointers.CheckRun});
		end
		
		%check if any
		if ~any(indUseFiles)
			ptrMsg = dialog('Position',[600 400 250 100],'Name','No files selected');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[20 50 210 40],...
				'FontSize',11,...
				'String','You did not select any files');
			ptrButton = uicontrol('Parent',ptrMsg,...
				'Position',[100 20 50 30],...
				'String','OK',...
				'FontSize',10,...
				'Callback','delete(gcf)');
			
			movegui(ptrMsg,'center')
			drawnow;
			return
		end
		
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
			SC_lock(sFigETO);
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
			SC_unlock(sFigETO);
		end
	end
end
