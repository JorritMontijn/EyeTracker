function [sPupil,im1,im2] = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,dblPupilMinPixSize)
	%getPupil Detects pupil in image using GPU-accelerated image processing
	%syntax: [sPupil,im1,im2] = getPupil(gMatVid,gMatFilt,intReflT,intPupilT,objSE,dblPupilMinPixSize)
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
	%		- sPupil.dblRoundness
	%		- sPupil.dblEccentricity
	%		- sPupil.vecCentroid
	%		- sPupil.dblMajAx
	%		- sPupil.dblMinAx
	%		- sPupil.dblOri
	%	- im1; 2D image after reflection removal
	%	- im2; 2D image containing thresholded area labels
	%
	%Note: requesting im1 and im2 as optional outputs slightly reduces
	%performance, but this should be barely noticeable on most systems.
	%
	%Version history:
	%1.0 - Sept 11 2019
	%	Created by Jorrit Montijn
	
	%% process inputs/outputs
	if nargout > 1
		boolSaveIms = true;
	else
		boolSaveIms = false;
	end
	
	%% perform pupil detection
	%move to GPU and rescale
	gMatVid = (gMatVid - min(gMatVid(:)));
	gMatVid = (gMatVid / max(gMatVid(:)))*255;
	
	% detect pupil
	%Gaussian blur
	gMatVid = conv2(gMatVid,gMatFilt,'same');
	
	%reflection threshold, set reflection to black (>253)
	gMatVid(gMatVid > sglReflT) = 0;
	if boolSaveIms,im1 = gather(gMatVid);end
	
	%pupil threshold, binarize and invert so pupil is white (<15)
	gMatVid = gMatVid < sglPupilT;
	
	%morphological closing (dilate+erode) to remove reflection boundary
	%reiterate closing x times (4)
	gMatVid = imclose(gMatVid,objSE);
	gMatVid = imclose(gMatVid,objSE);
	gMatVid = imclose(gMatVid,objSE);
	gMatVid = imclose(gMatVid,objSE);
	if boolSaveIms,imClosed = gather(gMatVid);end
	%fill small holes
	gMatVid = imfill(gMatVid,4,'holes');
	%morphological opening (erode+dilate) to remove small connections
	gMatVid = imopen(gMatVid,objSE);
	
	%get regions of sufficient size
	imBW = gather(gMatVid);
	sCC = bwconncomp(imBW, 26);
	sS = regionprops(sCC, 'Area');
	vecArea = [sS.Area];
	vecKeep = find(vecArea >= dblPupilMinPixSize);
	matL = labelmatrix(sCC);
	intParts = numel(vecKeep);
	%get large region properties
	vecArea = vecArea(vecKeep);
	matCentroids = nan(2,intParts);
	vecMajAx = nan(1,intParts);
	vecMinAx = nan(1,intParts);
	vecOri = nan(1,intParts);
	vecPerimeter = nan(1,intParts);
	matObjects = false(size(imBW));
	for i=1:intParts
		matBW = matL==vecKeep(i);
		matObjects(matBW) = true;
		cellProps  = regionprops(matBW,'Centroid','MajorAxisLength','MinorAxisLength','Orientation','Perimeter');
		matCentroids(:,i) = cellProps.Centroid;
		vecMajAx(i) = cellProps.MajorAxisLength;
		vecMinAx(i) = cellProps.MinorAxisLength;
		vecOri(i) = cellProps.Orientation;
		vecPerimeter(i) = cellProps.Perimeter;
	end
	%save image if requested
	if boolSaveIms,im2=imClosed+imBW+2*matObjects;end
	
	%what is area to perimeter ratio?
	vecAreaToPerim = vecArea./vecPerimeter;
	%what would it be if it were a circle?
	vecCircAreaToPerim = (vecMinAx+vecMajAx)/8;
	vecRoundness = vecAreaToPerim ./ vecCircAreaToPerim;
	vecEccentricity = sqrt(1-((vecMinAx ./ vecMajAx).^2));
	%dblCircPerim = 2*pi*r;
	%dblCircArea = pi*r^2;
	%dblAreaToPerim = r/2;
	
	%use roundest object as pupil
	if isempty(vecRoundness)
		dblRoundness = 0;
		dblEccentricity = 0;
		vecCentroid = [0 0];
		dblMajAx = 0;
		dblMinAx = 0;
		dblOri = 0;
	else
		[dblRoundness,intUse]=max(vecRoundness);
		dblEccentricity = vecEccentricity(intUse);
		vecCentroid = matCentroids(:,intUse);
		dblMajAx = vecMajAx(intUse);
		dblMinAx = vecMinAx(intUse);
		dblOri = vecOri(intUse);
	end
	
	%% save data
	sPupil = struct;
	%assign detected pupil parameters
	sPupil.dblRoundness = dblRoundness;
	sPupil.dblEccentricity = dblEccentricity;
	sPupil.vecCentroid = vecCentroid;
	sPupil.dblMajAx = dblMajAx;
	sPupil.dblMinAx = dblMinAx;
	sPupil.dblOri = dblOri;
	
end
	
