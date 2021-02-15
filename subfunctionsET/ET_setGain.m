function ET_setGain(dblGain,boolRetry)
	%ET_setGain Set camera gain
	
	%get globals
	global sET;
	global sEyeFig;
	
	%get input
	if ~exist('dblGain','var') || isempty(dblGain)
		dblGain = sET.dblGain;
	end
	if ~exist('boolRetry','var') || isempty(boolRetry)
		boolRetry = true;
	end
	
	%set properties & suppress warning
	try
		strWarnID = 'imaq:gige:adaptorPropertyHealed';
		warning('off',strWarnID);
		sET.objCam.DeviceProperties.Gain = dblGain;
		warning('on',strWarnID);
	catch ME
		sET.ME=ME;
		%set to expected value
		cellStr = strsplit(sET.ME.message(1:(end-1)),'=');
		if boolRetry
			dblGain = str2double(cellStr{end});
			ET_setGain(dblGain,false);
		else
			rethrow(ME);
		end
	end
	
	%update information to match new gain
	dblNewGain = sET.objCam.DeviceProperties.Gain;
	sET.dblGain = dblNewGain;
	set(sEyeFig.ptrEditGain,'String',sprintf('%.2f',dblNewGain));
end