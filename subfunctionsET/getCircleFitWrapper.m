function [vecOptimParams,dblEdgeHardness,imPupil] = getCircleFitWrapper(matIn,vecApproxCentroid,dblApproxRadius,imIgnore,imBW)
	
	%vecApproxCentroid can be X-Y centroid or 5-element p0 vector for lsqcurvefit
	
	%% check if mask is supplied
	if ~exist('imIgnore','var') || isempty(imIgnore)
		imIgnore = false(size(matIn));
	end
	global vecP;
	
	%% linearize variables
	[matX,matY] = meshgrid(1:size(matIn,2),1:size(matIn,1));
	vecX = matX(~imIgnore);
	vecY = matY(~imIgnore);
	vecZ = (matIn(~imIgnore)./max(matIn(~imIgnore)));
	vecP = ~imBW(~imIgnore).*-1;
	if numel(vecApproxCentroid) == 2
		vecParams0 = [vecApproxCentroid(:)' dblApproxRadius/2 dblApproxRadius/2 0];
	else
		vecParams0 = vecApproxCentroid(:)';
	end
	% build data grid
	matXY = [vecX vecY];
	
	%% fit ellipse
	sOpt = struct;
	sOpt.Display = 'off';%'off'
	vecLB = [0 0 0.5 0.5 -pi];
	vecUB = [size(matIn,2) size(matIn,1) size(matIn,1)/2 size(matIn,1)/2 pi];
	[vecOptimParams,dblVal,flag,out] = lsqcurvefit(@getCircFitPenalty,vecParams0,matXY,vecZ,vecLB(1:numel(vecParams0)),vecUB(1:numel(vecParams0)),sOpt);
	
	%% calculate edge hardness
	if nargout > 2
		%add ignored areas back in
		matXY = [matX(:) matY(:)];
	
		%get fitted pupil
		vecValues = getCircFit(vecOptimParams,matXY);
		
		%get mask
		imPupil = reshape(vecValues,size(matX))>0.5;
		
		%get pixel identities
		indBorder = (vecValues > 0) & (vecValues < 1);
		matB = reshape(indBorder,size(matX));
		matDilB = imdilate(matB,strel('disk',2,8));
		indOuterBorder = matDilB & ~imPupil & ~imIgnore;
		indInnerBorder = matDilB & imPupil & ~imIgnore;
		
		%get border sharpness
		dblEdgeHardness = mean(vecZ(indInnerBorder)) - mean(vecZ(indOuterBorder));
	end
end