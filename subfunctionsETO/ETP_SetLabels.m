function sLabels = ETP_SetLabels(hObject,eventdata)
	
	%get globals
	global sETP;
	global sFigETP;
	global ETP_sLabels;
	global ETP_matAllIm;
	global ETP_matAllImOrig;
	
	%% check bounds
	intTempAvg = str2double(sFigETP.sHandles.TempAvg.String);
	if ~isnumeric(intTempAvg) || intTempAvg < 1
		sFigETP.sHandles.TempAvg.String = '1';
	elseif intTempAvg > sETP.intS
		sFigETP.sHandles.TempAvg.String = num2str(sETP.intS);
	end
	
	%% get values
	sHandles = sFigETP.sHandles;
	dblGain = str2double(sFigETP.sHandles.Gain.String);
	dblGamma = str2double(sFigETP.sHandles.Gamma.String);
	intTempAvg = str2double(sFigETP.sHandles.TempAvg.String);
	dblGaussWidth = str2double(sFigETP.sHandles.Blur.String);
	dblThreshReflect = str2double(sFigETP.sHandles.ReflLum.String);
	dblThreshPupil = str2double(sFigETP.sHandles.PupLum.String);
	
	%% get roi matrix
	%get ROI
	vecRectROIPix = round([sETP.vecRectROI(1)*sETP.intX sETP.vecRectROI(2)*sETP.intY sETP.vecRectROI(3)*sETP.intX sETP.vecRectROI(4)*sETP.intY]);
	vecKeepY = vecRectROIPix(2):(vecRectROIPix(2)+vecRectROIPix(4));
	vecKeepX = vecRectROIPix(1):(vecRectROIPix(1)+vecRectROIPix(3));
	
	%check boundaries
	vecKeepY(vecKeepY<1)=[];
	vecKeepY(vecKeepY>sETP.intY)=[];
	vecKeepX(vecKeepX<1)=[];
	vecKeepX(vecKeepX>sETP.intX)=[];
	
	%allocate 
	ETP_matAllImOrig = nan(numel(vecKeepY),numel(vecKeepX),1,size(sETP.matFrames,4),size(sETP.matFrames,5));
	if sETP.boolUseGPU
		ETP_matAllIm = ones(numel(vecKeepY),numel(vecKeepX),size(sETP.matFrames,4),'gpuArray');
	end
	for intIm=1:size(sETP.matFrames,4)
		%get originals
		ETP_matAllImOrig(:,:,1,intIm,:) = double(sETP.matFrames(vecKeepY,vecKeepX,1,intIm,:));
		
		% apply image corrections
		matMeanIm = (sum(ETP_matAllImOrig(:,:,1,intIm,1:floor(intTempAvg)),5) + (intTempAvg-floor(intTempAvg))*ETP_matAllImOrig(:,:,1,intIm,ceil(intTempAvg)))./intTempAvg;
		[matIm,imReflection] = ET_ImPrep(matMeanIm,sETP.gMatFilt,sETP.dblThreshReflect,sETP.objSE,sETP.boolInvertImage);
		matIm(imReflection) = 0;
		ETP_matAllIm(:,:,intIm) = imadjust(matIm./255);
	end
	
	%% label all frames
	boolNewLabels = false;
	if ~isfield(ETP_sLabels,'T') || ~all(sETP.vecSampleFrames == ETP_sLabels.T)
		boolNewLabels = true;
	elseif ~isempty(ETP_sLabels) && ~sFigETP.boolAutoRun 
		%ask whether to overwrite
		sOpts = struct;
		sOpts.Interpreter = 'none';
		sOpts.Default = 'No';
		strAnswer = questdlg('Do you want to select new labels?', ...
			'Overwrite labels?', ...
			'Yes','No',sOpts);
		if strcmp(strAnswer,'Yes')
			boolNewLabels = true;
		end
	end
	if boolNewLabels
		%% get labels
		sLabels = ETP_GetImLabels(ETP_matAllIm);
		sLabels.T = sETP.vecSampleFrames;
		sLabels.RectROI = vecRectROIPix;
		
		%% save data
		%add extra info
		sLabels.ParentVid = sETP.strVideoFile;
		sLabels.ParentPath = sETP.strPath;
		sLabels.ParentRecording = sETP.strRecordingNI;
		
		%remove extension & build new name
		cellFile = strsplit(sETP.strVideoFile,'.');
		strFileCore = strjoin(cellFile(1:end-1),'.');
		strName = [strFileCore 'Labels.mat'];
		strFolder = sETP.strPath;
		
		%save
		save(fullfile(strFolder,strName),'sLabels');
		
	else
		sLabels = ETP_sLabels;
	end
	
	%assign to global
	ETP_sLabels = sLabels;
end