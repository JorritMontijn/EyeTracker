function [vecOptimParams,dblEdgeHardness,imPupil] = getCircleFitWrapper(matIn,vecApproxCentroid,dblApproxRadius,imIgnore,imBW)
	%getCircleFitWrapper Optimizes a circular or ellipsoid fit on an input image (range: 0-1)
	%	[vecOptimParams,dblEdgeHardness,imPupil] = getCircleFitWrapper(matIn,vecApproxCentroid,dblApproxRadius,imIgnore,imBW)
	
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
	fFunc = @getCircFit; %slower, but better quality
	%fFunc = @getCircFitPenalty; %faster, but worse quality
	sOpt = struct;
	sOpt.Display = 'off';%'off'
	vecLB = [0 0 0.5 0.5 -pi];
	vecParams0(vecParams0<vecLB)=vecLB(vecParams0<vecLB);
	vecUB = [size(matIn,2) size(matIn,1) size(matIn,1)/2 size(matIn,1)/2 pi];
	vecParams0(vecParams0>vecUB)=vecUB(vecParams0>vecUB);
	[vecOptimParams,dblVal,flag,out] = lsqcurvefit(fFunc,vecParams0,matXY,vecZ,vecLB(1:numel(vecParams0)),vecUB(1:numel(vecParams0)),sOpt);
	
	%% calculate edge hardness
	if nargout > 1
		
		%get mask
		matXY_sq = [matX(:) matY(:)];
		vecP = ~imBW(:).*-1;
		matPupil = reshape(feval(fFunc,vecOptimParams,matXY_sq),size(matIn));
		imPupil = matPupil>0.5;
		
		%get pixel identities
		matB = (matPupil > 0.2) & (matPupil < 0.8);
		matDilB = imdilate(matB,strel('disk',2,8));
		indOuterBorder = matDilB & ~imPupil & ~imIgnore;
		indInnerBorder = matDilB & imPupil & ~imIgnore;
		
		%get border sharpness
		indInnerBorder = indInnerBorder(~imIgnore);
		indOuterBorder = indOuterBorder(~imIgnore);
		dblEdgeHardness = mean(vecZ(indInnerBorder)) - mean(vecZ(indOuterBorder));
		
		%{
		%get fitted pupil
		%vecV = getCircFitPenalty(vecOptimParams,matXY);
		
		%plot
		figure
		
		F = scatteredInterpolant(vecX,vecY,vecZ);
		imZ = F(matX,matY);
		
		F = scatteredInterpolant(vecX,vecY,vecP);
		imP = F(matX,matY)+1;
		
		subplot(2,3,1)
		imagesc(matPupil)
		colorbar
		subplot(2,3,2)
		imagesc(imZ)
		subplot(2,3,3)
		imagesc(imP)
		
		subplot(2,3,4)
		imRGB = matPupil;
		imRGB(:,:,2) = imZ;
		imRGB(:,:,3) = imIgnore;
		
		imshow(imRGB)
		
		subplot(2,3,5)
		imagesc((imZ-matPupil).^2);colorbar
		%}
		
	end
end