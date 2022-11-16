function hPlot = plotRect(varargin)
	%plotRect Plot rectangle box
	%   hPlot = plotRect(handle,vecRect,vararg)
	
	if numel(varargin{1}) == 4
		handle = gca;
		vecRect = varargin{1};
		vararg = {varargin(2:end)};
	else
		handle = varargin{1};
		vecRect = varargin{2};
		vararg = varargin(3:end);
	end
	
	vecX = [vecRect(1) vecRect(1) vecRect(1)+vecRect(3) vecRect(1)+vecRect(3) vecRect(1)];
	vecY = [vecRect(2) vecRect(2)+vecRect(4) vecRect(2)+vecRect(4) vecRect(2) vecRect(2)];
	hPlot=plot(handle,vecX,vecY,vararg{:});
end

