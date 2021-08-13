function ETC_AddPupilEpoch(hObject,eventdata,strType)
	%globals
	global sFigETC;
	global sETC;
	
	%get temporary epoch
	sEpoch = sFigETC.sEpochTemp;
	
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
		if intSwitchDetectOrInterpolate == 1 || ~isfield(sFigETC.sPupil,'sTrackParams')
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
				
				%% read values at starting frame
				%load video frame
				if isfield(sETC,'matVid') && ~isempty(sETC.matVid)
					matFrame = sETC.matVid(:,:,:,vecFrames(1));
				else
					matFrame = read(sETC.objVid,vecFrames(1));
				end
				matFrame = mean(matFrame,3);
				%rescale
				if any(all(matFrame<(max(matFrame(:))/10),2))
					matFrame(all(matFrame<(max(matFrame(:))/10),2),:) = [];
				end
				if any(all(matFrame<(max(matFrame(:))/10),1))
					matFrame(:,all(matFrame<(max(matFrame(:))/10),1)) = [];
				end
				matFrame = imnorm(matFrame)*255;
				
				%retrieve median pupil luminance
				[matX,matY] = meshgrid(1:size(matFrame,2),1:size(matFrame,1));
				[dummy,vecDist] = cart2pol(matY-sEpoch.BeginLabels.Y,matX-sEpoch.BeginLabels.X);
				indInner = vecDist < sEpoch.BeginLabels.R;
				dblOldPupilT = sTrPar.dblThreshPupil;
				dblPupilT = median(matFrame(indInner));
				vecPupil = (vecPupil - dblOldPupilT) + dblPupilT;
				
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
				
				%% detect
				%pre-allocate
				vecPrevLoc = [sEpoch.BeginLabels.X sEpoch.BeginLabels.Y];
				sEpoch.CenterX = zeros(1,intFrames);
				sEpoch.CenterY = zeros(1,intFrames);
				sEpoch.Radius = zeros(1,intFrames);
				%assign first frame
				sEpoch.CenterX(1) = sEpoch.BeginLabels.X;
				sEpoch.CenterY(1) = sEpoch.BeginLabels.Y;
				sEpoch.Radius(1) = sEpoch.BeginLabels.R;
				
				%run
				for intFrame=2:intFrames
					%msg
					if toc(hTic) > 1
						waitbar(intFrame/intFrames,hWaitbar,sprintf('Detecting pupil in frame %d/%d',intFrame,intFrames));
						drawnow;
						hTic = tic;
					end
					%get current image
					intRealFrame = vecFrames(intFrame);
					%load video frame
					if isfield(sETC,'matVid') && ~isempty(sETC.matVid)
						matFrame = sETC.matVid(:,:,:,intRealFrame);
					else
						matFrame = read(sETC.objVid,intRealFrame);
					end
					matFrame = mean(matFrame,3);
					
					%rescale
					if any(all(matFrame<(max(matFrame(:))/10),2))
						matFrame(all(matFrame<(max(matFrame(:))/10),2),:) = [];
					end
					if any(all(matFrame<(max(matFrame(:))/10),1))
						matFrame(:,all(matFrame<(max(matFrame(:))/10),1)) = [];
					end
					matFrame = imnorm(matFrame);
					
					%send frame to gpu
					if sETC.boolUseGPU
						gMatVid = gpuArray(matFrame);
					else
						gMatVid = matFrame;
					end
					
					%detect
					sPupilDetected = getPupil(gMatVid,gMatFilt,dblReflT,dblPupilT,objSE,vecPrevLoc,vecPupil,sETC.boolUseGPU);
					vecCentroid = sPupilDetected.vecCentroid;
					dblRadius = sPupilDetected.dblRadius;
					vecPrevLoc = vecCentroid;
					
					%assign
					sEpoch.CenterX(intFrame) = vecCentroid(1);
					sEpoch.CenterY(intFrame) = vecCentroid(2);
					sEpoch.Radius(intFrame) = dblRadius(1);
				end
				sEpoch.Blinks = [];
				delete(hWaitbar);
				uiunlock(sFigETC);
			catch ME
				delete(hWaitbar);
				uiunlock(sFigETC);
				dispErr(ME);
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