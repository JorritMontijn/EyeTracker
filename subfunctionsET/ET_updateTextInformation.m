function ET_updateTextInformation(varargin)
	%update cell information window
	global sEyeFig;
	global sET;
	
	%check if data has been loaded
	if isempty(sEyeFig) || (isempty(sET) && nargin == 0)
		return;
	else
		try
			cellOldText = get(sEyeFig.ptrTextInformation, 'string');
		catch
			return;
		end
	end
	
	%check if msg is supplied, otherwise ...
	if nargin > 0
		cellText = varargin{1};
	else
		cellText = {'...'};
	end
	if numel(cellText) > 6,cellText(7:end) = [];end
	set(sEyeFig.ptrTextInformation, 'string', cellText );
	drawnow;
end
