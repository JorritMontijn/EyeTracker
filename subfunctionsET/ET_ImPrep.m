function [gMatVid,imReflection] = ET_ImPrep(gMatVid,gMatFilt,sglReflT,objSE,boolInvertImage)
	%ET_ImPrep Summary of this function goes here
	%   [gMatVid,imReflection] = ET_ImPrep(gMatVid,gMatFilt,sglReflT,objSE,boolInvertImage)
	
	%move to GPU and rescale
	%gMatVid = (gMatVid - min(gMatVid(:)));
	%gMatVid = (gMatVid / max(gMatVid(:)))*255;
	
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
	
	%rescale after reflection removal
	dblNewMax = max(flat(gMatVid(~imReflection)));
	if ~isempty(dblNewMax)
		gMatVid(imReflection) = dblNewMax;
	end
	%gMatVid = (gMatVid - min(gMatVid(:)));
	%gMatVid = (gMatVid / max(gMatVid(:)))*255;
	
end

