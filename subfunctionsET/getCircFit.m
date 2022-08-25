function vecValues = getCircFit(vecOptimParams,matXY)
	%getCircFit Returns values in the range 0-1 depending on x-y location
	%	within (1) or outside (0) circle defined by vecParams (x, y, r)
	%Syntax: vecValues = getCircFit(vecParams,matXY)
	
	error(['work in progress: please the previous version if you want to do eye-tracking. '...
		'this function now uses ellipses, but that''s not implemented in the other scripts yet. '...
		'note to self: the grid-warp operations can be separated from the circle calculation if the minor:major axis ratio and ellipse angle are constant'])
	
	if numel(vecOptimParams) == 3
		%get distance
		vecDist = hypot(matXY(:,2)-vecOptimParams(2),matXY(:,1)-vecOptimParams(1));
		indInner = vecDist < (vecOptimParams(3) - 1);
		indOuter = vecDist > vecOptimParams(3);
		vecValues = zeros(size(vecDist));
		vecValues(indInner) = 1;
		vecValues(indOuter) = 0;
		vecValues(~indInner & ~indOuter) = vecOptimParams(3) - vecDist(~indInner & ~indOuter);
	elseif numel(vecOptimParams) == 5
		%get vars
		dblX = vecOptimParams(1);
		dblY = vecOptimParams(2);
		dblR = vecOptimParams(3);
		dblR2 = vecOptimParams(4);
		dblA = -vecOptimParams(5);
		
		%build rotation matrix
		matRot = [cos(dblA) -sin(dblA);...
			sin(dblA) cos(dblA)];
		
		%center
		matCntXY = bsxfun(@minus,matXY,[dblX dblY]);
		
		%rotate
		matRotXY = (matRot*matCntXY')';
		
		%stretch
		matStrXY = bsxfun(@rdivide,matRotXY,[dblR dblR2]);
		
		%get distance
		vecDist = hypot(matStrXY(:,2),matStrXY(:,1));
		indInner = vecDist < (1 - 1/dblR);
		indOuter = vecDist > (1 +  1/dblR);
		vecValues = zeros(size(vecDist));
		vecValues(indInner) = 1;
		vecValues(indOuter) = 0;
		vecValues(~indInner & ~indOuter) = (dblR*(1 - vecDist(~indInner & ~indOuter)) + 1)/2;
		
	else
		error([mfilename ':WrongParamNum'],'number of params can only be 3 or 5');
	end
end

function plot
	%%
	cla;
	scatter3(matXY(:,1),matXY(:,2),vecValues,[],vecValues,'.')
	hold on
	ellipse(gca,vecOptimParams(1),vecOptimParams(2),vecOptimParams(3),vecOptimParams(4),vecOptimParams(5),'Color','r','LineStyle',':');
	hold off
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