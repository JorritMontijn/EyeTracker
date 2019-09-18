function ET_enableForceQuit(varargin)
	%UNTITLED Summary of this function goes here
	
	%% get globals
	global sEyeFig
	
	%% enable force quit
	sEyeFig.boolIsBusy = false;
	ET_updateTextInformation('Force quit is now enabled');
end

