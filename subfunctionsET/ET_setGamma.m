function ET_setGamma(dblGamma,boolRetry)
	%ET_setGamma Set camera Gamma
	
	%get globals
	global sET;
	global sEyeFig;
	
	%get input
	if ~exist('dblGamma','var') || isempty(dblGamma)
		dblGamma = sET.dblGamma;
	end
	if ~exist('boolRetry','var') || isempty(boolRetry)
		boolRetry = true;
	end
	
	%set properties & suppress warning
	try
		strWarnID = 'imaq:gige:adaptorPropertyHealed';
		warning('off',strWarnID);
		sET.objCam.DeviceProperties.Gamma = dblGamma;
		warning('on',strWarnID);
	catch ME
		sET.ME=ME;
		%set to expected value
		cellStr = strsplit(sET.ME.message(1:(end-1)),'=');
		if boolRetry
			dblGamma = str2double(cellStr{end});
			ET_setGamma(dblGamma,false);
		else
			rethrow(ME);
		end
	end
	
	%update information to match new Gamma
	dblNewGamma = sET.objCam.DeviceProperties.Gamma;
	sET.dblGamma = dblNewGamma;
	set(sEyeFig.ptrEditGamma,'String',sprintf('%.2f',dblNewGamma));
end