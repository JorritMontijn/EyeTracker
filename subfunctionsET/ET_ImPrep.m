function [gMatVid,imReflection] = ET_ImPrep(gMatVid,gMatFilt,sglReflT,objSE,boolInvertImage)
	%ET_ImPrep Summary of this function goes here
	%   [gMatVid,imReflection] = ET_ImPrep(gMatVid,gMatFilt,sglReflT,objSE,boolInvertImage)
	
	%global
	global sETC;
	
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
	if boolInvertImage
		if all(imReflection(:))
			imReflection = false;
		end
		gMatVid = -(gMatVid - max(flat(gMatVid(~imReflection))));
		gMatVid(gMatVid<0) = 255;
	end
	
	%apply circular mask
	if isfield(sETC,'dblCircMaskSize') && ~isempty(sETC.dblCircMaskSize) && sETC.dblCircMaskSize > 0 && sETC.dblCircMaskSize < 1
		[intNy,intNx]=size(imReflection);
		dblCircRadius = sETC.dblCircMaskSize * sqrt((intNx/2)^2 + (intNy/2)^2);
		[matX,matY] = meshgrid(1:intNx,1:intNy);
		matXY = [matX(:) matY(:)];
		imCircMask = reshape(getCircFit([intNx/2 intNy/2 dblCircRadius],matXY)...
			,size(imReflection))==0;
		imReflection = imReflection | imCircMask;
	end
	
	%rescale after reflection removal
	dblNewMax = max(flat(gMatVid(~imReflection)));
	if ~isempty(dblNewMax)
		gMatVid(imReflection) = dblNewMax;
	end
	gMatVid = (gMatVid - min(gMatVid(:)));
	gMatVid = (gMatVid / max(gMatVid(:)))*255;
	
end

