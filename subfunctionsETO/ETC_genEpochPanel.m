function ETC_genEpochPanel(ptrMainGUI,vecLocation)
	
	%% get globals
	global sETC;
	global sFigETC;
	
	%% make panel
	ptrPanelEpoch = uipanel('Parent',ptrMainGUI);
	vecColor = get(ptrMainGUI,'Color');
	set(ptrPanelEpoch,'Position',vecLocation,'BackgroundColor',vecColor,'Title','Epoch Annotation','FontSize',10);
	ptrPanelEpoch.Units = 'normalized';
	
	%% generate threshold corrections
	%set locations
	vecLocList = [0.05 0.64 0.9 0.1];
	vecLocRadioGroup = [vecLocList(1) vecLocList(2)-0.20 vecLocList(3) 0.19];
	dblW = 0.44;
	dblH = 0.10;
	dblLeftStart = vecLocList(1);
	dblRightStart = vecLocList(1)+dblW+0.02;
	dblTopStart = vecLocRadioGroup(2)-dblH-0.02;
	dblBottomStart = dblTopStart-dblH-0.01;
	dblBS = 2/3; %button size
	
	%text
	vecLocTextTop = [0.05 0.9 0.9 0.08];
	ptrTextParameters = uicontrol(ptrPanelEpoch,'Style','text','Units','normalized','Position',vecLocTextTop,'String','Parameter corrections','FontSize',10,'BackgroundColor',[1 1 1]);
	
	%pupil
	vecLocTextPupil = [dblLeftStart 0.84 dblW*dblBS 0.06];
	ptrTextPupil = uicontrol(ptrPanelEpoch,'Style','text','Units','normalized','Position',vecLocTextPupil,'String','Pupil','FontSize',10,'BackgroundColor',vecColor);
	
	%edit box for pupil factor
	ptrEditPupil= uicontrol('Style','edit','Parent',ptrPanelEpoch,'FontSize',10,...
		'Units','normalized','Position',[vecLocTextPupil(1) vecLocTextPupil(2)-0.1 dblW*dblBS 0.1],...
		'String',sprintf('%.3f',sETC.dblPupilFactor),...
		'Callback',@ETC_EditPupilCallback,...
		'Tooltip',sprintf('Correction factor for pupil luminance threshold'));
	
	%reflection
	vecLocTextReflection = [dblLeftStart+dblW*dblBS+0.01 vecLocTextPupil(2) dblW*dblBS vecLocTextPupil(4)];
	ptrTextReflection = uicontrol(ptrPanelEpoch,'Style','text','Units','normalized','Position',vecLocTextReflection + [-0.03 0 0.06 0],'String','Reflection','FontSize',10,'BackgroundColor',vecColor);
	
	%edit box for reflection factor
	ptrEditReflection= uicontrol('Style','edit','Parent',ptrPanelEpoch,'FontSize',10,...
		'Units','normalized','Position',[vecLocTextReflection(1) vecLocTextReflection(2)-0.1 dblW*dblBS 0.1],...
		'String',sprintf('%.3f',sETC.dblReflectionFactor),...
		'Callback',@ETC_EditReflectionCallback,...
		'Tooltip',sprintf('Correction factor for reflection luminance threshold'));
	
	%circular mask
	vecLocTextMask = [dblLeftStart+2*dblW*dblBS+0.02 vecLocTextPupil(2) dblW*dblBS vecLocTextPupil(4)];
	ptrTextMask = uicontrol(ptrPanelEpoch,'Style','text','Units','normalized','Position',vecLocTextMask + [0.02 0 -0.04 0],'String','Mask','FontSize',10,'BackgroundColor',vecColor);
	
	%edit box for reflection factor
	ptrEditMask= uicontrol('Style','edit','Parent',ptrPanelEpoch,'FontSize',10,...
		'Units','normalized','Position',[vecLocTextMask(1) vecLocTextMask(2)-0.1 dblW*dblBS 0.1],...
		'String',sprintf('%.3f',sETC.dblCircMaskSize),...
		'Callback',@ETC_EditMaskCallback,...
		'Tooltip',sprintf('Size of circular mask'));
	
	%% generate list elements
	%list of epochs
	if ~isfield(sFigETC.sPupil,'sEpochs') || isempty(sFigETC.sPupil.sEpochs)
		sEpochs = ETC_GenEmptyEpochs;
		sEpochs(:) = [];
		sFigETC.sPupil.sEpochs = sEpochs;
	end
	
	
	%generate list
	%vecLocList = [5 170 120 20];
	ptrEpochList = uicontrol(ptrPanelEpoch,'Style','popupmenu','Units','normalized','Position',vecLocList,'String',{''},'Callback',@ETC_SelectEpoch,'FontSize',10,...
		'Tooltip',sprintf('Select an epoch from the list'));
	
	%create epochs from fixed data
	[cellEpochList,sFigETC.sPupil.sEpochs] = ETC_GenEpochList(ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime,sFigETC.sPupil);
	ptrEpochList.Value = numel(cellEpochList);
	
	%generate radio buttons
	ptrGroup = uibuttongroup(ptrPanelEpoch,'Units','normalized','Position',vecLocRadioGroup);
	vecLocRadio1 = [0 0 1 0.5];
	ptrEpochAutoDetect = uicontrol(ptrGroup,'Style','radiobutton','Units','normalized','Position',vecLocRadio1,'String','Re-detect','Callback',@ETC_ResetFocus,'FontSize',10,...
		'Tooltip',sprintf('Each frame in an epoch will be detected using the pupil detection algorithm \nKeyboard shortcut: r'));
	vecLocRadio2 = [0 0.5 1 0.5];
	ptrEpochInterpolate = uicontrol(ptrGroup,'Style','radiobutton','Units','normalized','Position',vecLocRadio2,'String','Interpolate','Callback',@ETC_ResetFocus,'FontSize',10,...
		'Tooltip',sprintf('The pupil size/location will be interpolated between the first and last frames of the epoch \nKeyboard shortcut: i'));
	
	%% populate panel based on current epoch
	%button 1: draw pupil begin; callback: draw pupil, save as temporary
	%epoch if new, or overwrite old epoch
	vecLocButtonTL = [dblLeftStart dblTopStart dblW dblH];
	ptrButtonDrawPupilBegin = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonTL,'String','Draw Begin','Callback',{@ETC_AddPupilEpoch,'begin'},'FontSize',10,...
		'Tooltip',sprintf('Create new epoch and draw the pupil manually \nTip: you can also use the right mouse button to use the detected pupil at the frame you click at'));
	
	%button 2: draw pupil end; callback: draw pupil, make new epoch and add
	%temporary epoch to list if new, or overwrite old epoch
	vecLocButtonTR = [dblRightStart dblTopStart dblW dblH];
	ptrButtonDrawPupilEnd = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonTR,'String','Draw End','Callback',{@ETC_AddPupilEpoch,'end'},'FontSize',10,...
		'Tooltip',sprintf('Finish new epoch and draw the pupil manually \nTip: you can also use the right mouse button to use the detected pupil at the frame you click at'));
	
	%button 3: set blink begin; callback: save as temporary epoch if new,
	%or overwrite old epoch
	vecLocButtonBL = [dblLeftStart dblBottomStart dblW dblH];
	ptrButtonDrawBlinkBegin = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonBL,'String','Blink Begin','Callback',{@ETC_SetBlinkEpoch,'begin'},'FontSize',10,...
		'Tooltip',sprintf('Create new epoch and mark as blinking period \nTip: you can also use the middle mouse button'));
	
	%button 4: set blink end; callback: make new epoch and add temporary
	%epoch to list if new, or overwrite old epoch
	vecLocButtonBR = [dblRightStart dblBottomStart dblW dblH];
	ptrButtonDrawBlinkEnd = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonBR,'String','Blink End','Callback',{@ETC_SetBlinkEpoch,'end'},'FontSize',10,...
		'Tooltip',sprintf('Finish new epoch and mark as blinking period \nTip: you can also use the middle mouse button'));
	
	%button 5: set epoch as blink
	vecLocButtonBlinkEpoch = [dblLeftStart dblBottomStart-dblH-0.01 dblW*dblBS dblH];
	ptrButtonBlinkEpoch = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonBlinkEpoch,'String','Blink','ForegroundColor',[0.4 0 0],'Callback',@ETC_BlinkEpoch,'FontSize',10,...
		'Tooltip',sprintf('Set selected epoch as blink\nKeyboard shortcut: b'));
	
	%button 6: keep epoch tracking and set as non-blink
	vecLocButtonKeepEpoch = [dblLeftStart+dblW*dblBS+0.01 vecLocButtonBlinkEpoch(2) dblW*dblBS dblH];
	ptrButtonKeepEpoch = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonKeepEpoch,'String','Keep','ForegroundColor',[0.4 0 0],'Callback',@ETC_KeepEpoch,'FontSize',10,...
		'Tooltip',sprintf('Keep selected epoch as non-blink\nKeyboard shortcut: n or k'));
	
	%button 7: recalculate current epoch
	vecLocButtonRecalc = [dblLeftStart+2*dblW*dblBS+0.02 vecLocButtonKeepEpoch(2) dblW*dblBS dblH];
	ptrButtonRecalcEpoch = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonRecalc,'String','Rerun','ForegroundColor',[0.4 0 0],'Callback',@ETC_RecalcEpoch,'FontSize',10,...
		'Tooltip',sprintf('Rerun selected epoch \nKeyboard shortcut: i for interpolation, r for detection'));
	
	%button 8: callback: delete selected epoch if selected is not new
	vecLocButtonDelete = [dblLeftStart vecLocButtonKeepEpoch(2)-dblH-0.01 dblW dblH];
	ptrButtonDeleteEpoch = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonDelete,'String','Del Epoch','ForegroundColor',[0.4 0 0],'Callback',@ETC_DeleteEpoch,'FontSize',10,...
		'Tooltip',sprintf('Delete selected epoch \nKeyboard shortcut: d'));
	
	%button 9: apply all epochs & clear list
	vecLocButtonApply = [dblRightStart vecLocButtonDelete(2) dblW dblH];
	ptrButtonApplyEpochs = uicontrol(ptrPanelEpoch,'Style','pushbutton','Units','normalized','Position',vecLocButtonApply,'String','Apply','ForegroundColor',[0.4 0 0],'Callback',@ETC_ApplyEpochs,'FontSize',10,...
		'Tooltip',sprintf('Apply selected epoch \nKeyboard shortcut: a'));
	
	%% add pointers
	sFigETC.ptrPanelEpoch = ptrPanelEpoch;
	sFigETC.ptrTextParameters = ptrTextParameters;
	sFigETC.ptrTextPupil = ptrTextPupil;
	sFigETC.ptrTextReflection = ptrTextReflection;
	sFigETC.ptrTextMask = ptrTextMask;
	sFigETC.ptrEditReflection = ptrEditReflection;
	sFigETC.ptrEditPupil = ptrEditPupil;
	sFigETC.ptrEditMask = ptrEditMask;
	sFigETC.ptrEpochList = ptrEpochList;
	sFigETC.ptrEpochAutoDetect = ptrEpochAutoDetect;
	sFigETC.ptrEpochInterpolate = ptrEpochInterpolate;
	sFigETC.ptrButtonDrawPupilBegin = ptrButtonDrawPupilBegin;
	sFigETC.ptrButtonDrawPupilEnd = ptrButtonDrawPupilEnd;
	sFigETC.ptrButtonDrawBlinkBegin = ptrButtonDrawBlinkBegin;
	sFigETC.ptrButtonDrawBlinkEnd = ptrButtonDrawBlinkEnd;
	sFigETC.ptrButtonBlinkEpoch = ptrButtonBlinkEpoch;
	sFigETC.ptrButtonKeepEpoch = ptrButtonKeepEpoch;
	sFigETC.ptrButtonRecalcEpoch = ptrButtonRecalcEpoch;
	sFigETC.ptrButtonDeleteEpoch = ptrButtonDeleteEpoch;
	sFigETC.ptrButtonApplyEpochs = ptrButtonApplyEpochs;
	sFigETC.sEpochTemp = [];
