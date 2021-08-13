function cellEpochList = ETC_GenEpochList(ptrEpochList,sEpochs,vecPupilTime)
	%vecPupilFixedCenterX(intBegin:intEnd) = sEpoch.CenterX;
	%vecPupilFixedCenterY(intBegin:intEnd) = sEpoch.CenterY;
	%vecPupilFixedRadius(intBegin:intEnd) = sEpoch.Radius;
	%vecPupilFixedBlinks(intBegin:intEnd) = sEpoch.Blinks;
	
	cellEpochList = arrayfun(@(x) sprintf('%.1f - %.1f s (F# %d - %d)',vecPupilTime(x.BeginFrame),vecPupilTime(x.EndFrame),x.BeginFrame,x.EndFrame),...
		sEpochs,'UniformOutput',false);
	cellEpochList(end+1) = {'New'};
	ptrEpochList.String = cellEpochList;
end