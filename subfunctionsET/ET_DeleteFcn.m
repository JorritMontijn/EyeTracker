%% closing function
function ET_DeleteFcn(varargin)
	%get globals
	global sEyeFig
	
	%stop timer
	stop(sEyeFig.objTimer);
end