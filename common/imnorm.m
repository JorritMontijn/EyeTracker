function matData = imnorm(matData,intDim)
	%imnorm Normalized image or matrix to values in range [0 1]; if second
	%argument is supplied, normalization takes place over that dimension,
	%otherwise normalization is performed over all values [intDim = 0]
	%   Syntax: imOut = imnorm(imIn[,intDim])
	
	%suppress warning due to eval()
	%#ok<*NASGU>
	
	%default
	if nargin == 1, intDim=[];end
	
	%transform to double
	matData = double(matData);
	
	if isempty(intDim) && ndims(matData) == 3
		%for backward compatibility; if no second argument is supplied,
		%perform normalization over third dimension if input has ndims==3
		for intCh=1:size(matData,3)
			imInThis = matData(:,:,intCh);
			dblMin = min(imInThis(:));
			dblMax = max(imInThis(:));
			
			if dblMin == dblMax
				imOutThis = zeros(size(imInThis));
			else
				imOutThis = imInThis - dblMin;
				imOutThis = imOutThis / max(imOutThis(:));
			end
			matData(:,:,intCh) = imOutThis;
		end
	elseif isempty(intDim) || intDim == 0
		%perform normalization over all values
		dblMin = min(matData(:));
		dblMax = max(matData(:));
		if dblMin == dblMax
			matData = ones(size(matData));
		else
			matData = matData - dblMin;
			matData = matData / max(matData(:));
		end
	else
		%perform normalization over specified dimension
		%create dimension selection string
		strSelectDimsTemplate = ['(:' repmat(',:',[1 ndims(matData)-1]) ')'];
		for intElement=1:size(matData,intDim)
			%change dimension selection string to comply to required
			%element in selected dimension
			strSelect = num2str(intElement);
			intStart = intDim*2;
			intStop = intStart - 1 + length(strSelect);
			strSelectDims = strSelectDimsTemplate;
			strSelectDims(intStart:intStop) = num2str(intElement);
			intStartEnd = (intStop+1);
			intStopEnd = length(strSelectDimsTemplate)+length(strSelect)-1;
			strSelectDims(intStartEnd:intStopEnd) = strSelectDimsTemplate((intStart+1):end);
			
			%retrieve values
			matThis = eval(['matData' strSelectDims]);
			
			%normalize
			dblMin = min(matThis(:));
			dblMax = max(matThis(:));
			if dblMin == dblMax
				matThis = eps*ones(size(matThis));
			else
				matThis = matThis - dblMin;
				matThis = matThis / max(matThis(:));
			end
			
			%assign to original matrix
			eval(['matData' strSelectDims ' = matThis;']);
		end
	end
end

