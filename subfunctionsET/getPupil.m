function [sPupil,imPupil,imReflection,imBW,imGrey] = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,vecPrevLoc,vecPupilT,sET)
	%getPupil Detects pupil in image using GPU-accelerated image processing
	%syntax: [sPupil,imPupil,imReflection,imBW,imGrey] = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,vecPrevLoc,vecPupilT,sET)
	%	input:
	%	- gMatVid [Y x X]: gpuArray-class 2D image
	%	- gMatFilt [Y x X]: gpuArray-class 2D smoothing filter
	%	- sglReflT [single]: reflection threshold (in pixel luminance)
	%	- sglPupilT [single]: pupil threshold (in pixel luminance)
	%	- objSE: [object]: structuring element object for image processing
	%	- vecPrevLoc: previous pupil location / previous pupil parameters
	%	- vecPupilT: vector of pupil thresholds
	%	- sET: eye-tracking data structure
	%
	%	output:
	%	- sPupil; structure with pupil parameters:
	%		sPupil.vecCentroid;			center in pixel coordinates
	%		sPupil.dblRadius;			radius in pixels
	%		sPupil.dblRadius2;			radius2 in pixels
	%		sPupil.dblAngle;			angle in rads
	%		sPupil.dblEdgeHardness;		0 if uniform (no edge), 1 if mask drops from 1 to 0 at exactly the fitted boundary
	%		sPupil.dblMeanPupilLum;		average pupil area intensity
	%		sPupil.dblSdPupilLum;		sd of pupil area intensity
	%		sPupil.dblApproxConfidence; confidence of approximated pupil parameters
	%		sPupil.dblApproxRoundness;	approximated pupil roundness
	%		sPupil.vecApproxCentroid;	approximated pupil centroid
	%		sPupil.dblApproxRadius;		approximated pupil radius
	%		
	%	- imPupil; 2D 
	%	- imReflection; 2D reflection mask
	%	- imBW;
	%	- imGrey; 2D image after reflection removal
	%
	%Note: requesting im1 and im2 as optional outputs slightly reduces
	%performance, but this should be barely noticeable on most systems.
	%
	%Version history:
	%1.0 - 11 Sept 2019
	%	Created by Jorrit Montijn
	%2.0 - 18 Dec 2019
	%	New algorithm dynamically chooses pupil threshold, then performs
	%	L2-regularized ridge fitting with circle [by JM]
	%2.1 - 18 August 2022
	%	Changed fits to ellipse rather than circle; applied some computational improvements so speed
	%	should be approximately the same as before [by JM]
	
	%% check inputs
	if ~exist('vecPupilT','var') || isempty(vecPupilT)
		vecPupilT = sglPupilT;
	end
	if ~exist('sET','var')
		sET.boolUseGPU = true;
	elseif ~isstruct(sET)
		boolUseGPU = sET;
		sET=struct;
		sET.boolUseGPU = boolUseGPU;
	end
	if ~isfield(sET,'boolInvertImage') || isempty(sET.boolInvertImage)
		boolInvertImage = false;
	else
		boolInvertImage = sET.boolInvertImage;
	end
	
	
	%% get approximate pupil
	gMatVidOrig = gMatVid;
	imBW = false(size(gMatVid));
	while all(~imBW(:))
		%% prepare image
		[gMatVid,imReflection] = ET_ImPrep(gMatVidOrig,gMatFilt,sglReflT,objSE,boolInvertImage);
		if nargout > 4
			imGrey = gather(gMatVid);
			imGrey(imReflection) = 0;
		end
		
		%% get pupil estimate at different pupil thresholds
		vecPrevCentroid = flat(vecPrevLoc(1:2));
		vecImSize = size(gMatVid);
		intThreshNum = numel(vecPupilT);
		vecRoundness = nan(1,intThreshNum);
		vecArea = nan(1,intThreshNum);
		matCentroids = nan(2,intThreshNum);
		imStack = false(vecImSize(1),vecImSize(2),intThreshNum);
		for intThresholdIdx=1:numel(vecPupilT)
			%get approximate estimate of pupil regions
			dblPupilT=vecPupilT(intThresholdIdx);
			boolLowest = dblPupilT==min(vecPupilT);
			[dblRoundness,dblArea,vecCentroid,imBW] = getApproxPupil(gMatVid,dblPupilT,objSE,vecPrevLoc,boolLowest);
			%assign values
			vecRoundness(intThresholdIdx) = dblRoundness;
			vecArea(intThresholdIdx) = dblArea;
			matCentroids(:,intThresholdIdx) = vecCentroid;
			imStack(:,:,intThresholdIdx) = imBW;
		end
		%% increase reflection threshold if reflection is too high
		if all(~imBW(:))
			sglReflT=sglReflT*1.1;
		end
	end
	
	%% define likelihood of pupil based on roundness, area, and
	%calculate distance from previous location
	vecDist = sqrt(sum(bsxfun(@minus,matCentroids,vecPrevCentroid).^2,1));
	dblSd = sqrt(sum(vecImSize.^2));
	vecLikelihood = (vecRoundness - min(vecRoundness) + 1e-6) .* sqrt(vecArea) .* (1 - normcdf(vecDist,0,dblSd/2) + normcdf(-vecDist,0,dblSd/2));
	vecProbChoose = vecLikelihood ./ nansum(vecLikelihood);
	
	%define fitting location
	[dblApproxConfidence,intUseIdx] = max(vecProbChoose);
	
	%retrieve data
	dblApproxRoundness = vecRoundness(intUseIdx);
	dblApproxRadius = sqrt(vecArea(intUseIdx)/pi);
	vecApproxCentroid = matCentroids(:,intUseIdx);
	
	%get target image
	[dummy,intUseIm] = min(abs(sglPupilT-vecPupilT));
	imBW = imStack(:,:,intUseIm);
	
	%% fit with circle
	%get potential area
	
	%turn BW image into double with slight gradient
	if isfield(sET,'boolUseGPU') && sET.boolUseGPU
		matDbl = double(gather(imfilt(gpuArray(double(imBW)),gMatFilt)));
	else
		matDbl = double(imfilt(double(imBW),gMatFilt));
		%matDbl = double(imfilt(double(imBW),gMatFilt));
	end
	%matDbl = double(imBW);
	
	%for fitting, impose small penalty on pupil areas outside imBW
	if numel(vecPrevLoc) > 2
		vecP0 = vecPrevLoc;
		vecP0(1:2) = vecApproxCentroid;
	else
		vecP0 = vecApproxCentroid;
	end
	try
		[vecFitParams,dblEdgeHardness,imPupil] = getCircleFitWrapper(matDbl,vecP0,dblApproxRadius,imReflection,imBW);
		vecCentroid = vecFitParams(1:2);
		dblRadius = vecFitParams(3);
		dblRadius2 = vecFitParams(4);
		dblAngle = vecFitParams(5);
	catch ME
		rethrow(ME)
		vecCentroid = vecApproxCentroid;
		dblRadius = dblApproxRadius;
		dblRadius2 = dblRadius;
		dblAngle = 0;
		dblEdgeHardness = 0;
		imPupil = false.*imReflection;
	end
	imPupil = logical(imPupil);
	%retrieve original brightness of fitted area
	if all(~imPupil(:))
		imPupil(1,1) = 1;
	end
	vecPixVals = flat(gMatVid(imPupil));
	dblMeanPupilLum = gather(mean(vecPixVals));
	dblSdPupilLum = gather(std(vecPixVals));
	
	%% save data
	sPupil = struct;
	%assign detected pupil parameters
	sPupil.vecCentroid = vecCentroid; %center in pixel coordinates
	sPupil.dblRadius = dblRadius; %radius in pixels
	sPupil.dblRadius2 = dblRadius2; %radius2 in pixels
	sPupil.dblAngle = dblAngle; %angle of ellipse
	sPupil.dblEdgeHardness = dblEdgeHardness; %0 if uniform (no edge), 1 if mask drops from 1 to 0 at exactly the fitted boundary
	sPupil.dblMeanPupilLum = dblMeanPupilLum; %average pupil area intensity
	sPupil.dblSdPupilLum = dblSdPupilLum; %sd of pupil area intensity
	sPupil.dblApproxConfidence = dblApproxConfidence; %confidence of approximated pupil parameters
	sPupil.dblApproxRoundness = dblApproxRoundness; %approximated pupil roundness
	sPupil.vecApproxCentroid = vecApproxCentroid; %approximated pupil centroid
	sPupil.dblApproxRadius = dblApproxRadius; %approximated pupil radius
	
end