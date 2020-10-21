function [sPupil,imPupil,imReflection,imBW,imGrey] = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,vecPrevLoc,vecPupilT,sET)
	%getPupil Detects pupil in image using GPU-accelerated image processing
	%syntax: [sPupil,imPupil,imReflection,imBW,imGrey] = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,vecPrevLoc,vecPupilT)
	%	input:
	%	- gMatVid [Y x X]: gpuArray-class 2D image
	%	- gMatFilt [Y x X]: gpuArray-class 2D smoothing filter
	%	- sglReflT [single]: reflection threshold (in pixel luminance)
	%	- sglPupilT [single]: pupil threshold (in pixel luminance)
	%	- objSE: [object]: structuring element object for image processing
	%	- dblPupilMinPixSize: minimum contiguous pupil area in pixels
	%
	%	output:
	%	- sPupil; structure with pupil parameters:
	%		sPupil.vecCentroid;			center in pixel coordinates
	%		sPupil.dblRadius;			radius in pixels
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
	%1.0 - Sept 11 2019
	%	Created by Jorrit Montijn
	%2.0 - Dec 18 2019
	%	New algorithm dynamically chooses pupil threshold, then performs
	%	L2-regularized ridge fitting with circle [by JM]
	
	%% check inputs
	if ~exist('vecPupilT','var') || isempty(vecPupilT)
		vecPupilT = sglPupilT;
	end
	
	%% perform pupil detection
	%move to GPU and rescale
	gMatVid = (gMatVid - min(gMatVid(:)));
	gMatVid = (gMatVid / max(gMatVid(:)))*255;
	
	%filter image
	if ~isempty(gMatFilt) && ~isscalar(gMatFilt)
		gMatVid = imfilt(gMatVid,gMatFilt);
	end
	%detect reflection; dilate area and ignore for fit later on
	imReflection = gMatVid > sglReflT;
	imReflection = logical(gather(imdilate(imReflection,objSE)));
	if sET.boolInvertImage
		if all(imReflection(:))
			imReflection = false;
		end
		gMatVid = -(gMatVid - max(flat(gMatVid(~imReflection))));
		gMatVid(gMatVid<0) = 255;
	end
	if nargout > 4
		imGrey = gather(gMatVid);
		imGrey(imReflection) = 0;
	end
	
	%% get pupil estimate at different thresholds
	vecImSize = size(gMatVid);
	intThreshNum = numel(vecPupilT);
	vecRoundness = nan(1,intThreshNum);
	vecArea = nan(1,intThreshNum);
	matCentroids = nan(2,intThreshNum);
	imStack = false(vecImSize(1),vecImSize(2),intThreshNum);
	for intThresholdIdx=1:numel(vecPupilT)
		%get approximate estimate of pupil regions
		dblPupilT=vecPupilT(intThresholdIdx);
		[dblRoundness,dblArea,vecCentroid,imBW] = getApproxPupil(gMatVid,dblPupilT,objSE,vecPrevLoc);
		%assign values
		vecRoundness(intThresholdIdx) = dblRoundness;
		vecArea(intThresholdIdx) = dblArea;
		matCentroids(:,intThresholdIdx) = vecCentroid;
		imStack(:,:,intThresholdIdx) = imBW;
	end
	
	%% define likelihood of pupil based on roundness, area, and
	%calculate distance from previous location
	vecDist = sqrt(sum(bsxfun(@minus,matCentroids,vecPrevLoc(:)).^2,1));
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
	intUseIm = find(sglPupilT==vecPupilT,1);
	imBW = imStack(:,:,intUseIm);
	
	%% fit with circle
	%turn BW image into double with slight gradient
	if sET.boolUseGPU
		matDbl = double(gather(imfilt(gpuArray(double(imBW)),gMatFilt)));
	else
		matDbl = double(imfilt(double(imBW),gMatFilt));
	end
	%matDbl = double(imBW);
	%for fitting, impose ridge (L2) regularization for x&y location and radius
	%	(all three relative to initial approximate pupil estimate
	try
		[vecCentroid,dblRadius,dblEdgeHardness,imPupil] = getCircleRidgeFit(matDbl,vecApproxCentroid,dblApproxRadius,imReflection,0);
	catch
		vecCentroid = vecApproxCentroid;
		dblRadius = dblApproxRadius;
		dblEdgeHardness = 0;
		imPupil = false.*imReflection;
	end
	imPupil = logical(imPupil);
	%retrieve original brightness of fitted area
	if all(~imPupil(:))
		imPupil(1,1) = true;
	end
	vecPixVals = flat(gMatVid(imPupil));
	dblMeanPupilLum = gather(mean(vecPixVals));
	dblSdPupilLum = gather(std(vecPixVals));
	
	%plot
	%{
	matPlot = imReflection + imBW*2 + imPupil * 4;
	matC = ...
			[0 0 0;... %0, nothing
			1 0 0;... %1, reflection
			0 1 0;... %2, potential pupil regions
			1 1 0;... %3, reflection & potential pupil
			0 1 1;... %4, pupil
			1 0 1;... %5, reflection & pupil
			1 1 1;... %6, potential pupil & pupil
			0 0 1;... %7, potential pupil & pupil & reflection
			];
	imagesc(matPlot,[0 7]);
	colormap(matC)
	%}
	
	%% save data
	sPupil = struct;
	%assign detected pupil parameters
	sPupil.vecCentroid = vecCentroid; %center in pixel coordinates
	sPupil.dblRadius = dblRadius; %radius in pixels
	sPupil.dblEdgeHardness = dblEdgeHardness; %0 if uniform (no edge), 1 if mask drops from 1 to 0 at exactly the fitted boundary
	sPupil.dblMeanPupilLum = dblMeanPupilLum; %average pupil area intensity
	sPupil.dblSdPupilLum = dblSdPupilLum; %sd of pupil area intensity
	sPupil.dblApproxConfidence = dblApproxConfidence; %confidence of approximated pupil parameters
	sPupil.dblApproxRoundness = dblApproxRoundness; %approximated pupil roundness
	sPupil.vecApproxCentroid = vecApproxCentroid; %approximated pupil centroid
	sPupil.dblApproxRadius = dblApproxRadius; %approximated pupil radius
	
end