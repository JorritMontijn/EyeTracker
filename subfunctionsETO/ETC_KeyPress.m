function ETC_KeyPress(hMain,eventdata)
	
	%dummy for testing
	global sFigETC;
	if ~exist('eventdata','var')
		eventdata = struct;
		eventdata.Key = 'r';
		eventdata.Modifier = [];
	end
	
	% Get guidata
	if toc(sFigETC.lastPress) < 0.1;return;end
	sFigETC.lastPress = tic;
	
	if strcmp(eventdata.Key,'rightarrow') || strcmp(eventdata.Key,'leftarrow')
		%get current time
		intCurFrame = sFigETC.intCurFrame;
		vecDist = cell2vec({sFigETC.sPupil.sEpochs.BeginFrame}) - intCurFrame;
		
		%find new epoch
		if strcmp(eventdata.Key,'rightarrow')
			intSelectEpoch = find(vecDist>0,1,'first');
		else
			intSelectEpoch = find(vecDist<0,1,'last');
		end
		if isempty(intSelectEpoch),return;end
		
		%if not new, set time to beginning & redraw
		sFigETC.ptrEpochList.Value = intSelectEpoch;
		
		%set to beginning of epoch
		sEpoch = sFigETC.sPupil.sEpochs(intSelectEpoch);
		ETC_GetCurrentFrame([],[],sEpoch.BeginFrame);
		
	elseif strcmp(eventdata.Key,'f1')
		
		%bring up controls
		ETC_DisplayHelp();
		
	elseif strcmp(eventdata.Key,'b')
		%mark set as blink
		feval(sFigETC.ptrButtonBlinkEpoch.Callback);
		ETC_redraw();
	elseif strcmp(eventdata.Key,'n') || strcmp(eventdata.Key,'k')
		%mark as non-blink
		feval(sFigETC.ptrButtonKeepEpoch.Callback);
		ETC_redraw();
	elseif strcmp(eventdata.Key,'a')
		%apply epoch
		feval(sFigETC.ptrButtonApplyEpochs.Callback);
		ETC_redraw();
	elseif strcmp(eventdata.Key,'r')
		%recalc epoch
		feval(sFigETC.ptrButtonRecalcEpoch.Callback);
		ETC_redraw();
	elseif strcmp(eventdata.Key,'d')
		%delete epoch
		feval(sFigETC.ptrButtonDeleteEpoch.Callback);
		ETC_redraw();
	end
end

