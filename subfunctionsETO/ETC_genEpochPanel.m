function ETC_genEpochPanel(ptrMainGUI,vecLocation,fCallback)
	
	%% get globals
	global sETC;
	global sFigETC;
	
	%% make panel
	ptrPanelEpoch = uipanel('Parent',ptrMainGUI);
	vecColor = get(ptrMainGUI,'Color');
	set(ptrPanelEpoch,'Position',vecLocation,'BackgroundColor',vecColor,'Title','Epoch Annotation','FontSize',10);
	ptrPanelEpoch.Units = 'normalized';
	
	%% generate elements
	%list of epochs
	if ~isfield(sFigETC.sPupil,'sEpochs')
		sEpochs = struct;
		sEpochs.BeginFrame = nan;
		sEpochs.BeginLabels = [];
		sEpochs.EndFrame = nan;
		sEpochs.EndLabels = [];
		sEpochs.CenterX = [];
		sEpochs.CenterY = [];
		sEpochs.Radius = [];
		sEpochs.Blinks = [];
		sEpochs(:) = [];
		sFigETC.sPupil.sEpochs = sEpochs;
	end
	
	%generate list
	%vecLocList = [5 170 120 20];
	vecLocList = [0.05 0.88 0.9 0.1];
	ptrEpochList = uicontrol(ptrPanelEpoch,'Style','popupmenu','Units','normalized','Position',vecLocList,'String',{''},'Callback',@ETC_SelectEpoch,'FontSize',10);
	
	%populate list
	ETC_GenEpochList(ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
	
	%generate radio buttons
	vecLocRadioGroup = [vecLocList(1) vecLocList(2)-0.27 vecLocList(3) 0.25];
	ptrGroup = uibuttongroup(ptrPanelEpoch,'Units','normalized','Position',vecLocRadioGroup);
	vecLocRadio1 = [0 0 1 0.5];
	ptrEpochAutoDetect = uicontrol(ptrGroup,'Style','radiobutton','Units','normalized','Position',vecLocRadio1,'String','Auto-detect','FontSize',10);
	vecLocRadio2 = [0 0.5 1 0.5];
	ptrEpochInterpolate = uicontrol(ptrGroup,'Style','radiobutton','Units','normalized','Position',vecLocRadio2,'String','Interpolate','FontSize',10);
	
	
	%% populate panel based on current epoch
	%set locations
	dblW = 0.44;
	dblH = 0.15;
	dblLeftStart = vecLocList(1);
	dblRightStart = vecLocList(1)+dblW+0.02;
	dblTopStart = vecLocRadioGroup(2)-dblH-0.05;
	dblBottomStart = dblTopStart-dblH-0.02;
	
	%button 1: draw pupil begin; callback: draw pupil, save as temporary
	%epoch if new, or overwrite old epoch
	vecLocButtonTL = [dblLeftStart dblTopStart dblW dblH];
	ptrButtonDrawPupilBegin = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonTL,'String','Draw Begin','Callback',{@ETC_DrawPupilEpoch,'begin'},'FontSize',10);
	
	%button 2: draw pupil end; callback: draw pupil, make new epoch and add
	%temporary epoch to list if new, or overwrite old epoch
	vecLocButtonTR = [dblRightStart dblTopStart dblW dblH];
	ptrButtonDrawPupilEnd = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonTR,'String','Draw End','Callback',{@ETC_DrawPupilEpoch,'end'},'FontSize',10);
	
	%button 3: set blink begin; callback: save as temporary epoch if new,
	%or overwrite old epoch
	vecLocButtonBL = [dblLeftStart dblBottomStart dblW dblH];
	ptrButtonDrawBlinkBegin = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonBL,'String','Blink Begin','Callback',{@ETC_SetBlinkEpoch,'begin'},'FontSize',10);
	
	%button 4: set blink end; callback: make new epoch and add temporary
	%epoch to list if new, or overwrite old epoch
	vecLocButtonBR = [dblRightStart dblBottomStart dblW dblH];
	ptrButtonDrawBlinkEnd = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonBR,'String','Blink End','Callback',{@ETC_SetBlinkEpoch,'end'},'FontSize',10);
	
	%button 5: callback: delete selected epoch if selected is not new
	vecLocButtonDelete = [dblLeftStart+0.1 dblBottomStart-dblH-0.03 dblW*1.5 dblH];
	ptrButtonDeleteEpoch = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonDelete,'String','Delete Epoch','ForegroundColor',[0.4 0 0],'Callback',@ETC_DeleteEpoch,'FontSize',10);
	
	%% add pointers
	sFigETC.ptrPanelEpoch = ptrPanelEpoch;
	sFigETC.ptrEpochList = ptrEpochList;
	sFigETC.ptrEpochAutoDetect = ptrEpochAutoDetect;
	sFigETC.ptrEpochInterpolate = ptrEpochInterpolate;
	sFigETC.ptrButtonDrawPupilBegin = ptrButtonDrawPupilBegin;
	sFigETC.ptrButtonDrawPupilEnd = ptrButtonDrawPupilEnd;
	sFigETC.ptrButtonDrawBlinkBegin = ptrButtonDrawBlinkBegin;
	sFigETC.ptrButtonDrawBlinkEnd = ptrButtonDrawBlinkEnd;
	sFigETC.ptrButtonDeleteEpoch = ptrButtonDeleteEpoch;
	sFigETC.sEpochTemp = [];
