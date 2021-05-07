function ETP_DeleteFcn
	%UNTITLED Summary of this function goes here
	%   Detailed explanation goes here
	global sETP;
	global sFigETP;
	delete(sFigETP.output);
	clear('sFigETP');
	sETP.boolForceQuit = true;
end

