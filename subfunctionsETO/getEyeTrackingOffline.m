function sPupil = getEyeTrackingOffline(sFile,strTempDir)
	%getEyeTrackingOffline Run offline pupil detection
	%   sPupil = getEyeTrackingOffline(sFile,strTempDir)
	
	%% retrieve paths and copy required files
	%placeholder
	sPupil = struct;
	%temp
	if ~strcmp(strTempDir(end),filesep)
		strTempDir(end+1) = filesep;
	end
	if ~isfolder(strTempDir)
		[status0,msg0,msgID0]=mkdir(strTempDir);
		if status0 == 0,error(msgID0,sprintf('Error creating temp path "%s": %s',strTempDir,msg0));end
	end
	
	%vid
	strVidFile = sFile.name;
	strVidPath = sFile.folder;
	if ~strcmp(strVidPath(end),filesep)
		strVidPath(end+1) = filesep;
	end
	%params
	strParFile = sFile.sTrackParams.name;
	strParPath = sFile.sTrackParams.folder;
	if ~strcmp(strParPath(end),filesep)
		strParPath(end+1) = filesep;
	end
	
	% copy files to local temp directory
	fprintf('Copying "%s" to local path "%s" [%s]\n',strVidFile,strTempDir,getTime);
	ETP_prepareMovie(strVidPath,strVidFile,strTempDir,'Yes');
	[status2,msg2,msgID2] = copyfile([strParPath strParFile],[strTempDir strParFile]);
	if status2 == 0,error(msgID2,sprintf('Error copying "%s": %s',strParFile,msg2));end
	if contains(strVidFile,'Raw')
		strMiniOut = strrep(strVidFile,'Raw','MiniVid');
		
		%create output name
		strTrackedFile = strrep(strVidFile,'Raw','Processed');
		strTrackedFile(find(strTrackedFile=='.',1,'last'):end) = [];
		strTrackedFile = strcat(strTrackedFile,'.mat');
	else
		strMiniOut = [strVidFile(1:(end-4)) 'MiniVid.mp4'];
		
		%create output name
		strTrackedFile = strVidFile;
		strTrackedFile(find(strTrackedFile=='.',1,'last'):end) = [];
		strTrackedFile = [strTrackedFile 'Processed.mat'];
	end
	
	%% retrieve paths and copy optional files
	%sync
	if isfield(sFile,'sSync') && ~isempty(sFile.sSync)
		strSyncFile = sFile.sSync.name;
		strSyncPath = sFile.sSync.folder;
		if ~strcmp(strSyncPath(end),filesep)
			strSyncPath(end+1) = filesep;
		end
		[status3,msg3,msgID3] = copyfile([strSyncPath strSyncFile],[strTempDir strSyncFile]);
		if status3 == 0,error(msgID3,sprintf('Error copying "%s": %s',strSyncFile,msg3));end
		
		%gather sync data
		sSyncData = sFile.sSync.sSyncData;
		sSyncData.matSyncData(:,(sSyncData.intSyncCounter+1):end) = [];
	else
		sSyncData = [];
	end
	
	%% get values
	sTrPar = sFile.sTrackParams.sET;
	dblGain = sTrPar.dblGain;
	dblGamma = sTrPar.dblGamma;
	intTempAvg = round(sTrPar.intTempAvg);
	dblGaussWidth = sTrPar.dblGaussWidth;
	dblPupilMinRadius = sTrPar.dblPupilMinRadius;
	sglReflT = sTrPar.dblThreshReflect;
	sglPupilT = sTrPar.dblThreshPupil;
	vecPupil = sTrPar.vecPupil;
	objSE = sTrPar.objSE;
	%add video
	sTrPar.strVidFile = strVidFile;
	sTrPar.strVidPath = strVidPath;
	
	%% build elements & check gpu
	% access video
	objVid = VideoReader([strTempDir strVidFile]);
	intAllFrames = objVid.NumberOfFrames;
	dblTotDurSecs = objVid.Duration;
	sTrPar.intAllFrames = intAllFrames;
	sTrPar.dblTotDurSecs = dblTotDurSecs;
	
	% check GPU
	try
		gTest = gpuArray(eye(10));
		boolUseGPU = true;
		delete(gTest);
	catch
		boolUseGPU = false;
	end
	
	%blur width
	if dblGaussWidth == 0
		if boolUseGPU
			gMatFilt = gpuArray(single(1));
		else
			gMatFilt = single(1);
		end
	else
		intGaussSize = ceil(dblGaussWidth*2);
		vecFilt = normpdf(-intGaussSize:intGaussSize,0,dblGaussWidth);
		matFilt = vecFilt' * vecFilt;
		matFilt = matFilt / sum(matFilt(:));
		if boolUseGPU
			gMatFilt = gpuArray(single(matFilt));
		else
			gMatFilt = single(matFilt);
		end
	end
	
	%% create rect vectors & draw image
	if any(sTrPar.vecRectSync > 1) || any(sTrPar.vecRectROI > 1)
		sTrPar.vecRectSync([1 3]) = sTrPar.vecRectSync([1 3])./sTrPar.intX;
		sTrPar.vecRectSync([2 4]) = sTrPar.vecRectSync([2 4])./sTrPar.intY;
		sTrPar.vecRectROI([1 3]) = sTrPar.vecRectROI([1 3])./sTrPar.intX;
		sTrPar.vecRectROI([2 4]) = sTrPar.vecRectROI([2 4])./sTrPar.intY;
	end
	%ROI
	vecRectROIPix = round([sTrPar.vecRectROI(1)*sTrPar.intX sTrPar.vecRectROI(2)*sTrPar.intY sTrPar.vecRectROI(3)*sTrPar.intX sTrPar.vecRectROI(4)*sTrPar.intY]);
	vecKeepY = vecRectROIPix(2):(vecRectROIPix(2)+vecRectROIPix(4));
	vecKeepX = vecRectROIPix(1):(vecRectROIPix(1)+vecRectROIPix(3));
	
	%check boundaries
	vecKeepY(vecKeepY<1)=[];
	vecKeepY(vecKeepY>sTrPar.intY)=[];
	vecKeepX(vecKeepX<1)=[];
	vecKeepX(vecKeepX>sTrPar.intX)=[];
	
	%Sync
	vecRectSyncPix = round([sTrPar.vecRectSync(1)*sTrPar.intX sTrPar.vecRectSync(2)*sTrPar.intY sTrPar.vecRectSync(3)*sTrPar.intX sTrPar.vecRectSync(4)*sTrPar.intY]);
	vecSyncY = vecRectSyncPix(2):(vecRectSyncPix(2)+vecRectSyncPix(4));
	vecSyncX = vecRectSyncPix(1):(vecRectSyncPix(1)+vecRectSyncPix(3));
	
	%% pre-allocate & load initial frames
	%create gui
	sFigETOM = ETO_genFastMonitor(sTrPar);
	
	%prep vars
	vecPrevLoc = [sTrPar.intX/2 sTrPar.intY/2];
	intFrame = 0;
	intBufferCounter = 0;
	intDetectFrame = 0;
	matBuffer = zeros(numel(vecKeepY),numel(vecKeepX),intTempAvg);
	vecBufferT = zeros(1,intTempAvg);
	
	%pre-allocate full-t variables
	vecPupilFullSyncLum = nan(1,intAllFrames);
	vecPupilFullSyncLumT = nan(1,intAllFrames);
	
	%pre-allocate skip-t variables
	intDetectFrames = floor(intAllFrames/intTempAvg);
	vecPupilTime = nan(1,intDetectFrames);
	vecPupilVidFrame = nan(1,intDetectFrames);
	vecPupilCenterX = nan(1,intDetectFrames);
	vecPupilCenterY = nan(1,intDetectFrames);
	vecPupilRadius = nan(1,intDetectFrames);
	vecPupilEdgeHardness = nan(1,intDetectFrames);
	vecPupilMeanPupilLum = nan(1,intDetectFrames);
	vecPupilSdPupilLum = nan(1,intDetectFrames);
	vecPupilAbsVidLum = nan(1,intDetectFrames);
	vecPupilApproxConfidence = nan(1,intDetectFrames);
	vecPupilApproxRoundness = nan(1,intDetectFrames);
	vecPupilApproxRadius = nan(1,intDetectFrames);
	vecPupilSyncLum = nan(1,intDetectFrames);
	vecPupilNotReflection = nan(1,intDetectFrames);
	%prep minivid
	[strPath,strMiniFile,strExt]=fileparts(strMiniOut);
	strMiniOut = strcat(strMiniFile,'.mj2');
	objMiniVid = VideoWriter(fullpath(strTempDir,strMiniOut), 'Archival');
	objMiniVid.FrameRate = objVid.FrameRate/intTempAvg;
	open(objMiniVid);
	
	%run
	dblLastUpdate = -inf;
	dblUpdateInterval = 1;
	dblLastT = 0;
	hTic = tic;
	dblCurTime = 0;
	while hasFrame(objVid)
		%% read frame and add to buffer
		intFrame = intFrame + 1;
		try
			matVidRaw = readFrame(objVid);
		catch
			pause(0.5);
			warning([mfilename ':ReadError'],sprintf('Frame %d/%d (t=%.3s) could not be read',intFrame,intTotFrames,dblCurTime));
		end
		dblCurTime = objVid.CurrentTime;
		
		% load frame
		matCurFrame = single(matVidRaw)./255;
		
		%add to buffer
		intBufferCounter = intBufferCounter + 1;
		if intBufferCounter > intTempAvg
			intBufferCounter = 1;
		end
		matBuffer(:,:,intBufferCounter) = matCurFrame(vecKeepY,vecKeepX,1);
		vecBufferT(intBufferCounter) = dblCurTime;
		
		%select sync ROI & save data
		matSync = matCurFrame(vecSyncY,vecSyncX,1);
		dblSync = mean(matSync(:));
		vecPupilFullSyncLum(intFrame) = dblSync;
		vecPupilFullSyncLumT(intFrame) = dblCurTime;
		
		%% check if buffer is full
		if intBufferCounter == intTempAvg
			%% run detection
			%compile counters
			intDetectFrame = intDetectFrame + 1;
			
			%average
			matFrame = mean(matBuffer,3);
			dblT = mean(vecBufferT);
			dblSyncLum = mean(vecPupilFullSyncLum((intFrame-intTempAvg+1):intFrame));
			
			%send frame to gpu
			if boolUseGPU
				gMatVid = gpuArray(matFrame);
			else
				gMatVid = matFrame;
			end
			
			% apply image corrections
			gMatVid = imadjust(gMatVid,[],[],dblGamma).*dblGain;
			gMatVid(gMatVid(:)>1)=1;
			
			%write mini vid
			writeVideo(objMiniVid,gather(gMatVid));
		
			%detect
			[sPupilDetected,imPupil,imReflection,imBW,imGrey] = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,vecPrevLoc,vecPupil,sTrPar);
			vecPrevLoc = sPupilDetected.vecCentroid;
			
			%% save tracking data
			dblAbsVidLum = mean(gMatVid(:));
			vecPupilTime(intDetectFrame) = dblT;
			vecPupilVidFrame(intDetectFrame) = round(intFrame-intTempAvg/2);
			vecPupilCenterX(intDetectFrame) = sPupilDetected.vecCentroid(1);
			vecPupilCenterY(intDetectFrame) = sPupilDetected.vecCentroid(2);
			vecPupilRadius(intDetectFrame) = sPupilDetected.dblRadius;
			vecPupilEdgeHardness(intDetectFrame) = sPupilDetected.dblEdgeHardness;
			vecPupilMeanPupilLum(intDetectFrame) = sPupilDetected.dblMeanPupilLum;
			vecPupilSdPupilLum(intDetectFrame) = sPupilDetected.dblSdPupilLum;
			vecPupilAbsVidLum(intDetectFrame) = dblAbsVidLum;
			vecPupilApproxConfidence(intDetectFrame) = sPupilDetected.dblApproxConfidence;
			vecPupilApproxRoundness(intDetectFrame) = sPupilDetected.dblApproxRoundness;
			vecPupilApproxRadius(intDetectFrame) = sPupilDetected.dblApproxRadius;
			vecPupilSyncLum(intDetectFrame) = dblSyncLum;
			vecPupilNotReflection(intDetectFrame) = sum(imReflection(:));
			
			%add variables to pupil structure
			%sPupil.dblSyncLum = dblSyncLum;
			%sPupil.dblAbsVidLum = dblAbsVidLum;
			%if intDetectFrame == 1
			%	sPupil1 = sPupil;
			%end
			
			%% update screen
			if toc(hTic)-dblLastUpdate > dblUpdateInterval
				sFigETOM.ptrTextCurT.String = sprintf('Now at: t=%.3f s / %.3f s: %.3f s per second',dblT,dblTotDurSecs,(dblT-dblLastT)/(toc(hTic)-dblLastUpdate));
				drawnow;
				dblLastT = dblT;
				dblLastUpdate = toc(hTic);
			end
			%sIms = struct;
			%sIms.imPupil = imPupil;
			%sIms.imReflection = imReflection;
			%sIms.imBW = imBW;
			%sIms.imGrey = imGrey;
			
			%redraw images
			%ETO_redraw(sFigETOM,sIms,sPupil,matCurFrame);
			
			%update plots
			%ETO_updateMonitor(sFigETOM,sPupil,sPupil1,dblT,sTrPar.dblTotDurSecs);
		end
	end
	%close monitor
	close(sFigETOM.ptrMainGUI);
	
	%close mini vid
	close(objMiniVid);
	delete(objVid);
	
	%% interpolate detection failures
	%combine all metrics
	vecEdge = abs(max(zscore(vecPupilEdgeHardness)) - zscore(vecPupilEdgeHardness));
	vecDist = sqrt(zscore(vecPupilCenterX).^2 + zscore(vecPupilCenterY).^2);
	vecRound = abs(max(zscore(vecPupilApproxRoundness)) - zscore(vecPupilApproxRoundness));
	indWrong = (zscore(vecRound+vecDist) > 1) | abs(zscore(vecPupilCenterX))>2;
	indWrong = conv(indWrong,ones(1,5),'same')>0;
	vecAllPoints = 1:numel(indWrong);
	vecGoodPoints = find(~indWrong);
	vecBadPoints = find(indWrong);
	
	%{
	%initial roundness check
	indWrongA = sqrt(zscore(vecPupilCenterX).^2 + zscore(vecPupilCenterY).^2) > 4;
	indWrong1 = conv(indWrongA,ones(1,5),'same')>0;
	vecAllPoints1 = 1:numel(indWrong1);
	vecGoodPoints1 = find(~indWrong1);
	vecTempX = interp1(vecGoodPoints1,vecPupilCenterX(~indWrong1),vecAllPoints1);
	vecTempY = interp1(vecGoodPoints1,vecPupilCenterY(~indWrong1),vecAllPoints1);
	%remove position outliers
	indWrongB = abs(nanzscore(vecTempX)) > 4 | abs(nanzscore(vecTempY)) > 4;
	%remove low edge hardness points
	indWrongC = zscore(vecPupilEdgeHardness) < -3;
	%define final removal vector
	indWrong = conv(indWrongA | indWrongB | indWrongC,ones(1,5),'same')>0;
	vecAllPoints = 1:numel(indWrong);
	vecGoodPoints = find(~indWrong);
	%}
	
	%fix
	vecPupilFixedCenterX = interp1(vecGoodPoints,vecPupilCenterX(~indWrong),vecAllPoints,'linear','extrap');
	vecPupilFixedCenterY = interp1(vecGoodPoints,vecPupilCenterY(~indWrong),vecAllPoints,'linear','extrap');
	vecPupilFixedRadius = interp1(vecGoodPoints,vecPupilRadius(~indWrong),vecAllPoints,'linear','extrap');
	
	%% gather data
	%check which frames to remove
	intLastFrame = find(~(isnan(vecPupilApproxConfidence) | vecPupilApproxConfidence == 0),1,'last');
	vecPupilTime = vecPupilTime(1:intLastFrame);
	vecPupilVidFrame = vecPupilVidFrame(1:intLastFrame);
	vecPupilSyncLum = vecPupilSyncLum(1:intLastFrame);
	vecPupilCenterX = vecPupilCenterX(1:intLastFrame);
	vecPupilCenterY = vecPupilCenterY(1:intLastFrame);
	vecPupilRadius = vecPupilRadius(1:intLastFrame);
	vecPupilEdgeHardness = vecPupilEdgeHardness(1:intLastFrame);
	vecPupilMeanPupilLum = vecPupilMeanPupilLum(1:intLastFrame);
	vecPupilAbsVidLum = vecPupilAbsVidLum(1:intLastFrame);
	vecPupilSdPupilLum = vecPupilSdPupilLum(1:intLastFrame);
	vecPupilApproxConfidence = vecPupilApproxConfidence(1:intLastFrame);
	vecPupilApproxRoundness = vecPupilApproxRoundness(1:intLastFrame);
	vecPupilApproxRadius = vecPupilApproxRadius(1:intLastFrame);
	vecPupilNotReflection = vecPupilNotReflection(1:intLastFrame);
	vecPupilFixedCenterX = vecPupilFixedCenterX(1:intLastFrame);
	vecPupilFixedCenterY = vecPupilFixedCenterY(1:intLastFrame);
	vecPupilFixedRadius = vecPupilFixedRadius(1:intLastFrame);
	vecPupilFixedPoints = indWrong;
	
	%output
	sPupil = struct;
	sPupil.sSyncData = sSyncData;
	
	%full vectors
	sPupil.vecPupilFullSyncLum = vecPupilFullSyncLum;
	sPupil.vecPupilFullSyncLumT = vecPupilFullSyncLumT;
	
	%timing
	sPupil.vecPupilTime = vecPupilTime;
	sPupil.vecPupilVidFrame = vecPupilVidFrame;
	sPupil.vecPupilSyncLum = vecPupilSyncLum;
	
	%raw
	sPupil.vecPupilCenterX = vecPupilCenterX;
	sPupil.vecPupilCenterY = vecPupilCenterY;
	sPupil.vecPupilRadius = vecPupilRadius;
	sPupil.vecPupilEdgeHardness = vecPupilEdgeHardness;
	sPupil.vecPupilMeanPupilLum = vecPupilMeanPupilLum;
	sPupil.vecPupilAbsVidLum = vecPupilAbsVidLum;
	
	sPupil.vecPupilSdPupilLum = vecPupilSdPupilLum;
	sPupil.vecPupilApproxConfidence = vecPupilApproxConfidence;
	sPupil.vecPupilApproxRoundness = vecPupilApproxRoundness;
	sPupil.vecPupilApproxRadius = vecPupilApproxRadius;
	sPupil.vecPupilNotReflection = vecPupilNotReflection;
	%fixed
	sPupil.vecPupilFixedCenterX = vecPupilFixedCenterX;
	sPupil.vecPupilFixedCenterY = vecPupilFixedCenterY;
	sPupil.vecPupilFixedRadius = vecPupilFixedRadius;
	sPupil.vecPupilFixedPoints = vecPupilFixedPoints;
	
	%extra info
	sPupil.strVidFile = strVidFile;
	sPupil.strVidPath = strVidPath;
	sPupil.sTrackParams = sTrPar;
	sPupil.strMiniVidPath = strVidPath;
	sPupil.strMiniVidFile = strMiniOut;
	sPupil.name = strTrackedFile;
	
	
	%% save file
	%save
	save([strVidPath strTrackedFile],'sPupil');
	fprintf('Saved data to %s (source: %s, path: %s) [%s]\n',strTrackedFile,strVidFile,strVidPath,getTime);
	
	%copy mini vid
	copyfile([strTempDir strMiniOut],[strVidPath strMiniOut]);
	fprintf('Saved minivid to %s (source: %s, target: %s) [%s]\n',strMiniOut,strTempDir,strVidPath,getTime);
	
	%% plot output
	ETO_plotResults(sPupil);
	strResultsFig = strVidFile(1:(end-4));
	drawnow;
	try
		export_fig([strVidPath strResultsFig '.tif']);
		export_fig([strVidPath strResultsFig '.pdf']);
	catch
		print([strVidPath strResultsFig],'-dtiff');
		print([strVidPath strResultsFig],'-dpdf');
	end
%end

