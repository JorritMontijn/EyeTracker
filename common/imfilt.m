function matImage = imfilt(matImageIn,matFilt,strPadVal)
	%imfilt ND image filtering. Syntax:
	%   matData = imfilt(matImage,matFilt,strPadVal)
	%
	%	input:
	%	- matImage; [X by Y] image matrix (can be gpuArray)
	%	- matFilt: [M by N] filter matrix (can be gpuArray)
	%	- strPadVal: optional (default: 'symmetric'), padding type using padarray.m
	%
	%Version history:
	%1.0 - 16 Dec 2019
	%	Created by Jorrit Montijn
	%1.1 - 25 Nov 2020
	%	Added support for N-dimensional matrices [by JM]
	
	%get padding type
	if ~exist('strPadVal','var') || isempty(strPadVal)
		strPadVal = 'symmetric';
	end
	
	%pad array
	vecSizeIn = size(matImageIn);
	matImageIn = padarray(matImageIn,floor(size(matFilt)/2),strPadVal);
	
	%filter
	if ndims(matImageIn) < 3 && ndims(matFilt) < 3
		matImage = conv2(matImageIn,matFilt,'valid');
		%ensure size is the same
		if vecSizeIn(1) > size(matImage,1),matImage((end+1):vecSizeIn(1),:)=matImage(end,:);end
		if vecSizeIn(2) > size(matImage,2),matImage(:,(end+1):vecSizeIn(2))=matImage(:,end);end
		if vecSizeIn(1) < size(matImage,1),matImage((vecSizeIn(1)+1):end,:) = [];end
		if vecSizeIn(2) < size(matImage,2),matImage(:,(vecSizeIn(2)+1):end) = [];end
	else
		matImage = convn(matImageIn,matFilt,'valid');
	end
end

