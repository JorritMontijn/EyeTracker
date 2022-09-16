function [cellEpochList,sEpochs] = ETC_GenEpochList(ptrEpochList,sEpochs,vecPupilTime,sPupil)
	%vecPupilFixedCenterX(intBegin:intEnd) = sEpoch.CenterX;
	%vecPupilFixedCenterY(intBegin:intEnd) = sEpoch.CenterY;
	%vecPupilFixedRadius(intBegin:intEnd) = sEpoch.Radius;
	%vecPupilFixedBlinks(intBegin:intEnd) = sEpoch.Blinks;
	
	%create epochs from sPupil if this is creation
	if exist('sPupil','var') && sum((sPupil.vecPupilFixedPoints & ~sPupil.vecPupilIsEdited) > 0) && numel(sEpochs) == 0
		%create epochs from sPupil
		indAddEpochs = sPupil.vecPupilFixedPoints & ~sPupil.vecPupilIsEdited;
		vecStartEpochs = 1+find(diff(indAddEpochs)==1);
		vecEndEpochs = find(diff(indAddEpochs)==-1);
		if vecEndEpochs(1) < vecStartEpochs(1)
			vecStartEpochs = cat(2,1,vecStartEpochs);
		end
		if vecStartEpochs(end) > vecEndEpochs(end)
			vecEndEpochs = cat(2,vecEndEpochs,numel(indAddEpochs));
		end
		vecInterEpochDur = vecStartEpochs(2:end) - vecEndEpochs(1:(end-1));
		
		%merge epochs
		dblMinInterEpochDurSecs = 0.5;
		vecInterEpochDurSecs = (vecInterEpochDur/sPupil.sTrackParams.dblRealFrameRate)*sPupil.sTrackParams.intTempAvg;
		vecMergeEpochs = find(vecInterEpochDurSecs < dblMinInterEpochDurSecs);
		if ~isempty(vecMergeEpochs)
			vecEpochStretchEndIdx = find([diff(vecMergeEpochs) 2]>1);
			vecEpochStretchEnd = vecMergeEpochs(vecEpochStretchEndIdx)+1;
			vecEpochStretchStart = [1 vecMergeEpochs(vecEpochStretchEndIdx(1:(end-1))+1)];
			
			%get singleton epochs
			vecAllEpochs = 1:numel(vecStartEpochs);
			vecSingetonEpochs = vecAllEpochs(~ismember(vecAllEpochs,[vecMergeEpochs vecMergeEpochs+1]));
			
			%combine
			vecNewEpochStarts = sort([vecStartEpochs(vecSingetonEpochs)...
				vecStartEpochs(vecEpochStretchStart)]);
			vecNewEpochEnds = sort([vecEndEpochs(vecSingetonEpochs)...
				vecEndEpochs(vecEpochStretchEnd)]);
			
			%add to epochs
			intOldEpochs = numel(sEpochs);
			for intNewEpochIdx=numel(vecNewEpochStarts):-1:1
				intAssignEpochIdx = intNewEpochIdx+intOldEpochs;
				%get begin labels
				intB = vecNewEpochStarts(intNewEpochIdx);
				BeginLabels = struct('X',sPupil.vecPupilCenterX(intB),...
					'Y',sPupil.vecPupilCenterY(intB),...
					'R',sPupil.vecPupilRadius(intB),...
					'R2',sPupil.vecPupilRadius2(intB),...
					'A',sPupil.vecPupilAngle(intB));
				
				%get end labels
				intE = vecNewEpochEnds(intNewEpochIdx);
				EndLabels = struct('X',sPupil.vecPupilCenterX(intE),...
					'Y',sPupil.vecPupilCenterY(intE),...
					'R',sPupil.vecPupilRadius(intE),...
					'R2',sPupil.vecPupilRadius2(intE),...
					'A',sPupil.vecPupilAngle(intE));
				
				%assign data
				vecF = intB:intE;
				sEpochs(intAssignEpochIdx).BeginFrame = intB;
				sEpochs(intAssignEpochIdx).BeginLabels = BeginLabels;
				sEpochs(intAssignEpochIdx).EndFrame = intE;
				sEpochs(intAssignEpochIdx).EndLabels = EndLabels;
				sEpochs(intAssignEpochIdx).CenterX = sPupil.vecPupilCenterX(vecF);
				sEpochs(intAssignEpochIdx).CenterY = sPupil.vecPupilCenterY(vecF);
				sEpochs(intAssignEpochIdx).Radius = sPupil.vecPupilRadius(vecF);
				sEpochs(intAssignEpochIdx).Radius2 = sPupil.vecPupilRadius2(vecF);
				sEpochs(intAssignEpochIdx).Angle = sPupil.vecPupilAngle(vecF);
				sEpochs(intAssignEpochIdx).Blinks = true(size(vecF));
				sEpochs(intAssignEpochIdx).IsDetected = true(size(vecF));
			end
		end
	end
	
	%reorder
	[dummy,vecReorder] = sort(cell2vec({sEpochs.BeginFrame}));
	sEpochs = sEpochs(vecReorder);
	
	%add epochs to gui list
	cellEpochList = arrayfun(@(x) sprintf('%.1f - %.1f s (F# %d - %d)',vecPupilTime(x.BeginFrame),vecPupilTime(x.EndFrame),x.BeginFrame,x.EndFrame),...
		sEpochs,'UniformOutput',false);
	cellEpochList(end+1) = {'New'};
	ptrEpochList.String = cellEpochList;
end