end
function ETC_RecalcEpoch(hObject,eventdata)
	%globals
	global sFigETC;
	
	%if not new, set time to beginning & redraw
	intSelectEpoch = sFigETC.ptrEpochList.Value;
	cellEpochList = sFigETC.ptrEpochList.String;
	if intSelectEpoch < numel(cellEpochList)
		%remove blinking from whole epoch
		sFigETC.sPupil.sEpochs(intSelectEpoch).Blinks = zeros(size(1,...
			sFigETC.sPupil.sEpochs(intSelectEpoch).EndFrame -sFigETC.sPupil.sEpochs(intSelectEpoch).BeginFrame+1));
		
		%recalculate
		ETC_AddPupilEpoch([],[],'recalc');
	end
	
	%reset focus
	if exist('hObject','var') && ~isempty(hObject)
		set(hObject, 'enable', 'off');
		drawnow;
		set(hObject, 'enable', 'on');
	end
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
function ETC_EditPupilCallback(hObject,eventdata)
	%globals
	global sETC;
	
	%get numerical value
	dblPupFac = str2double(hObject.String);
	if ~isempty(dblPupFac) && ~isnan(dblPupFac) && dblPupFac > 0
		sETC.dblPupilFactor = dblPupFac;
	end
	hObject.String = sprintf('%.3f',sETC.dblPupilFactor);
end
function ETC_EditReflectionCallback(hObject,eventdata)
	%globals
	global sETC;
	
	%get numerical value
	dblReflFac = str2double(hObject.String);
	if ~isempty(dblReflFac) && ~isnan(dblReflFac) && dblReflFac > 0
		sETC.dblReflectionFactor = dblReflFac;
	end
	hObject.String = sprintf('%.3f',sETC.dblReflectionFactor);
	
	%redraw
	ETC_redraw();
end
function ETC_EditMaskCallback(hObject,eventdata)
	%globals
	global sETC;
	
	%get numerical value
	dblCircMaskSize = str2double(hObject.String);
	if ~isempty(dblCircMaskSize) && ~isnan(dblCircMaskSize) && dblCircMaskSize > 0 && dblCircMaskSize <= 1
		sETC.dblCircMaskSize = dblCircMaskSize;
	end
	hObject.String = sprintf('%.3f',sETC.dblCircMaskSize);
	
	%redraw
	ETC_redraw();
end

	