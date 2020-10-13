function [vecCentroid,dblRadius,dblEdgeHardness,imPupil] = getCircleRidgeFit(matIn,vecApproxCentroid,dblApproxRadius,imIgnore,dblLambda)
	
	%% check if mask is supplied
	if ~exist('imIgnore','var') || isempty(imIgnore)
		imIgnore = false(size(matIn));
	end
	%% check if lambda is supplied
	if ~exist('dblLambda','var') || isempty(dblLambda)
		dblLambda = 1;
	end
	
	%% linearize variables
	[matX,matY] = meshgrid(1:size(matIn,2),1:size(matIn,1));
	vecX = matX(~imIgnore);
	vecY = matY(~imIgnore);
	vecZ = matIn(~imIgnore);
	vecParams0 = [vecApproxCentroid(:)' dblApproxRadius];
	
	%% build function
	matXY = [vecX vecY];
	
	sConstants = struct;
	sConstants.vecX = vecX;
	sConstants.vecY = vecY;
	sConstants.vecZ = vecZ;
	sConstants.vecApproxParams = vecParams0;
	sConstants.dblLambda = dblLambda;
	fCircFit = @(vecOptimParams)getCircFit(vecOptimParams,sConstants);
	
	%% fit
	sOpt = struct;
	sOpt.Display = 'off';
	%sOpt.TolFun = 1e-15;
	%sOpt.TolX = 1e-15;
	vecLB = [0 0 0.5];
	vecUB = [size(matIn,2) size(matIn,1) size(matIn,1)];
	
	[vecParamsFit,dblVal,flag,out] = lsqcurvefit(@getCircFit,vecParams0,matXY,vecZ,vecLB,vecUB,sOpt);
	
	%[vecParamsFit,dblVal,flag,out] = fminsearch(fCircFit,vecParams0,sOpt);
	%[vecParamsFit,dblVal,flag,out] = fminunc(fCircFit,vecParams0,sOpt);
	vecCentroid = vecParamsFit(1:2);
	dblRadius = vecParamsFit(3);
	
	%% calculate edge hardness
	if nargout > 2
		%get relative locations
		vecRelX = sConstants.vecX - vecParamsFit(1);
		vecRelY = sConstants.vecY - vecParamsFit(2);
		
		%get distance
		[dummy,vecDist] = cart2pol(vecRelX,vecRelY);
		%get pixel identities
		indInnerBorder = (vecDist > (dblRadius - 2)) & (vecDist <= dblRadius);
		indOuterBorder = (vecDist > (dblRadius)) & (vecDist <= dblRadius + 2);
		%get border sharpness
		dblEdgeHardness = mean(sConstants.vecZ(indInnerBorder)) - mean(sConstants.vecZ(indOuterBorder));
	end
	
	%% calculate mask
	if nargout > 3
		%get relative locations
		matRelX = matX - vecParamsFit(1);
		matRelY = matY - vecParamsFit(2);
		
		%get distance
		[dummy,matDist] = cart2pol(matRelX,matRelY);
		
		%get pixel identities
		imPupil = matDist < vecParamsFit(3);
	end
end