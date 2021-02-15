function ET_updateTextInformation(varargin)
	%update cell information window
	global sEyeFig;
	
	%check if data has been loaded
	if isempty(sEyeFig)
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
	if ~iscell(cellText)
		cellText = {cellText};
	end
	cellNewText = [cellOldText(:); cellText(:)];
	intLineNum = 6;
	if numel(cellNewText) > intLineNum,cellNewText(1:(end-intLineNum)) = [];end
	set(sEyeFig.ptrTextInformation, 'string', cellNewText );
	drawnow;
end
