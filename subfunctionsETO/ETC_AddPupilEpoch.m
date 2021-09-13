function ETC_AddPupilEpoch(hObject,eventdata,strType)
	%globals
	global sFigETC;
	global sETC;
	
	%get temporary epoch
	sEpoch = sFigETC.sEpochTemp;
	
	%get modifier
	boolControlPressed = getAsyncKeyState(VirtualKeyCode.VK_CONTROL);
	boolAltPressed = getAsyncKeyState(VirtualKeyCode.VK_MENU);
	
	%if not new, set time to beginning & redraw
	intSelectEpoch = sFigETC.ptrEpochList.Value;
	cellEpochList = sFigETC.ptrEpochList.String;
	if isempty(sEpoch)
		if intSelectEpoch == numel(cellEpochList)
			%gen
			sEpoch = ETC_GenEmptyEpochs();
			sEpoch(1).BeginFrame = nan;
			sEpoch(1).EndFrame = nan;
		else
			%load data
			sEpoch = sFigETC.sPupil.sEpochs(intSelectEpoch);
		end
	end
	
	%get current frame and ask for pupil drawing
	if strcmpi(strType,'begin')
		intCurrFrame = sFigETC.intCurFrame;
		sLabels = ETP_GetImLabels(sFigETC.ptrCurFrame.CData(:,:,1));
		sEpoch.BeginLabels = sLabels;
		sEpoch.BeginFrame = intCurrFrame;
	elseif strcmpi(strType,'end')
		intCurrFrame = sFigETC.intCurFrame;
		sLabels = ETP_GetImLabels(sFigETC.ptrCurFrame.CData(:,:,1));
		sEpoch.EndLabels = sLabels;
		sEpoch.EndFrame = intCurrFrame;
	elseif isscalar(strType) && isint(strType) && strType > 0
		%get data
		vecT = sFigETC.ptrAxesX.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesX.Children,'UniformOutput',false),'line')).XData;
		vecX = sFigETC.ptrAxesX.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesX.Children,'UniformOutput',false),'line')).YData;
		vecY = sFigETC.ptrAxesY.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesY.Children,'UniformOutput',false),'line')).YData;
		vecR = sFigETC.ptrAxesR.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesR.Children,'UniformOutput',false),'line')).YData;
		%check end
		intCurrFrame = strType;
		if intCurrFrame > numel(vecT),return;end
		
		%get current data
		sLabels = struct;
		%check if epoch overlaps current frame
		%draw epoch if overlapping
		indHasLabels = arrayfun(@(x) ~isempty(x.BeginLabels) & ~isempty(x.EndLabels),sFigETC.sPupil.sEpochs);
		indHasOverlap = cell2vec({sFigETC.sPupil.sEpochs.BeginFrame}) <= intCurrFrame & cell2vec({sFigETC.sPupil.sEpochs.EndFrame}) >= intCurrFrame;
		boolUseDefault = true;
		if ~isempty(indHasLabels)
			indEligible = indHasLabels(:) & indHasOverlap;
			intUseEpoch = find(indEligible,1,'last');
			if ~isempty(intUseEpoch)
				%extract parameters
				sReadFromEpoch = sFigETC.sPupil.sEpochs(intUseEpoch);
				intFrameInEpoch = intCurrFrame - sReadFromEpoch.BeginFrame + 1;
				sLabels.X = sReadFromEpoch.CenterX(intFrameInEpoch);
				sLabels.Y = sReadFromEpoch.CenterY(intFrameInEpoch);
				sLabels.R = sReadFromEpoch.Radius(intFrameInEpoch);
				boolUseDefault = false;
			end
		end
		if boolUseDefault
			%otherwise use original values
			sLabels.X = vecX(intCurrFrame);
			sLabels.Y = vecY(intCurrFrame);
			sLabels.R = vecR(intCurrFrame);
		end
		
		%assign
		if ~isnan(sEpoch.BeginFrame) && isnan(sEpoch.EndFrame)
			sEpoch.EndLabels = sLabels;
			sEpoch.EndFrame = intCurrFrame;
		else
			sEpoch.BeginLabels = sLabels;
			sEpoch.BeginFrame = intCurrFrame;
		end
	else
		error([mfilename ':TypeMissing'],'Type missing');
	end
	
	%check if epoch is complete
	if ~isnan(sEpoch.BeginFrame) && ~isnan(sEpoch.EndFrame) && sEpoch.BeginFrame > 0  && sEpoch.EndFrame > 0 && ~isempty(sEpoch.BeginLabels) && ~isempty(sEpoch.EndLabels)
		%swap end/begin if end < begin
		if sEpoch.EndFrame < sEpoch.BeginFrame
			intOldBeginF = sEpoch.BeginFrame;
			sOldBeginL = sEpoch.BeginLabels;
			sEpoch.BeginFrame = sEpoch.EndFrame;
			sEpoch.BeginLabels = sEpoch.EndLabels;
			sEpoch.EndFrame = intOldBeginF;
			sEpoch.EndLabels = sOldBeginL;
		end
		
		%interpolate or detect pupil between beginning and end of epoch
		intSwitchDetectOrInterpolate = sFigETC.ptrEpochInterpolate.Value; %0=detect,1=interp
		vecFrames = sEpoch.BeginFrame:sEpoch.EndFrame;
		intFrames = numel(vecFrames);
		if (intSwitchDetectOrInterpolate == 1 && ~boolAltPressed) || ~isfield(sFigETC.sPupil,'sTrackParams') || boolControlPressed
			sEpoch.CenterX = linspace(sEpoch.BeginLabels.X,sEpoch.EndLabels.X,intFrames);
			sEpoch.CenterY = linspace(sEpoch.BeginLabels.Y,sEpoch.EndLabels.Y,intFrames);
			sEpoch.Radius = linspace(sEpoch.BeginLabels.R,sEpoch.EndLabels.R,intFrames);
			sEpoch.Blinks = [];
		else
			%% run detection algorithm
			%set message
			% lock
			try
				uilock(sFigETC);
				%msg
				hWaitbar = waitbar(0,sprintf('Preparing pupil detection...'),'Name','Detecting pupil');
				movegui(hWaitbar,'center')
				drawnow;
				hTic = tic;
				
				%% get values
				sTrPar = sFigETC.sPupil.sTrackParams;
				dblGaussWidth = sTrPar.dblGaussWidth;
				dblReflT = sTrPar.dblThreshReflect;
				vecPupil = sTrPar.vecPupil;
				objSE = sTrPar.objSE;
				
				%% make filter
				%blur width
				if dblGaussWidth == 0
					if sETC.boolUseGPU
						gMatFilt = gpuArray(single(1));
					else
						gMatFilt = single(1);
					end
				else
					intGaussSize = ceil(dblGaussWidth*2);
					vecFilt = normpdf(-intGaussSize:intGaussSize,0,dblGaussWidth);
					matFilt = vecFilt' * vecFilt;
					matFilt = matFilt / sum(matFilt(:));
					if sETC.boolUseGPU
						gMatFilt = gpuArray(single(matFilt));
					else
						gMatFilt = single(matFilt);
					end
				end
				
				%% read values at starting frame
				%load beginning video frame
				if isfield(sETC,'matVid') && ~isempty(sETC.matVid)
					matFrame = sETC.matVid(:,:,:,vecFrames(1));
				else
					matFrame = read(sETC.objVid,vecFrames(1));
				end
				matFrame = mean(matFrame,3);
				%rescale
				if any(all(matFrame<(max(matFrame(:))/10),2))
					matFrame(all(matFrame<(max(matFrame(:))/10),2),:) = median(matFrame(:));
				end
				if any(all(matFrame<(max(matFrame(:))/10),1))
					matFrame(:,all(matFrame<(max(matFrame(:))/10),1)) = median(matFrame(:));
				end
				matFrame = imnorm(matFrame)*255;
				
				%prep im
				matFrame = gather(ET_ImPrep(matFrame,gMatFilt,dblReflT,objSE,false));
	
				%retrieve median pupil luminance
				[matX,matY] = meshgrid(1:size(matFrame,2),1:size(matFrame,1));
				[dummy,vecDist] = cart2pol(matY-sEpoch.BeginLabels.Y,matX-sEpoch.BeginLabels.X);
				indInner = vecDist < sEpoch.BeginLabels.R;
				dblOldPupilT = sTrPar.dblThreshPupil;
				dblBeginPupilT = median(matFrame(indInner));
				
				%% load end video frame
				if isfield(sETC,'matVid') && ~isempty(sETC.matVid)
					matFrame = sETC.matVid(:,:,:,vecFrames(end));
				else
					matFrame = read(sETC.objVid,vecFrames(end));
				end
				matFrame = mean(matFrame,3);
				%rescale
				if any(all(matFrame<(max(matFrame(:))/10),2))
					matFrame(all(matFrame<(max(matFrame(:))/10),2),:) = median(matFrame(:));
				end
				if any(all(matFrame<(max(matFrame(:))/10),1))
					matFrame(:,all(matFrame<(max(matFrame(:))/10),1)) = median(matFrame(:));
				end
				matFrame = imnorm(matFrame)*255;
				
				%prep im
				matFrame = gather(ET_ImPrep(matFrame,gMatFilt,dblReflT,objSE,false));
					
				%retrieve median pupil luminance for end
				[dummy,vecDist] = cart2pol(matY-sEpoch.EndLabels.Y,matX-sEpoch.EndLabels.X);
				indInner = vecDist < sEpoch.BeginLabels.R;
				dblEndPupilT = median(matFrame(indInner));
				vecPupil = linspace(dblBeginPupilT,dblEndPupilT,5);
				dblPupilT = mean(vecPupil);
				vecPupil = vecPupil-std(vecPupil);
				
				%% detect
				%pre-allocate
				vecForwardX = zeros(1,intFrames);
				vecForwardY = zeros(1,intFrames);
				vecForwardR = zeros(1,intFrames);
				vecReverseX = zeros(1,intFrames);
				vecReverseY = zeros(1,intFrames);
				vecReverseR = zeros(1,intFrames);
				%assign first & last frame
				vecForwardX(1) = sEpoch.BeginLabels.X;
				vecForwardY(1) = sEpoch.BeginLabels.Y;
				vecForwardR(1) = sEpoch.BeginLabels.R;
				vecReverseX(end) = sEpoch.EndLabels.X;
				vecReverseY(end) = sEpoch.EndLabels.Y;
				vecReverseR(end) = sEpoch.EndLabels.R;
				
				%% load video frames
				matEpochFrames = zeros(size(matFrame,1),size(matFrame,2),intFrames);
				matEpochFrames(:,:,1) = matFrame;
				for intFrame=2:intFrames
					%get current image
					intRealFrame = vecFrames(intFrame);
					if isfield(sETC,'matVid') && ~isempty(sETC.matVid)
						matFrame = sETC.matVid(:,:,:,intRealFrame);
					else
						matFrame = read(sETC.objVid,intRealFrame);
					end
					matFrame = mean(matFrame,3);
					
					%rescale
					if any(all(matFrame<(max(matFrame(:))/10),2))
						matFrame(all(matFrame<(max(matFrame(:))/10),2),:) = median(matFrame(:));
					end
					if any(all(matFrame<(max(matFrame(:))/10),1))
						matFrame(:,all(matFrame<(max(matFrame(:))/10),1)) = median(matFrame(:));
					end
					matEpochFrames(:,:,intFrame) = imnorm(matFrame);
				end
				
				%% run
				vecPrevLocForward = [vecForwardX(1) vecForwardY(1)];
				vecPrevLocReverse = [vecReverseX(end) vecReverseY(end)];
				for intFrame=2:intFrames
					%msg
					if toc(hTic) > 1
						waitbar(intFrame/intFrames,hWaitbar,sprintf('Detecting pupil in frame %d/%d',intFrame,intFrames));
						drawnow;
						hTic = tic;
					end
					
					%% forward detect
					%send frame to gpu
					matForwardFrame = matEpochFrames(:,:,intFrame);
					if sETC.boolUseGPU
						gMatVid = gpuArray(matForwardFrame);
					else
						gMatVid = matForwardFrame;
					end
					
					%detect
					sPupilDetected = getPupil(gMatVid,gMatFilt,dblReflT,dblPupilT,objSE,vecPrevLocForward,vecPupil,sETC.boolUseGPU);
					vecCentroid = sPupilDetected.vecCentroid;
					dblRadius = sPupilDetected.dblRadius;
					vecPrevLocForward = vecCentroid;
					
					%assign
					vecForwardX(intFrame) = vecCentroid(1);
					vecForwardY(intFrame) = vecCentroid(2);
					vecForwardR(intFrame) = dblRadius(1);
					
					%% reverse detect
					%send frame to gpu
					intRevFrame = intFrames-intFrame+1;
					matReverseFrame = matEpochFrames(:,:,intRevFrame);
					if sETC.boolUseGPU
						gMatVid = gpuArray(matReverseFrame);
					else
						gMatVid = matReverseFrame;
					end
					%reverse detect
					sPupilDetected = getPupil(gMatVid,gMatFilt,dblReflT,dblPupilT,objSE,vecPrevLocReverse,vecPupil,sETC.boolUseGPU);
					vecCentroid = sPupilDetected.vecCentroid;
					dblRadius = sPupilDetected.dblRadius;
					vecPrevLocReverse = vecCentroid;
					
					%assign
					vecReverseX(intRevFrame) = vecCentroid(1);
					vecReverseY(intRevFrame) = vecCentroid(2);
					vecReverseR(intRevFrame) = dblRadius(1);
				end
				sEpoch.Blinks = [];
				
				%% assign closest match
				vecInterpX = linspace(sEpoch.BeginLabels.X,sEpoch.EndLabels.X,intFrames);
				vecInterpY = linspace(sEpoch.BeginLabels.Y,sEpoch.EndLabels.Y,intFrames);
				vecFinalX = zeros(1,intFrames);
				vecFinalY = zeros(1,intFrames);
				vecFinalR = zeros(1,intFrames);
				
				vecForwardDist = (vecForwardX - vecInterpX).^2 + (vecForwardY - vecInterpY).^2;
				vecReverseDist = (vecReverseX - vecInterpX).^2 + (vecReverseY - vecInterpY).^2;
				indUseForward = vecForwardDist < vecReverseDist;
				vecFinalX(indUseForward) = vecForwardX(indUseForward);
				vecFinalY(indUseForward) = vecForwardY(indUseForward);
				vecFinalR(indUseForward) = vecForwardR(indUseForward);
				vecFinalX(~indUseForward) = vecReverseX(~indUseForward);
				vecFinalY(~indUseForward) = vecReverseY(~indUseForward);
				vecFinalR(~indUseForward) = vecReverseR(~indUseForward);
				
				sEpoch.CenterX = vecFinalX;
				sEpoch.CenterY = vecFinalY;
				sEpoch.Radius = vecFinalR;
				
				%% done
				delete(hWaitbar);
				uiunlock(sFigETC);
			catch ME
				delete(hWaitbar);
				uiunlock(sFigETC);
				if strcmp(ME.identifier,'MATLAB:waitbar:InvalidSecondInput')
					%cancelled by clicking wait bar; this is not an error
				else
					dispErr(ME);
				end
				%remove temporary epoch
				sFigETC.sEpochTemp = [];
				return;
			end
		end
		
		%remove temporary epoch
		sFigETC.sEpochTemp = [];
		%update epoch list
		sFigETC.sPupil.sEpochs(intSelectEpoch) = sEpoch;
		%reorder
		[dummy,vecReorder] = sort(cell2vec({sFigETC.sPupil.sEpochs.BeginFrame}));
		sFigETC.sPupil.sEpochs = sFigETC.sPupil.sEpochs(vecReorder);
		%update gui epoch list
		cellEpochList = ETC_GenEpochList(sFigETC.ptrEpochList,sFigETC.sPupil.sEpochs,sFigETC.sPupil.vecPupilTime);
		sFigETC.ptrEpochList.Value = numel(cellEpochList);
		%redraw traces
		ETC_redraw();
	else
		%add temporary epoch
		sFigETC.sEpochTemp = sEpoch;
	end
end