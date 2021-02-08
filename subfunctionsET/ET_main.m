function ET_main(varargin)
	%% ET_main
	%get globals
	global sEyeFig;
	global sET;
	cellText = {};
	
	%retrieve variables
	if isfield(sET,'objVid')
		objVid = sET.objVid;
	else
		return;
	end
	
	%% prepare: set parameters
	%set initial dummy values
	intTempAvg = -1; %number of frames to average over; higher values limit detection rates
	dblGaussWidth = -1; %blur width
	vecRectROI = [0 0 0 0]; %crop
	vecRectSync = [0 0 0 0];
	dblThreshReflect = -1;%threshold for reflection (invert brightness if above)
	dblThreshPupil = -1;%threshold for pupil (potential pupil if below)
	dblPupilMinRadius = -1; %minimum radius of pupil (remove area if below)
	intRadStrEl = 0;
	vecPrevLoc = [0;0];
	
	%morph close iters
	%pupil size min/max
	dblDetectRate = 0;
	boolSyncHigh = 0;
	sET.intSyncPulse = 0;
	sET.dblRecStart = 0;
	dblThreshSync = 0;
	
	%% run for all eternity
	try
		%start
		start(objVid);
		
		sEyeFig.boolIsBusy = true;
		boolIsRunning = true;
		while boolIsRunning
			%check global value
			boolIsRunning = sEyeFig.boolIsRunning;
			
			%% update parameters if necessary
			%other switches, etc
			boolDetectPupil = sET.boolDetectPupil; %not detecting increases speed
			boolSaveToDisk = sET.boolSaveToDisk; %not saving increasing speed
			boolRecording = sET.boolRecording;
			
			%build structuring elements
			if sET.intSubSample == 1 && intRadStrEl ~= 2
				intRadStrEl = 2; %switched to 2, 2019-11-11
				objSE = strel('disk',intRadStrEl,4);
			elseif sET.intSubSample == 2 && intRadStrEl ~= 2
				intRadStrEl = 2;
				objSE = strel('disk',intRadStrEl,4);
			end
			
			%sync threshold luminance
			if dblThreshSync ~= sET.dblThreshSync
				sET.dblThreshSync = max([min([sET.dblThreshSync 255]) 1]); %range: 1-10
				dblThreshSync = sET.dblThreshSync;
			end
			%temp averaging
			if intTempAvg ~= sET.intTempAvg
				sET.intTempAvg = max([min([sET.intTempAvg 10]) 1]); %range: 1-10
				intTempAvg = sET.intTempAvg;
			end
			%Pupil ROI: [x-from-left y-from-top x-width y-height]
			if ~all(vecRectROI == sET.vecRectROI)
				vecRectROI = round(sET.vecRectROI);
				vecKeepY = vecRectROI(2):(vecRectROI(2)+vecRectROI(4));
				vecKeepX = vecRectROI(1):(vecRectROI(1)+vecRectROI(3));
				
				%check boundaries
				vecKeepY(vecKeepY<1)=[];
				vecKeepY(vecKeepY>sET.intMaxY)=[];
				vecKeepX(vecKeepX<1)=[];
				vecKeepX(vecKeepX>sET.intMaxX)=[];
				
				%rebuild ROI
				vecRectROI = [vecKeepX(1) vecKeepY(1) vecKeepX(end)-vecKeepX(1) vecKeepY(end)-vecKeepY(1)];
				vecPlotRectX = [vecRectROI(1) vecRectROI(1) vecRectROI(1)+vecRectROI(3) vecRectROI(1)+vecRectROI(3) vecRectROI(1)];
				vecPlotRectY = [vecRectROI(2) vecRectROI(2)+vecRectROI(4) vecRectROI(2)+vecRectROI(4) vecRectROI(2) vecRectROI(2)];
				sET.vecRectROI = vecRectROI;
			end
			%Sync ROI: [x-from-left y-from-top x-width y-height]
			if ~all(vecRectSync == sET.vecRectSync)
				vecRectSync = round(sET.vecRectSync);
				vecSyncY = vecRectSync(2):(vecRectSync(2)+vecRectSync(4));
				vecSyncX = vecRectSync(1):(vecRectSync(1)+vecRectSync(3));
				
				%check boundaries
				vecSyncY(vecSyncY<1)=[];
				vecSyncY(vecSyncY>sET.intMaxY)=[];
				vecSyncX(vecSyncX<1)=[];
				vecSyncX(vecSyncX>sET.intMaxX)=[];
				
				%rebuild ROI
				vecRectSync = [vecSyncX(1) vecSyncY(1) vecSyncX(end)-vecSyncX(1) vecSyncY(end)-vecSyncY(1)];
				vecPlotSyncX = [vecRectSync(1) vecRectSync(1) vecRectSync(1)+vecRectSync(3) vecRectSync(1)+vecRectSync(3) vecRectSync(1)];
				vecPlotSyncY = [vecRectSync(2) vecRectSync(2)+vecRectSync(4) vecRectSync(2)+vecRectSync(4) vecRectSync(2) vecRectSync(2)];
				sET.vecRectSync = vecRectSync;
			end
			%blur width
			if dblGaussWidth ~= sET.dblGaussWidth
				dblGaussWidth = sET.dblGaussWidth;
				if dblGaussWidth == 0
					if sET.boolUseGPU
						gMatFilt = gpuArray(single(1));
					else
						gMatFilt = single(1);
					end
				else
					intGaussSize = ceil(dblGaussWidth*2);
					vecFilt = normpdf(-intGaussSize:intGaussSize,0,dblGaussWidth);
					matFilt = vecFilt' * vecFilt;
					matFilt = matFilt / sum(matFilt(:));
					if sET.boolUseGPU
						gMatFilt = gpuArray(single(matFilt));
					else
						gMatFilt = single(matFilt);
					end
				end
			end
			
			%thresholds: reflection/pupil
			if dblThreshReflect ~= sET.dblThreshReflect
				dblThreshReflect = sET.dblThreshReflect;
				sglReflT = single(dblThreshReflect);
			end
			if dblThreshPupil ~= sET.dblThreshPupil
				dblThreshPupil = sET.dblThreshPupil;
				sglPupilT = single(dblThreshPupil);
			end
			if dblPupilMinRadius ~= sET.dblPupilMinRadius
				dblPupilMinRadius = sET.dblPupilMinRadius;
				dblPupilMinPixSize = pi*dblPupilMinRadius^2;
			end
			
			%% check new frames
			if objVid.FramesAvailable >= sET.intTempAvg
				%% get video data
				warning('off','imaq:getdata:infFramesPerTrigger');
				intFrAvail = objVid.FramesAvailable;
				[matVidRaw, vecTime, sMetadata] = getdata(objVid);
				warning('on','imaq:getdata:infFramesPerTrigger');
				intFrAcq = objVid.FramesAcquired;
				%subsample
				vecSubY = 1:sET.intSubSample:size(matVidRaw,1);
				vecSubX = 1:sET.intSubSample:size(matVidRaw,2);
				matVidRaw = matVidRaw(vecSubY,vecSubX,:,:);
				if sET.boolRotateImage
					matVidRaw = permute(matVidRaw,[2 1 3:ndims(matVidRaw)]);
				end
				
				%% get spikeGLX timestamp
				if ~isempty(sET.hSGL)
					intCurCountNI = GetScanCount(sET.hSGL, sET.intStreamNI);
					dblEphysTimeNI = intCurCountNI/sET.dblSampFreqNI;
					
					%create sync matrix
					if ~isfield(sET,'sSyncData')
						sET.sSyncData = struct;
						sET.sSyncData.MatrixEntries = 'matSyncData([TimeVid FrameVid TimeNI FrameNI],t)';
						sET.sSyncData.intSyncCounter = 1;
						sET.sSyncData.matSyncData = nan(4,10000);
					end
					
					%enlarge matrix
					if sET.sSyncData.intSyncCounter > size(sET.sSyncData.matSyncData,2)
						sET.sSyncData.matSyncData = cat(2,sET.sSyncData.matSyncData,nan(size(sET.sSyncData.matSyncData,1),10000));
					end
					%save data & update counter
					sET.sSyncData.matSyncData(:,sET.sSyncData.intSyncCounter) = [vecTime(end) sET.objVidWriter.FrameCount dblEphysTimeNI intCurCountNI];
					sET.sSyncData.intSyncCounter = sET.sSyncData.intSyncCounter + 1;
					
				else
					intCurCountNI = 0;
					dblEphysTimeNI = 0;
				end
				
				%% flush to disk
				if boolRecording && boolSaveToDisk
					warning('off','MATLAB:audiovideo:VideoWriter:mp4FramePadded');
					writeVideo(sET.objVidWriter,matVidRaw);
					warning('on','MATLAB:audiovideo:VideoWriter:mp4FramePadded');
					set(sEyeFig.ptrTextVidOutDuration,'String',sprintf('%.1f',sET.objVidWriter.Duration));
					set(sEyeFig.ptrTextVidOutFrameCount,'String',sprintf('%.0f',sET.objVidWriter.FrameCount));
				end
				%get file size
				if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Path')
					sFile=dir(strcat(sET.objVidWriter.Path,sET.objVidWriter.Filename));
				end
				if exist('sFile','var') && numel(sFile) > 0
					dblVidMB = sFile(1).bytes / (1024*1024);
				else
					dblVidMB = 0;
				end
				
				%% perform pupil detection
				%select ROI
				vecUseFrames = (size(matVidRaw,4)-intTempAvg+1):size(matVidRaw,4);
				matVid = imnorm(mean(single(matVidRaw(:,:,1,vecUseFrames)),4));
				if sET.boolUseGPU
					gMatVid = gpuArray(matVid(vecKeepY,vecKeepX));
				else
					gMatVid = matVid(vecKeepY,vecKeepX);
				end
				
				%show video
				imagesc(sEyeFig.ptrAxesMainVideo,matVidRaw(:,:,1,end));
				colormap(sEyeFig.ptrAxesMainVideo,'grey');
                axis(sEyeFig.ptrAxesMainVideo,'off');
				
				%detect pupil?
				if boolDetectPupil
					%find pupil
					vecPupil = sglPupilT;%(sglPupilT-2):(sglPupilT+1);
					[sPupil,imPupil,imReflection,imBW,imGrey] = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,vecPrevLoc,vecPupil,sET);
					
					%get synchronization pulse window luminance
					dblSyncLum = mean(flat(matVidRaw(vecSyncY,vecSyncX,1,end)));
					boolLastSyncHigh = boolSyncHigh;
					boolSyncHigh = dblSyncLum > dblThreshSync;
					if boolSyncHigh && (boolLastSyncHigh ~= boolSyncHigh)
						sET.intSyncPulse = sET.intSyncPulse + 1;
					end
					
					%extract parameters
					vecCentroid = sPupil.vecCentroid;
					vecPrevLoc = vecCentroid;
					dblMajAx = sPupil.dblRadius;
					dblMinAx = dblMajAx;
					dblOri = 0;
					dblRoundness = sPupil.dblApproxRoundness;
					dblEccentricity = sPupil.dblApproxConfidence;
                    dblEdgeHardness = sPupil.dblEdgeHardness;
					
					%orig with overlays
					hold(sEyeFig.ptrAxesMainVideo,'on');
					plot(sEyeFig.ptrAxesMainVideo,vecPlotSyncX,vecPlotSyncY,'c--');
					plot(sEyeFig.ptrAxesMainVideo,vecPlotRectX,vecPlotRectY,'b--');
					dblX = vecCentroid(1) + vecPlotRectX(1);
					dblY = vecCentroid(2) + vecPlotRectY(1);
					ellipse(sEyeFig.ptrAxesMainVideo,dblX,dblY,dblMajAx,dblMinAx,deg2rad(dblOri)-pi/4,'Color','r','LineStyle','--');
					hold(sEyeFig.ptrAxesMainVideo,'off');
					
					%closed
					imagesc(sEyeFig.ptrAxesSubVid1,imGrey);
					colormap(sEyeFig.ptrAxesSubVid1,'grey');
					axis(sEyeFig.ptrAxesSubVid1,'off');
					
					%regions
					imagesc(sEyeFig.ptrAxesSubVid2,imBW);
					colormap(sEyeFig.ptrAxesSubVid2,'parula');
					axis(sEyeFig.ptrAxesSubVid2,'off');
					dblLastDetectRate = dblDetectRate;
					dblNewDetectRate = sET.dblRealFrameRate/intFrAvail;
					dblDetectRate = (dblLastDetectRate + dblNewDetectRate)/2;
				else
					vecCentroid = [-1 -1];
					dblMajAx = -1;
					dblMinAx = -1;
					dblOri = -1;
					dblEccentricity = -1;
					dblRoundness = 0;
					dblEdgeHardness = 0;
					dblLastDetectRate = 0;
					dblDetectRate = 0;
					dblSyncLum = 0;
				end
				
				%% update figure
				set(sEyeFig.ptrTextDetectRate,'String',sprintf('%.3f',dblDetectRate));
				set(sEyeFig.ptrTextVidTime,'String',sprintf('%.3f',vecTime(end)-sET.dblRecStart));
				set(sEyeFig.ptrTextVidMB,'String',sprintf('%.2f',dblVidMB));
				set(sEyeFig.ptrTextPupilRoundness,'String',sprintf('%.3f',dblEdgeHardness));
				set(sEyeFig.ptrTextSyncLum,'String',sprintf('%.1f',dblSyncLum));
				set(sEyeFig.ptrTextSyncPulseCount,'String',sprintf('%.0f',sET.intSyncPulse));
				set(sEyeFig.ptrTextNITime,'String',sprintf('%.3f',dblEphysTimeNI));
				
				%% output pupil properties
				if sET.boolRecording && boolDetectPupil && isfield(sET,'ptrDataOut')
					%prepare data line
					%Time,VidFrame,SyncLum,SyncPulse,CenterX,CenterY,MajorAx,MinorAx,Orient,Eccentric,Roundness,FrameNI,SecsNI
					vecData = [vecTime(end) sET.objVidWriter.FrameCount dblSyncLum sET.intSyncPulse vecCentroid(1) vecCentroid(2) dblMajAx dblMinAx dblOri dblEccentricity dblRoundness intCurCountNI dblEphysTimeNI];
					strData = sprintf('"%.3f",',vecData);
					strData = strcat(strData(1:(end-1)),'\n');
					%write to file
					fprintf(sET.ptrDataOut,strData);
				end
				
				%% unlock on first run
				if ~sET.IsInitialized
					sET.IsInitialized = true;
					ET_unlock(sEyeFig);
				end
			end
			
			%pause
			drawnow;pause(0.01);
		end
		
		%stop video stream
		delete(objVid);
		
		%stop recording and save data
		ET_stopRecording();
		
		%close program
		delete(sEyeFig.ptrMainGUI);
	catch ME
		%clean up
		delete(objVid);
		if isfield(sET,'objVidWriter'),close(sET.objVidWriter);end
		try,fclose(sET.ptrDataOut);catch,end
		rethrow(ME);
		delete(sEyeFig.ptrMainGUI);
	end
	
