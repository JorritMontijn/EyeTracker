function boolAddedEpoch = ETC_SetBlinkEpoch(hObject,eventdata,strType)
	%globals
	global sFigETC;
	%get temporary epoch
	sEpoch = sFigETC.sEpochTemp;
	
	%get modifier
	boolControlPressed = getAsyncKeyState(VirtualKeyCode.VK_CONTROL);
	boolAltPressed = getAsyncKeyState(VirtualKeyCode.VK_MENU);
	
	%if not new, create new
	cellEpochList = sFigETC.ptrEpochList.String;
	intSelectedEpoch = sFigETC.ptrEpochList.Value;
	if isempty(sEpoch) || intSelectedEpoch ~= numel(cellEpochList)
		%gen
		sEpoch = ETC_GenEmptyEpochs();
		sEpoch(1).BeginFrame = nan;
		sEpoch(1).EndFrame = nan;
	end
	sFigETC.ptrEpochList.Value = numel(cellEpochList);
	
	
	%get current frame
	if strcmpi(strType,'begin')
		intCurrFrame = sFigETC.intCurFrame;
		sEpoch.BeginFrame = intCurrFrame;
	elseif strcmpi(strType,'end')
		intCurrFrame = sFigETC.intCurFrame;
		sEpoch.EndFrame = intCurrFrame;
	elseif isscalar(strType) && isint(strType) && strType > 0
		%get data
		vecT = sFigETC.ptrAxesX.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesX.Children,'UniformOutput',false),'line')).XData;
		%check end
		intCurrFrame = strType;
		if intCurrFrame > numel(vecT),return;end
		
		%assign
		if ~isnan(sEpoch.BeginFrame) && isnan(sEpoch.EndFrame)
			sEpoch.EndFrame = intCurrFrame;
		else
			sEpoch.BeginFrame = intCurrFrame;
		end
	else
		error([mfilename ':TypeMissing'],'Type missing');
	end
	
	%check if epoch is complete
	boolAddedEpoch = false;
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
		sEpoch.Radius2 = [];
		sEpoch.Angle = [];
		if boolControlPressed || boolAltPressed
			sEpoch.Blinks = zeros(1,intFrames);
		else
			sEpoch.Blinks = ones(1,intFrames);
		end
		
		%remove temporary epoch
		sFigETC.sEpochTemp = [];
		%update epoch list
		sFigETC.sPupil.sEpochs(intSelectedEpoch) = sEpoch;
		%reorder
		[dummy,vecReorder] = sort(cell2vec({sFigETC.sPupil.sEpochs.BeginFrame}));
		sFigETC.sPupil.sEpochs = sFigETC.sPupil.sEpochs(vecReorder);
		%update gui epoch list
		cellEpochList = ETC_GenEpochList(sFigETC.ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
		sFigETC.ptrEpochList.Value = find(vecReorder==intSelectedEpoch);
		boolAddedEpoch = true;
		
		%set to epoch start
		ETC_GetCurrentFrame([],[],sEpoch.BeginFrame);
		
		%redraw traces
		ETC_redraw();
	else
		%add temporary epoch
		sFigETC.sEpochTemp = sEpoch;
	end
end