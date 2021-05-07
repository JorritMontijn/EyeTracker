function vecValues = getCircFitPenalty(vecOptimParams,matXY)
	%getCircFit Returns values in the range 0-1 depending on x-y location
	%	within (1) or outside (0) circle defined by vecParams (x, y, r) 
	%Syntax: vecValues = getCircFit(vecParams,matXY)
	
	%get penalty matrix
	global vecP;
	
	%get distance
	vecValues = getCircFit(vecOptimParams,matXY);
	indApplyP = vecValues ~= 0 & vecP ~= 0;
	vecValues(indApplyP) = vecP(indApplyP);
	
end
%{
function dblError = getCircFit(vecOptimParams,sConstants)
	%get relative locations
	vecRelX = sConstants.vecX - vecOptimParams(1);
	vecRelY = sConstants.vecY - vecOptimParams(2);
	
	%get regularization term
	dblRidgeError = sConstants.dblLambda*sum((vecOptimParams - sConstants.vecApproxParams).^2);
	
	%get distance
	[dummy,vecDist] = cart2pol(vecRelX,vecRelY);
	vecError = sConstants.vecZ - (vecDist < vecOptimParams(3));
	
	%total error
	dblError = double(sum(vecError.^2) + dblRidgeError);
end
%}