function ETC_SaveEpochs()
	%get globals
	global sETC;
	global sFigETC;
	
	%get file
	sPupil = sFigETC.sPupil;
	strTargetFile = fullpath(sPupil.strProcPath,sPupil.strProcFile);
	
	if isfield(sPupil,'sEpochs') && ~isempty(sPupil.sEpochs)
		%message
		ptrMsg = dialog('Position',[600 400 250 50],'Name','Saving data');
		ptrText = uicontrol('Parent',ptrMsg,...
			'Style','text',...
			'Position',[20 00 210 40],...
			'FontSize',11,...
			'String','Compiling and saving data...');
		movegui(ptrMsg,'center')
		drawnow;
		
		%extract old data
		vecPupilFixedCenterX = sPupil.vecPupilFixedCenterX;
		vecPupilFixedCenterY = sPupil.vecPupilFixedCenterY;
		vecPupilFixedRadius = sPupil.vecPupilFixedRadius;
		if ~isfield(sPupil,'vecPupilFixedBlinks')
			%generate blinkiness
			vecPupilFixedBlinks = zeros(size(vecPupilFixedRadius));
		else
			vecPupilFixedBlinks = sPupil.vecPupilFixedBlinks;
		end
		
		%construct new traces
		sEpochs = sFigETC.sPupil.sEpochs;
		intEpochNum = numel(sEpochs);
		for intEpoch=1:intEpochNum
			sEpoch = sEpochs(intEpoch);
			intBegin = sEpoch.BeginFrame;
			intEnd = sEpoch.EndFrame;
			if isempty(sEpoch.Blinks)
				vecPupilFixedCenterX(intBegin:intEnd) = sEpoch.CenterX;
				vecPupilFixedCenterY(intBegin:intEnd) = sEpoch.CenterY;
				vecPupilFixedRadius(intBegin:intEnd) = sEpoch.Radius;
			else
				vecPupilFixedBlinks(intBegin:intEnd) = sEpoch.Blinks;
			end
		end
		
		%overwrite 'Fixed' variables
		sPupil.vecPupilFixedCenterX = vecPupilFixedCenterX;
		sPupil.vecPupilFixedCenterY = vecPupilFixedCenterY;
		sPupil.vecPupilFixedRadius = vecPupilFixedRadius;
		sPupil.vecPupilFixedBlinks = vecPupilFixedBlinks;
		
		%save
		save(strTargetFile,'sPupil');
		
		%add to global
		sFigETC.sPupil = sPupil;
		
		%close msg
		delete(ptrMsg);
	end
end