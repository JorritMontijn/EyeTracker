function ETC_DeleteFcn
	%UNTITLED Summary of this function goes here
	%   Detailed explanation goes here
	global sETC;
	global sFigETC;
	delete(sFigETC.output);
	clear('sFigETC');
	sETC.boolForceQuit = true;
end

