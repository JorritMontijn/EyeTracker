function sEpochs = ETC_GenEmptyEpochs
	sEpochs = struct;
	sEpochs.BeginFrame = nan;
	sEpochs.BeginLabels = [];
	sEpochs.EndFrame = nan;
	sEpochs.EndLabels = [];
	sEpochs.CenterX = [];
	sEpochs.CenterY = [];
	sEpochs.Radius = [];
	sEpochs.Radius2 = [];
	sEpochs.Angle = [];
	sEpochs.Blinks = [];
	sEpochs.IsDetected = [];
	sEpochs(:) = [];
end