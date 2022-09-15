function ETC_genEpochPanel(ptrMainGUI,vecLocation)
	
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
	if ~isfield(sFigETC.sPupil,'sEpochs') || isempty(sFigETC.sPupil.sEpochs)
		sEpochs = ETC_GenEmptyEpochs;
		sEpochs(:) = [];
		sFigETC.sPupil.sEpochs = sEpochs;
	end
	
	
	%generate list
	%vecLocList = [5 170 120 20];
	vecLocList = [0.05 0.88 0.9 0.1];
	ptrEpochList = uicontrol(ptrPanelEpoch,'Style','popupmenu','Units','normalized','Position',vecLocList,'String',{''},'Callback',@ETC_SelectEpoch,'FontSize',10);
	
	%create epochs from fixed data
	[cellEpochList,sFigETC.sPupil.sEpochs] = ETC_GenEpochList(ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime,sFigETC.sPupil);
	ptrEpochList.Value = numel(cellEpochList);
	
	%generate radio buttons
	vecLocRadioGroup = [vecLocList(1) vecLocList(2)-0.27 vecLocList(3) 0.25];
	ptrGroup = uibuttongroup(ptrPanelEpoch,'Units','normalized','Position',vecLocRadioGroup);
	vecLocRadio1 = [0 0 1 0.5];
	ptrEpochAutoDetect = uicontrol(ptrGroup,'Style','radiobutton','Units','normalized','Position',vecLocRadio1,'String','Auto-detect','Callback',@ETC_ResetFocus,'FontSize',10);
	vecLocRadio2 = [0 0.5 1 0.5];
	ptrEpochInterpolate = uicontrol(ptrGroup,'Style','radiobutton','Units','normalized','Position',vecLocRadio2,'String','Interpolate','Callback',@ETC_ResetFocus,'FontSize',10);
	
	
	%% populate panel based on current epoch
	%set locations
	dblW = 0.44;
	dblH = 0.10;
	dblLeftStart = vecLocList(1);
	dblRightStart = vecLocList(1)+dblW+0.02;
	dblTopStart = vecLocRadioGroup(2)-dblH-0.05;
	dblBottomStart = dblTopStart-dblH-0.02;
	
	%button 1: draw pupil begin; callback: draw pupil, save as temporary
	%epoch if new, or overwrite old epoch
	vecLocButtonTL = [dblLeftStart dblTopStart dblW dblH];
	ptrButtonDrawPupilBegin = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonTL,'String','Draw Begin','Callback',{@ETC_AddPupilEpoch,'begin'},'FontSize',10);
	
	%button 2: draw pupil end; callback: draw pupil, make new epoch and add
	%temporary epoch to list if new, or overwrite old epoch
	vecLocButtonTR = [dblRightStart dblTopStart dblW dblH];
	ptrButtonDrawPupilEnd = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonTR,'String','Draw End','Callback',{@ETC_AddPupilEpoch,'end'},'FontSize',10);
	
	%button 3: set blink begin; callback: save as temporary epoch if new,
	%or overwrite old epoch
	vecLocButtonBL = [dblLeftStart dblBottomStart dblW dblH];
	ptrButtonDrawBlinkBegin = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonBL,'String','Blink Begin','Callback',{@ETC_SetBlinkEpoch,'begin'},'FontSize',10);
	
	%button 4: set blink end; callback: make new epoch and add temporary
	%epoch to list if new, or overwrite old epoch
	vecLocButtonBR = [dblRightStart dblBottomStart dblW dblH];
	ptrButtonDrawBlinkEnd = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonBR,'String','Blink End','Callback',{@ETC_SetBlinkEpoch,'end'},'FontSize',10);
	
	%button 5: set epoch as blink
	vecLocButtonBlinkEpoch = [dblLeftStart dblBottomStart-dblH-0.03 dblW dblH];
	ptrButtonBlinkEpoch = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonBlinkEpoch,'String','Mark Blink','ForegroundColor',[0.4 0 0],'Callback',@ETC_BlinkEpoch,'FontSize',10);
	
	%button 6: keep epoch tracking and set as non-blink
	vecLocButtonKeepEpoch = [dblRightStart vecLocButtonBlinkEpoch(2) dblW dblH];
	ptrButtonKeepEpoch = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonKeepEpoch,'String','Non-blink','ForegroundColor',[0.4 0 0],'Callback',@ETC_KeepEpoch,'FontSize',10);
	
	%button 7: callback: delete selected epoch if selected is not new
	vecLocButtonDelete = [dblLeftStart vecLocButtonKeepEpoch(2)-dblH-0.03 dblW dblH];
	ptrButtonDeleteEpoch = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonDelete,'String','Del Epoch','ForegroundColor',[0.4 0 0],'Callback',@ETC_DeleteEpoch,'FontSize',10);
	
	%button 8: apply all epochs & clear list
	vecLocButtonApply = [dblRightStart vecLocButtonDelete(2) dblW dblH];
	ptrButtonApplyEpochs = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonApply,'String','Apply','ForegroundColor',[0.4 0 0],'Callback',@ETC_ApplyEpochs,'FontSize',10);
	
	%% add pointers
	sFigETC.ptrPanelEpoch = ptrPanelEpoch;
	sFigETC.ptrEpochList = ptrEpochList;
	sFigETC.ptrEpochAutoDetect = ptrEpochAutoDetect;
	sFigETC.ptrEpochInterpolate = ptrEpochInterpolate;
	sFigETC.ptrButtonDrawPupilBegin = ptrButtonDrawPupilBegin;
	sFigETC.ptrButtonDrawPupilEnd = ptrButtonDrawPupilEnd;
	sFigETC.ptrButtonDrawBlinkBegin = ptrButtonDrawBlinkBegin;
	sFigETC.ptrButtonDrawBlinkEnd = ptrButtonDrawBlinkEnd;
	sFigETC.ptrButtonBlinkEpoch = ptrButtonBlinkEpoch;
	sFigETC.ptrButtonKeepEpoch = ptrButtonKeepEpoch;
	sFigETC.ptrButtonDeleteEpoch = ptrButtonDeleteEpoch;
	sFigETC.ptrButtonApplyEpochs = ptrButtonApplyEpochs;
	sFigETC.sEpochTemp = [];
