function sEpochs = ETC_GenEmptyEpochs
	sEpochs = struct;
	sEpochs.BeginFrame = nan;
	sEpochs.BeginLabels = [];
	sEpochs.EndFrame = nan;
	sEpochs.EndLabels = [];
	sEpochs.CenterX = [];
	sEpochs.CenterY = [];
	sEpochs.Radius = [];
	sEpochs.Blinks = [];
	sEpochs(:) = [];
end