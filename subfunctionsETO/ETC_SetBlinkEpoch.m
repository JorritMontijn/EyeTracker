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