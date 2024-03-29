function sPupil = ETC_SaveEpochs(intSelectEpoch)
	%get globals
	global sETC;
	global sFigETC;
	
	%get file
	sPupil = sFigETC.sPupil;
	
	if isfield(sPupil,'sEpochs') && ~isempty(sPupil.sEpochs)
		%message
		ptrMsg = dialog('Position',[600 400 250 50],'Name','Applying epoch data');
		ptrText = uicontrol('Parent',ptrMsg,...
			'Style','text',...
			'Position',[20 00 210 40],...
			'FontSize',11,...
			'String','Compiling and applying epoch data...');
		movegui(ptrMsg,'center')
		drawnow;
		
		%extract old data
		vecPupilFixedCenterX = sPupil.vecPupilFixedCenterX;
		vecPupilFixedCenterY = sPupil.vecPupilFixedCenterY;
		vecPupilFixedRadius = sPupil.vecPupilFixedRadius;
		vecPupilFixedRadius2 = sPupil.vecPupilFixedRadius2;
		vecPupilFixedAngle = sPupil.vecPupilFixedAngle;
		if ~isfield(sPupil,'vecPupilFixedBlinks')
			%generate blinkiness
			vecPupilFixedBlinks = zeros(size(vecPupilFixedRadius));
		else
			vecPupilFixedBlinks = sPupil.vecPupilFixedBlinks;
		end
		if ~isfield(sPupil,'vecPupilIsEdited')
			%assign edit
			vecPupilIsEdited = false(size(vecPupilFixedRadius));
		else
			vecPupilIsEdited = sPupil.vecPupilIsEdited;
		end
		if ~isfield(sPupil,'vecPupilIsDetected')
			%assign edit
			vecPupilIsDetected = true(size(vecPupilFixedRadius));
		else
			vecPupilIsDetected = sPupil.vecPupilIsDetected;
		end
		
		%construct new traces
		sEpochs = sFigETC.sPupil.sEpochs;
		intEpochNum = numel(sEpochs);
		if ~exist('intSelectEpoch','var')
			vecApplyEpochs = 1:intEpochNum;
		else
			vecApplyEpochs = intSelectEpoch;
		end
		for intEpoch=vecApplyEpochs
			sEpoch = sEpochs(intEpoch);
			intBegin = sEpoch.BeginFrame;
			intEnd = sEpoch.EndFrame;
			if isempty(sEpoch.Blinks)
				sEpoch.Blinks = vecPupilFixedBlinks(intBegin:intEnd);
			end
			if isempty(sEpoch.IsDetected)
				sEpoch.IsDetected = false(size(sEpoch.Blinks));
			end
			if ~isempty(sEpoch.CenterX)
				vecPupilFixedCenterX(intBegin:intEnd) = sEpoch.CenterX;
				vecPupilFixedCenterY(intBegin:intEnd) = sEpoch.CenterY;
				vecPupilFixedRadius(intBegin:intEnd) = sEpoch.Radius;
				vecPupilFixedRadius2(intBegin:intEnd) = sEpoch.Radius2;
				vecPupilFixedAngle(intBegin:intEnd) = sEpoch.Angle;
			end
			vecPupilFixedBlinks(intBegin:intEnd) = sEpoch.Blinks;
			vecPupilIsEdited(intBegin:intEnd) = true;
			vecPupilIsDetected(intBegin:intEnd) = sEpoch.IsDetected;
		end
		
		%overwrite 'Fixed' variables
		sPupil.vecPupilFixedCenterX = vecPupilFixedCenterX;
		sPupil.vecPupilFixedCenterY = vecPupilFixedCenterY;
		sPupil.vecPupilFixedRadius = vecPupilFixedRadius;
		sPupil.vecPupilFixedRadius2 = vecPupilFixedRadius2;
		sPupil.vecPupilFixedAngle = vecPupilFixedAngle;
		sPupil.vecPupilFixedBlinks = vecPupilFixedBlinks;
		sPupil.vecPupilIsEdited = vecPupilIsEdited;
		sPupil.vecPupilIsDetected = vecPupilIsDetected;
		
		%apply to figure
		sFigETC.ptrAxesX.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesX.Children,'UniformOutput',false),'line')).YData = sPupil.vecPupilFixedCenterX;
		sFigETC.ptrAxesY.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesY.Children,'UniformOutput',false),'line')).YData = sPupil.vecPupilFixedCenterY;
		sFigETC.ptrAxesA.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesA.Children,'UniformOutput',false),'line')).YData = pi*sPupil.vecPupilFixedRadius.*sPupil.vecPupilFixedRadius2;
		sFigETC.ptrAxesB.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesB.Children,'UniformOutput',false),'line')).YData = double(sPupil.vecPupilFixedBlinks);
		%add to global
		sFigETC.sPupil = sPupil;
		
		%close msg
		delete(ptrMsg);
	end
end