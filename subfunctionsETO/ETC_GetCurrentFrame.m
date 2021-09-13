function intNewFrame = ETC_GetCurrentFrame(hObject,eventdata,strType)
	
	%get globals
	global sETC;
	global sFigETC;
	
	%lock
	uilock(sFigETC);
	
	%get modifier
	boolControlPressed = getAsyncKeyState(VirtualKeyCode.VK_CONTROL);
	boolAltPressed = getAsyncKeyState(VirtualKeyCode.VK_MENU);
	
	%% get frame
	if ~exist('strType','var')
		strType = '';
	end
	intOldFrame = sFigETC.intCurFrame;
	intNewFrame = intOldFrame;
	if strcmpi(strType,'Edit')
		intNewFrame = round(str2double(sFigETC.ptrEditFrame.String));
	elseif strcmpi(strType,'Slider')
		intNewFrame = round(sFigETC.ptrSliderFrame.Value);
	elseif strcmpi(strType,'Scroll')
		if boolControlPressed
			intNewFrame = round(intOldFrame + sign(eventdata.VerticalScrollCount*eventdata.VerticalScrollAmount));
		elseif boolAltPressed
			intNewFrame = round(intOldFrame + 10*(eventdata.VerticalScrollCount*eventdata.VerticalScrollAmount));
		else
			intNewFrame = round(intOldFrame + (eventdata.VerticalScrollCount*eventdata.VerticalScrollAmount));
		
		end
		
		if intNewFrame < 1
			intNewFrame = 1;
		elseif intNewFrame > sETC.intF
			intNewFrame = sETC.intF;
		end
	elseif strcmpi(strType,'Click')
		%get time at click
		dblT = eventdata.IntersectionPoint(1);
		intNewFrame = find(sFigETC.sPupil.vecPupilTime>dblT,1);
		if eventdata.Button == 1
			%move to location
			if isempty(intNewFrame),intNewFrame=sETC.intF;end
		elseif eventdata.Button == 3
			%set as interpolation begin/end
			ETC_AddPupilEpoch(hObject,eventdata,intNewFrame);
		elseif eventdata.Button == 2
			%set as blink
			ETC_SetBlinkEpoch(hObject,eventdata,intNewFrame);
		end
	elseif isnumeric(strType)
		intNewFrame = strType;
	end
	
	%check if valid
	if ~(isnumeric(intNewFrame) && intNewFrame > 0 && intNewFrame <= sETC.intF)
		intNewFrame = intOldFrame;
	end
	%match values
	sFigETC.ptrSliderFrame.Value = intNewFrame;
	sFigETC.ptrEditFrame.String = sprintf('%d',intNewFrame);
	sFigETC.intCurFrame = intNewFrame;
	
	%% redraw
	if ~isempty(strType)
		ETC_redraw();
	end
	%unlock
	uiunlock(sFigETC);
	
end