function ETP_DetectEdit(hObject,eventdata,strParam)
	
	%get globals
	global sETP;
	global sFigETP;
	
	%% ensure input conforms to format
	sHandles = sFigETP.sHandles;
	if exist('strParam','var')
		dblNewVal = str2double(sFigETP.sHandles.(strParam).String);
		if isempty(dblNewVal) || ~isnumeric(dblNewVal)
			dblNewVal = sETP.(sHandles.(strParam).UserData.Val);
		end
		sFigETP.sHandles.(strParam).String = sprintf(sHandles.(strParam).UserData.Fmt,dblNewVal);
	end
	
	%% check bounds
	intTempAvg = str2double(sFigETP.sHandles.TempAvg.String);
	if ~isnumeric(intTempAvg) || intTempAvg < 1
		sFigETP.sHandles.TempAvg.String = '1';
	elseif intTempAvg > sETP.intS
		sFigETP.sHandles.TempAvg.String = num2str(sETP.intS);
	end
	
	%% get values
	sETP.dblGain = str2double(sFigETP.sHandles.Gain.String);
	sETP.dblGamma = str2double(sFigETP.sHandles.Gamma.String);
	sETP.intTempAvg = str2double(sFigETP.sHandles.TempAvg.String);
	dblGaussWidth = str2double(sFigETP.sHandles.Blur.String);
	sETP.dblStrEl = str2double(sFigETP.sHandles.StrEl.String);
	sETP.dblThreshReflect = str2double(sFigETP.sHandles.ReflLum.String);
	sETP.dblThreshPupil = str2double(sFigETP.sHandles.PupLum.String);
	sglReflT = sETP.dblThreshReflect;
	sglPupilT = sETP.dblThreshPupil;
	
	%% get selected frame
	sFigETP.intCurFrame = ETP_GetCurrentFrame();
	
	%% apply image corrections
	% apply image corrections
	matMeanIm = (sum(double(sETP.matFrames(:,:,1,sFigETP.intCurFrame,1:floor(sETP.intTempAvg))),5) + (sETP.intTempAvg-floor(sETP.intTempAvg))*double(sETP.matFrames(:,:,1,sFigETP.intCurFrame,ceil(sETP.intTempAvg))))./sETP.intTempAvg;
	matIm = imadjust(matMeanIm./255,[],[],sETP.dblGamma).*sETP.dblGain;
	matIm(matIm(:)>1)=1;
	sFigETP.matVid = matIm;
	
	%% do detection
	%build structuring element
	intRadStrEl = round(sETP.dblStrEl);
	vecChoose=[4 6 8];
	[dummy,intChooseIdx]=min(abs(vecChoose-intRadStrEl*2));
	intN = vecChoose(intChooseIdx);
	objSE = strel('disk',intRadStrEl,intN);
	sETP.objSE = objSE;
	
	%blur width
	if dblGaussWidth ~= sETP.dblGaussWidth || ~(isfield(sETP,'gMatFilt') && ~isempty(sETP.gMatFilt))
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
	%vecPupil = (sglPupilT-40):10:(sglPupilT+20);
	vecPupil = (sglPupilT-6):2:(sglPupilT+4);
	vecPupil(vecPupil<0)=[];
	vecPupil(vecPupil>sglReflT)=[];
	%vecPupil = sglPupilT;
	sETP.vecPupil = vecPupil;
	
	%get ROI
	vecRectROIPix = round([sETP.vecRectROI(1)*sETP.intX sETP.vecRectROI(2)*sETP.intY sETP.vecRectROI(3)*sETP.intX sETP.vecRectROI(4)*sETP.intY]);
	vecKeepY = vecRectROIPix(2):(vecRectROIPix(2)+vecRectROIPix(4));
	vecKeepX = vecRectROIPix(1):(vecRectROIPix(1)+vecRectROIPix(3));
	
	%check boundaries
	vecKeepY(vecKeepY<1)=[];
	vecKeepY(vecKeepY>sETP.intY)=[];
	vecKeepX(vecKeepX<1)=[];
	vecKeepX(vecKeepX>sETP.intX)=[];
	
	%select ROI
	if sETP.boolUseGPU
		gMatVid = gpuArray(sFigETP.matVid(vecKeepY,vecKeepX));
	else
		gMatVid = sFigETP.matVid(vecKeepY,vecKeepX);
	end
	vecPrevLoc = [size(gMatVid,1)/2 size(gMatVid,2)/2];
	
	%detect
	[sFigETP.sPupil,sFigETP.imPupil,sFigETP.imReflection,sFigETP.imBW,sFigETP.imGrey] = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,vecPrevLoc,vecPupil,sETP);
	
	%prep main image
	if ~isfield(sETP,'boolInvertImage') || isempty(sETP.boolInvertImage)
		boolInvertImage = false;
		sETP.boolInvertImage = boolInvertImage;
	else
		boolInvertImage = sETP.boolInvertImage;
	end
	imReflBig = false(size(sFigETP.matVid));
	imReflBig(vecKeepY,vecKeepX) = sFigETP.imReflection;
	imReflBig = imdilate(imReflBig,objSE);
	matMain = ET_ImPrep(sFigETP.matVid,[],sglReflT,objSE,boolInvertImage);
	matMain(imReflBig) = 0;
	sFigETP.matMain = matMain./255;
	
	%% redraw image, boxes & detection
	ETP_redraw();
end