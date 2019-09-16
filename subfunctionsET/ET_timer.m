function ET_timer(varargin)
	%UNTITLED Summary of this function goes here
	%   Detailed explanation goes here
	%Enable,'off'
	%check if windows machine
	
	%% get globals
	global sEyeFig
	
	%% set disk I/O
	if ispc
		[intFlagOut,strReturn]=system('typeperf -sc 0.1 -si 1 "\LogicalDisk(C:)\% Disk Time');
		
		cellLines =strsplit(strReturn,newline);
		strFracActive = getFlankedBy(cellLines{3},'","','"');
		set(sEyeFig.ptrTextVidOutDiskIO,'String',strFracActive(1:5));
	else
		
	end
end