end
function ETC_BlinkEpoch(hObject,eventdata)
	%globals
	global sFigETC;
	
	%if not new, set time to beginning & redraw
	intSelectEpoch = sFigETC.ptrEpochList.Value;
	cellEpochList = sFigETC.ptrEpochList.String;
	if intSelectEpoch < numel(cellEpochList)
		%add blinking to whole epoch
		sFigETC.sPupil.sEpochs(intSelectEpoch).Blinks = ones(size(1,...
			sFigETC.sPupil.sEpochs(intSelectEpoch).EndFrame -sFigETC.sPupil.sEpochs(intSelectEpoch).BeginFrame+1));
		
		%save epoch data
		ETC_SaveEpochs(intSelectEpoch);
		sFigETC.sPupil.sEpochs(intSelectEpoch) = [];
		
		%update gui epoch list
		ETC_GenEpochList(sFigETC.ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
		
		%move to next epoch
		ETC_KeyPress(sFigETC.output,struct('Key','rightarrow','Modifier',[]));
	end
	
	%reset focus
	if exist('hObject','var') && ~isempty(hObject)
		set(hObject, 'enable', 'off');
		drawnow;
		set(hObject, 'enable', 'on');
	end
end
function ETC_KeepEpoch(hObject,eventdata)
	%globals
	global sFigETC;
	
	%if not new, set time to beginning & redraw
	intSelectEpoch = sFigETC.ptrEpochList.Value;
	cellEpochList = sFigETC.ptrEpochList.String;
	if intSelectEpoch < numel(cellEpochList)
		%remove blinking from whole epoch
		sFigETC.sPupil.sEpochs(intSelectEpoch).Blinks = zeros(size(1,...
			sFigETC.sPupil.sEpochs(intSelectEpoch).EndFrame -sFigETC.sPupil.sEpochs(intSelectEpoch).BeginFrame+1));
		
		%save epoch data
		ETC_SaveEpochs(intSelectEpoch);
		sFigETC.sPupil.sEpochs(intSelectEpoch) = [];
		
		%update gui epoch list
		ETC_GenEpochList(sFigETC.ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
		
		%move to next epoch
		ETC_KeyPress(sFigETC.output,struct('Key','rightarrow','Modifier',[]));
	end
	
	%reset focus
	if exist('hObject','var') && ~isempty(hObject)
		set(hObject, 'enable', 'off');
		drawnow;
		set(hObject, 'enable', 'on');
	end
end
function ETC_ApplyEpochs(hObject,eventdata)
	%globals
	global sFigETC;
	
	%if not new, set time to beginning & redraw
	intSelectEpoch = sFigETC.ptrEpochList.Value;
	cellEpochList = sFigETC.ptrEpochList.String;
	if intSelectEpoch < numel(cellEpochList)
		%save epoch data
		ETC_SaveEpochs(intSelectEpoch);
		sFigETC.sPupil.sEpochs(intSelectEpoch) = [];
		
		%update gui epoch list
		cellEpochList = ETC_GenEpochList(sFigETC.ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
		sFigETC.ptrEpochList.Value = numel(cellEpochList);
		
		%redraw traces
		ETC_redraw();
	end
	
	%reset focus
	if exist('hObject','var') && ~isempty(hObject)
		set(hObject, 'enable', 'off');
		drawnow;
		set(hObject, 'enable', 'on');
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
		%set edit flag
		sFigETC.sPupil.vecPupilIsEdited(sFigETC.sPupil.sEpochs(intSelectEpoch).BeginFrame:sFigETC.sPupil.sEpochs(intSelectEpoch).EndFrame) = true;
		
		%remove
		sFigETC.sPupil.sEpochs(intSelectEpoch) = [];
		%update gui epoch list
		cellEpochList = ETC_GenEpochList(sFigETC.ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
		sFigETC.ptrEpochList.Value = numel(cellEpochList);
		
		%set to epoch
		ETC_SelectEpoch();
		
		%redraw traces
		ETC_redraw();
	end
	
	%reset focus
	if exist('hObject','var') && ~isempty(hObject)
		set(hObject, 'enable', 'off');
		drawnow;
		set(hObject, 'enable', 'on');
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
	
	%reset focus
	if exist('hObject','var') && ~isempty(hObject)
		set(hObject, 'enable', 'off');
		drawnow;
		set(hObject, 'enable', 'on');
	end
end
function ETC_ResetFocus(hObject,eventdata)
	%reset focus
	if exist('hObject','var') && ~isempty(hObject)
		set(hObject, 'enable', 'off');
		drawnow;
		set(hObject, 'enable', 'on');
	end
end