end
function ETC_DrawPupilEpoch(hObject,eventdata,strType)
	%globals
	global sFigETC;
	%get temporary epoch
	sEpoch = sFigETC.sEpochTemp;
	
	%if not new, set time to beginning & redraw
	intSelectEpoch = sFigETC.ptrEpochList.Value;
	cellEpochList = sFigETC.ptrEpochList.String;
	if isempty(sEpoch)
		if intSelectEpoch == numel(cellEpochList)
			%gen
			sEpoch = ETC_GenEmptyEpochs();
			sEpoch(1).BeginFrame = nan;
			sEpoch(1).EndFrame = nan;
		else
			%load data
			sEpoch = sFigETC.sPupil.sEpochs(intSelectEpoch);
		end
	end
	
	%get current frame and ask for pupil drawing
	intCurrFrame = sFigETC.intCurFrame;
	sLabels = ETP_GetImLabels(sFigETC.ptrCurFrame.CData(:,:,1));
	if strcmpi(strType,'begin')
		sEpoch.BeginLabels = sLabels;
		sEpoch.BeginFrame = intCurrFrame;
	elseif strcmpi(strType,'end')
		sEpoch.EndLabels = sLabels;
		sEpoch.EndFrame = intCurrFrame;
	else
		error([mfilename ':TypeMissing'],'Type missing');
	end
	
	%check if epoch is complete
	if ~isnan(sEpoch.BeginFrame) && ~isnan(sEpoch.EndFrame) && sEpoch.BeginFrame > 0  && sEpoch.EndFrame > 0 && ~isempty(sEpoch.BeginLabels) && ~isempty(sEpoch.EndLabels)
		%swap end/begin if end < begin
		if sEpoch.EndFrame < sEpoch.BeginFrame
			intOldBeginF = sEpoch.BeginFrame;
			sOldBeginL = sEpoch.BeginLabels;
			sEpoch.BeginFrame = sEpoch.EndFrame;
			sEpoch.BeginLabels = sEpoch.EndLabels;
			sEpoch.EndFrame = intOldBeginF;
			sEpoch.EndLabels = sOldBeginL;
		end
		
		%interpolate or detect pupil between beginning and end of epoch
		intSwitchDetectOrInterpolate = sFigETC.ptrEpochInterpolate.Value; %0=detect,1=interp
		vecFrames = sEpoch.BeginFrame:sEpoch.EndFrame;
		intFrames = numel(vecFrames);
		%if intSwitchDetectOrInterpolate == 1
			sEpoch.CenterX = linspace(sEpoch.BeginLabels.X,sEpoch.EndLabels.X,intFrames);
			sEpoch.CenterY = linspace(sEpoch.BeginLabels.Y,sEpoch.EndLabels.Y,intFrames);
			sEpoch.Radius = linspace(sEpoch.BeginLabels.R,sEpoch.EndLabels.R,intFrames);
			sEpoch.Blinks = [];
		%else
			
		%end
		
		%remove temporary epoch
		sFigETC.sEpochTemp = [];
		%update epoch list
		sFigETC.sPupil.sEpochs(intSelectEpoch) = sEpoch;
		%reorder
		[dummy,vecReorder] = sort(cell2vec({sFigETC.sPupil.sEpochs.BeginFrame}));
		sFigETC.sPupil.sEpochs = sFigETC.sPupil.sEpochs(vecReorder);
		%update gui epoch list
		cellEpochList = ETC_GenEpochList(sFigETC.ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
		sFigETC.ptrEpochList.Value = numel(cellEpochList);
		%redraw traces
		ETC_redraw();
	else
		%add temporary epoch
		sFigETC.sEpochTemp = sEpoch;
	end
end
function ETC_SetBlinkEpoch(hObject,eventdata,strType)
	%globals
	global sFigETC;
	%get temporary epoch
	sEpoch = sFigETC.sEpochTemp;
	
	%if not new, set time to beginning & redraw
	intSelectEpoch = sFigETC.ptrEpochList.Value;
	cellEpochList = sFigETC.ptrEpochList.String;
	if isempty(sEpoch)
		if intSelectEpoch == numel(cellEpochList)
			%gen
			sEpoch = struct;
			sEpoch.BeginFrame = nan;
			sEpoch.BeginLabels = [];
			sEpoch.EndFrame = nan;
			sEpoch.EndLabels = [];
			sEpoch.CenterX = [];
			sEpoch.CenterY = [];
			sEpoch.Radius = [];
			sEpoch.Blinks = [];
		else
			%load data
			sEpoch = sFigETC.sPupil.sEpochs(intSelectEpoch);
		end
	end
	
	%get current frame
	intCurrFrame = sFigETC.intCurFrame;
	if strcmpi(strType,'begin')
		sEpoch.BeginFrame = intCurrFrame;
	elseif strcmpi(strType,'end')
		sEpoch.EndFrame = intCurrFrame;
	else
		error([mfilename ':TypeMissing'],'Type missing');
	end
	
	%check if epoch is complete
	if ~isnan(sEpoch.BeginFrame) && ~isnan(sEpoch.EndFrame) && sEpoch.BeginFrame > 0  && sEpoch.EndFrame > 0 && isempty(sEpoch.BeginLabels) && isempty(sEpoch.EndLabels)
		%swap end/begin if end < begin
		if sEpoch.EndFrame < sEpoch.BeginFrame
			intOldBeginF = sEpoch.BeginFrame;
			sEpoch.BeginFrame = sEpoch.EndFrame;
			sEpoch.EndFrame = intOldBeginF;
		end
		
		%set blinks
		vecFrames = sEpoch.BeginFrame:sEpoch.EndFrame;
		intFrames = numel(vecFrames);
		sEpoch.CenterX = [];
		sEpoch.CenterY = [];
		sEpoch.Radius = [];
		sEpoch.Blinks = ones(1,intFrames);
		
		%remove temporary epoch
		sFigETC.sEpochTemp = [];
		%update epoch list
		sFigETC.sPupil.sEpochs(intSelectEpoch) = sEpoch;
		%reorder
		[dummy,vecReorder] = sort(cell2vec({sFigETC.sPupil.sEpochs.BeginFrame}));
		sFigETC.sPupil.sEpochs = sFigETC.sPupil.sEpochs(vecReorder);
		%update gui epoch list
		cellEpochList = ETC_GenEpochList(sFigETC.ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
		sFigETC.ptrEpochList.Value = numel(cellEpochList);
		%redraw traces
		ETC_redraw();
	else
		%add temporary epoch
		sFigETC.sEpochTemp = sEpoch;
	end
end
function ETC_DeleteEpoch(hObject,eventdata)
	%globals
	global sFigETC;
	%get temporary epoch
	sFigETC.sEpochTemp = [];
	
	%if not new, set time to beginning & redraw
	intSelectEpoch = sFigETC.ptrEpochList.Value;
	cellEpochList = sFigETC.ptrEpochList.String;
	if intSelectEpoch < numel(cellEpochList)
		%remove
		sFigETC.sPupil.sEpochs(intSelectEpoch) = [];
		%update gui epoch list
		cellEpochList = ETC_GenEpochList(sFigETC.ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
		sFigETC.ptrEpochList.Value = numel(cellEpochList);
		
		%redraw traces
		ETC_redraw();
	end
end
function ETC_SelectEpoch(hObject,eventdata)
	%globals
	global sFigETC;
	
	%if not new, set time to beginning & redraw
	sFigETC.sEpochTemp = [];
	intSelectEpoch = sFigETC.ptrEpochList.Value;
	cellEpochList = sFigETC.ptrEpochList.String;
	if intSelectEpoch == numel(cellEpochList)
		%new
	else
		%set to beginning
		sEpoch = sFigETC.sPupil.sEpochs(intSelectEpoch);
		ETC_GetCurrentFrame([],[],sEpoch.BeginFrame);
	end
end

function cellEpochList = ETC_GenEpochList(ptrEpochList,sEpochs,vecPupilTime)
	%vecPupilFixedCenterX(intBegin:intEnd) = sEpoch.CenterX;
	%vecPupilFixedCenterY(intBegin:intEnd) = sEpoch.CenterY;
	%vecPupilFixedRadius(intBegin:intEnd) = sEpoch.Radius;
	%vecPupilFixedBlinks(intBegin:intEnd) = sEpoch.Blinks;
	
	cellEpochList = arrayfun(@(x) sprintf('%.1f - %.1f s (F# %d - %d)',vecPupilTime(x.BeginFrame),vecPupilTime(x.EndFrame),x.BeginFrame,x.EndFrame),...
		sEpochs,'UniformOutput',false);
	cellEpochList(end+1) = {'New'};
	ptrEpochList.String = cellEpochList;
end