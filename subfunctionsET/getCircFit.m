function vecValues = getCircFit(vecOptimParams,matXY)
	%getCircFit Returns values in the range 0-1 depending on x-y location
	%	within (1) or outside (0) circle defined by vecParams (x, y, r) 
	%Syntax: vecValues = getCircFit(vecParams,matXY)
	
	%get distance
	[dummy,vecDist] = cart2pol(matXY(:,2)-vecOptimParams(2),matXY(:,1)-vecOptimParams(1));
	indInner = vecDist < (vecOptimParams(3) - 1);
	indOuter = vecDist > vecOptimParams(3);
	vecValues = zeros(size(vecDist));
	vecValues(indInner) = 1;
	vecValues(indOuter) = 0;
	vecValues(~indInner & ~indOuter) = vecOptimParams(3) - vecDist(~indInner & ~indOuter);
	
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