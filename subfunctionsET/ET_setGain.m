function ET_setGain(dblGain)
	%ET_setGain Set camera gain
	
	%get globals
	global sET;
	global sEyeFig;
	
	%get input
	if ~exist('dblGain','var') || isempty(dblGain)
		dblGain = sET.dblGain;
	end
	
	%set properties & suppress warning
	sET.objCam.DeviceProperties.Gain = dblGain;
	
	%update information to match new gain
	dblNewGain = sET.objCam.DeviceProperties.Gain;
	sET.dblGain = dblNewGain;
	set(sEyeFig.ptrEditGain,sprintf('%.1f',dblNewGain));
end