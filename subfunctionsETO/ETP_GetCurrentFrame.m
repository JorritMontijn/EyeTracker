function intNewFrame = ETP_GetCurrentFrame(handle,dummy,strType)
	
	%get globals
	global sETP;
	global sFigETP;
	
	%% get frame
	if ~exist('strType','var')
		strType = '';
	end
	intOldFrame = sFigETP.intCurFrame;
	intNewFrame = intOldFrame;
	if strcmpi(strType,'Edit')
		intNewFrame = round(str2double(sFigETP.ptrEditFrame.String));
	elseif strcmpi(strType,'Slider')
		intNewFrame = round(sFigETP.ptrSliderFrame.Value);
	end
	
	%check if valid
	if ~(isnumeric(intNewFrame) && intNewFrame > 0 && intNewFrame <= sETP.intF)
		intNewFrame = intOldFrame;
	end
	%match values
	sFigETP.ptrSliderFrame.Value = intNewFrame;
	sFigETP.ptrEditFrame.String = sprintf('%d',intNewFrame);
	sFigETP.intCurFrame = intNewFrame;
	
	%% redraw
	if ~isempty(strType)
		ETP_DetectEdit();
	end
end