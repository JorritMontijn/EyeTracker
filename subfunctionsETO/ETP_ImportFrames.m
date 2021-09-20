function ETP_ImportFrames(handles,dummy,boolInit)
	
	%get globals
	global sETP;
	global sFigETP;
	
	%get import #
	sETP.intImportPoints = str2double(sFigETP.ptrEditImportPoints.String);
	sETP.intImportStretch = str2double(sFigETP.ptrEditImportStretch.String);
	
	% message
	ptrMsg = dialog('Position',[600 400 250 50],'Name','Library Compilation');
	ptrText = uicontrol('Parent',ptrMsg,...
		'Style','text',...
		'Position',[20 00 210 40],...
		'FontSize',11,...
		'String',sprintf('Accessing video...'));
	movegui(ptrMsg,'center')
	drawnow;
	
	%get data
	intTotFrames = sETP.objVid.NumberOfFrames;
	
	%import frames
	vecFrames = unique(round(linspace(1,intTotFrames,sETP.intImportPoints+2)));
	vecFrames = vecFrames(2:(end-1));
	vecFrames((vecFrames + sETP.intImportStretch - 1) > intTotFrames) = [];
	intUseFrameNr = numel(vecFrames);
	sETP.intImportStretch = intUseFrameNr;
	sFigETP.ptrEditImportPoints.String = num2str(intUseFrameNr);
	matFrames = repmat(read(sETP.objVid,1),[1 1 1 intUseFrameNr sETP.intImportStretch]);
	for intFrameIdx=1:intUseFrameNr
		ptrText.String = sprintf('Loading frame %d (%d/%d).',vecFrames(intFrameIdx),intFrameIdx,sETP.intImportPoints);
		for intFrameInStretch=1:sETP.intImportStretch
			matFrames(:,:,:,intFrameIdx,intFrameInStretch) = read(sETP.objVid,vecFrames(intFrameIdx)+intFrameInStretch-1);
		end
	end
	sETP.matFrames = matFrames;
	[intY,intX,intC,intF,intS] = size(matFrames);
	sETP.intY = intY;
	sETP.intX = intX;
	sETP.intC = intC;
	sETP.intF = intF;
	sETP.intS = intS;
	sETP.vecSampleFrames = vecFrames;
	
	%close msg
	delete(ptrMsg);
	
	%redraw?
	if exist('boolInit','var') && boolInit
		%do nothing
	else
		%redraw
		ETP_DetectEdit();
	end
end