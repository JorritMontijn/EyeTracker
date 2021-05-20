function intNewFrame = ETC_GetCurrentFrame(handle,dummy,strType)
	
	%get globals
	global sETC;
	global sFigETC;
	
	%lock
	uilock(sFigETC);
	
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