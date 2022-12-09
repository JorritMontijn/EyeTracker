function matOut = getPupilMaskFit(dblPupilT,matXY)
	%getPupilMaskFit Optimizable function for lsqcurvefit to find the pupil threshold for an image
	%					given a ground-truth pupil area
	%   matOut = getPupilMaskFit(dblPupilT,matXY)
	%
	%getPupilMaskFit receives its constants from the global gStructFitPupilConstants
	
	global gStructFitPupilConstants;
	matFrame = gStructFitPupilConstants.matFrame;
	gMatFilt = gStructFitPupilConstants.gMatFilt;
	dblReflT = gStructFitPupilConstants.dblReflT;
	objSE = gStructFitPupilConstants.objSE;
	vecPrevLoc = gStructFitPupilConstants.vecPrevLoc;
	boolUseGPU = gStructFitPupilConstants.boolUseGPU;
	
	%detect pupil
	[sPupil,imPupil] = getPupil(matFrame,gMatFilt,dblReflT,dblPupilT,objSE,vecPrevLoc,dblPupilT,boolUseGPU);
	
	%add smooth border
	matOut = zeros(size(matFrame),'gpuArray');
	if any(imPupil(:))
		matOut(imPupil) = 1;
		%find surrounding pixels and add border
		imBorder = xor(imdilate(imPupil,objSE),imPupil);
		vecBorder = 1 - (gStructFitPupilConstants.matFrame(imBorder) - dblPupilT)./mean(matFrame(imPupil));
		vecBorder(vecBorder<0)=0;
		vecBorder(vecBorder>1)=1;
		matOut(imBorder) = vecBorder;
	end
	matOut = gather(matOut);
	%imagesc(matOut);
	%title(sprintf('threshold is %e',dblPupilT));
	%pause
	matOut = matOut(:);
end

function old
	%calculate pupil threshold, binarize and invert so pupil is white (<15)
	matFrame = matFrame < dblPupilT;
	
	%morphological closing (dilate+erode) to remove reflection boundary
	matFrame = imclose(matFrame,objSE);
	
	%fill small holes
	matFrame = imfill(matFrame,4,'holes');
	%morphological opening (erode+dilate) to remove small connections
	matFrame = imopen(matFrame,objSE);
	
	%get regions of sufficient size
	imBW = gather(matFrame);
	sCC = bwconncomp(imBW, 4);
	
	%get primary area
	matOut = zeros(size(matFrame),'gpuArray');
	if sCC.NumObjects > 0
		matOut(sCC.PixelIdxList{1}) = 1;
		
		%find surrounding pixels and add border
		matBorder = xor(imdilate(matFrame,objSE),matFrame);
		vecBorder = 1 - (gStructFitPupilConstants.matFrame(matBorder) - dblPupilT)./mean(matFrame(imBW));
		vecBorder(vecBorder<0)=0;
		vecBorder(vecBorder>1)=1;
		matOut(matBorder) = vecBorder;
	end
	matOut = gather(matOut);
	%imagesc(matOut);
	%title(sprintf('threshold is %e',dblPupilT));
	%pause
	
	matOut = matOut(:);
	
end

