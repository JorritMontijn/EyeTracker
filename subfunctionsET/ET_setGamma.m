function ET_setGamma(dblGamma)
	%ET_setGamma Set camera gain
	
	%get globals
	global sET;
	global sEyeFig;
	
	%get input
	if ~exist('dblGamma','var') || isempty(dblGamma)
		dblGamma = sET.dblGamma;
	end
	
	%set properties & suppress warning
	sET.objCam.DeviceProperties.Gamma = dblGamma;
	
	%update information to match new gain
	dblNewGamma = sET.objCam.DeviceProperties.Gamma;
	sET.dblGamma = dblNewGamma;
	set(sEyeFig.ptrEditGamma,sprintf('%.1f',dblNewGamma));
end