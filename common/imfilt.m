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
	matImage = padarray(matImageIn,floor(size(matFilt)/2),strPadVal);
	
	%filter
	if ndims(matImage) < 3 && ndims(matFilt) < 3
		matImage = conv2(matImage,matFilt,'valid');
	else
		matImage = convn(matImage,matFilt,'valid');
	end
end

