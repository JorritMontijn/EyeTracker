function dblError = ETP_FitWrapper(vecX,boolRescale)
	
	%% get labels
	global ETP_sLabels;
	global sETP;
	global ETP_matAllIm;
	global ETP_matAllImOrig;
	global ETP_Fit;
	global sFigETP;
	if nargin < 2 || isempty(boolRescale)
		boolRescale = true;
	end
	
	%% get inputs
	if ~boolRescale
		vecX = vecX./ETP_Fit.vecOrigX;
	end
	vecOrigX = ETP_Fit.vecOrigX;
	vecPrevX = ETP_Fit.vecPrevX;
	ETP_Fit.vecPrevX = vecX;
	
	%new vals
	dblGain = vecX(1)*vecOrigX(1);
	dblGamma = vecX(2)*vecOrigX(2);
	intTempAvg = vecX(3)*vecOrigX(3);
	dblGaussWidth = vecX(4)*vecOrigX(4);
	sglReflT = vecX(5)*vecOrigX(5);
	sglPupilT = vecX(6)*vecOrigX(6);
	
	%old vals
	dblPrevGain = vecPrevX(1)*vecOrigX(1);
	dblPrevGamma = vecPrevX(2)*vecOrigX(2);
	intPrevTempAvg = vecPrevX(3)*vecOrigX(3);
	dblPrevGaussWidth = vecPrevX(4)*vecOrigX(4);
	sglPrevReflT = vecPrevX(5)*vecOrigX(5);
	sglPrevPupilT = vecPrevX(6)*vecOrigX(6);
	
	intF = size(sETP.matFrames,4);
	
	%% update
	vecV = [dblGain dblGamma intTempAvg dblGaussWidth sglReflT sglPupilT];
	sFigETP.sHandles.Gain.String = sprintf('%.2f',vecV(1));
	sFigETP.sHandles.Gamma.String = sprintf('%.2f',vecV(2));
	sFigETP.sHandles.TempAvg.String = sprintf('%.2f',vecV(3));
	sFigETP.sHandles.Blur.String = sprintf('%.2f',vecV(4));
	sFigETP.sHandles.ReflLum.String = sprintf('%.1f',vecV(5));
	sFigETP.sHandles.PupLum.String = sprintf('%.1f',vecV(6));
	
	%% check image change
	if intTempAvg > (intF-1)
		intTempAvg = intF - 1;
	elseif intTempAvg < 1
		intTempAvg = 1; 
	end
	if dblGain ~= dblPrevGain || dblGamma ~= dblPrevGamma || intTempAvg ~= intPrevTempAvg
		%allocate
		for intIm=1:intF
			% apply image corrections
			matMeanIm = (sum(ETP_matAllImOrig(:,:,1,intIm,1:floor(intTempAvg)),5) + (intTempAvg-floor(intTempAvg))*ETP_matAllImOrig(:,:,1,intIm,ceil(intTempAvg)))./intTempAvg;
			matIm = imadjust(matMeanIm./255,[],[],dblGamma).*dblGain;
			matIm(matIm(:)>1)=1;
			ETP_matAllIm(:,:,intIm) = matIm;
		end
		
		if sETP.boolUseGPU
			ETP_matAllIm = gpuArray(ETP_matAllIm);
		end
	end
	
	%% do detection
	%build structuring element
	intRadStrEl = 2;
	objSE = strel('disk',intRadStrEl,4);
	
	%blur width
	if dblGaussWidth ~= dblPrevGaussWidth || ~(isfield(sETP,'gMatFilt') && ~isempty(sETP.gMatFilt))
		sETP.dblGaussWidth = dblGaussWidth;
		if dblGaussWidth == 0
			if sETP.boolUseGPU
				gMatFilt = gpuArray(single(1));
			else
				gMatFilt = single(1);
			end
		else
			intGaussSize = ceil(dblGaussWidth*2);
			vecFilt = normpdf(-intGaussSize:intGaussSize,0,dblGaussWidth);
			matFilt = vecFilt' * vecFilt;
			matFilt = matFilt / sum(matFilt(:));
			if sETP.boolUseGPU
				gMatFilt = gpuArray(single(matFilt));
			else
				gMatFilt = single(matFilt);
			end
		end
	else
		gMatFilt = sETP.gMatFilt;
	end
			
	%get parameters
	vecPrevLoc = [size(ETP_matAllIm,1) size(ETP_matAllIm,2)];
	%vecPupil = (sglPupilT-40):10:(sglPupilT+20);
	%vecPupil = (sglPupilT-6):2:(sglPupilT+4);
	%vecPupil(vecPupil<0)=[];
	%vecPupil(vecPupil>sglReflT)=[];
	vecPupil = sglPupilT;
	
	
	%% detect all images
	vecImX = ETP_sLabels.X;
	vecImY = ETP_sLabels.Y;
	vecImR = ETP_sLabels.R;
	vecImE = zeros(size(ETP_sLabels.R));
	for intIm=1:intF
		gMatVid = ETP_matAllIm(:,:,intIm);
		sPupil = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,vecPrevLoc,vecPupil,sETP);
		vecCentroid = sPupil.vecCentroid; %center in pixel coordinates
		
		dblX = vecImX(intIm);
		dblFitX = vecCentroid(1);
		
		dblY = vecImY(intIm);
		dblFitY = vecCentroid(2);
		
		dblR = vecImR(intIm);
		dblFitR = sPupil.dblRadius;
		
		vecImE(intIm) =sqrt( (dblX - dblFitX)^2 + (dblY - dblFitY)^2) + abs(dblR - dblFitR);
		
	end
	dblError = sum(vecImE);
end