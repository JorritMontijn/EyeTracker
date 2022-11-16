function strTime = getTime()
	%UNTITLED3 Summary of this function goes here
	%   Detailed explanation goes here
	
	vecTime = fix(clock);
	strTime = sprintf('%02d:%02d:%02d',vecTime(4:6));
end

