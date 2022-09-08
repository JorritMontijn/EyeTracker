function dblOptimPupilT = ETC_FitPupilThreshold(dblPupilT0,matFrame,imPupil,gMatFilt,dblReflT,objSE,vecPrevLoc,boolUseGPU)
	%ETC_FitPupilThreshold Summary of this function goes here
	%   dblOptimPupilT = ETC_FitPupilThreshold(dblPupilT0,matFrame,imPupil,gMatFilt,dblReflT,objSE,vecPrevLoc,boolUseGPU)
	
	%% check if mask is supplied
	global gStructFitPupilConstants;
	gStructFitPupilConstants.matFrame = matFrame;
	gStructFitPupilConstants.gMatFilt = gMatFilt;
	gStructFitPupilConstants.dblReflT = dblReflT;
	gStructFitPupilConstants.objSE = objSE;
	gStructFitPupilConstants.vecPrevLoc = vecPrevLoc;
	gStructFitPupilConstants.boolUseGPU = boolUseGPU;
	
	%% linearize variables
	[matX,matY] = meshgrid(1:size(imPupil,2),1:size(imPupil,1));
	matXY = [matX(:) matY(:)];
	vecZ = double(imPupil(:));
	
	%% find optimal threshold
	sOpt = struct;
	sOpt.Display = 'off';
	vecLB = min(double(gather(matFrame(:))));
	vecUB = max(double(gather(matFrame(:))));
	[dblOptimPupilT,dblVal,flag,out] = lsqcurvefit(@getPupilMaskFit,double(gather(dblPupilT0)),matXY,vecZ,vecLB,vecUB,sOpt);
	
	%matOut = getPupilMaskFit(dblOptimPupilT,matXY);
	%matOut = reshape(matOut,size(imPupil));
end

