function OT_redraw(varargin)
	%DC_redraw Sets and redraws windows
	%   DC_redraw([redrawImage=true])
	
	%get structures
	global sOT;
	global sFig;
	
	%check whether to plot in new figure
	intNewFigure = get(sFig.ptrButtonNewFig,'Value');
	
	%check if data has been loaded
	if isempty(sOT) || isempty(sFig)
		return;
	else
		try
			%get current image
			intImSelected = get(sFig.ptrListSelectMetric,'Value');
		catch %#ok<CTCH>
			return;
		end
	end
	
	% Draw the image if requested
	if intNewFigure == 0
		%check if figure is still there
		try
			ptrOldFig = get(sFig.ptrWindowHandle);
		catch %#ok<CTCH>
			ptrOldFig = [];
		end
		
		%make new figure
		if isempty(ptrOldFig)
			%close figure if old one still present
			if ~isempty(ptrOldFig)
				close(sFig.ptrWindowHandle);
			end
			
			% create figure
			sFig.ptrWindowHandle = figure;
			sFig.ptrAxesHandle = axes;
		else
			%set active figure
			%figure(sFig.ptrWindowHandle);
		end
	else
		% create figure
		sFig.ptrWindowHandle = figure;
		sFig.ptrAxesHandle = axes;
	end
	
	%% get requested parameters
	%check whether to plot in new figure
	intScatterPlot = get(sFig.ptrButtonScatterYes,'Value');
	intProcessType = get(sFig.ptrListSelectDataProcessing,'Value');
	cellProcessTypes = get(sFig.ptrListSelectDataProcessing,'String');
	strProcessType = cellProcessTypes{intProcessType};
	intMetric = get(sFig.ptrListSelectMetric,'Value');
	cellMetrics = get(sFig.ptrListSelectMetric,'String');
	strMetric = cellMetrics{intMetric};
	intChannel = get(sFig.ptrListSelectChannel,'Value');
	cellChannels = get(sFig.ptrListSelectChannel,'String');
	strChannel = cellChannels{intChannel};
	
	%% prep data
	intTrials = min([sOT.intEphysTrial sOT.intStimTrial]);
	
	%get stimulus parameters
	vecOriDegs = cell2mat({sOT.sStimObject(1:intTrials).Orientation});
	[vecStimTypes,vecUnique,vecCounts,cellSelect,vecRepetition] = label2idx(vecOriDegs);
	
	%get data from globals
	matRespBase = sOT.matRespBase; %[1 by S] cell with [chan x rep] matrix
	matRespStim = sOT.matRespStim; %[1 by S] cell with [chan x rep] matrix
	vecStimTypes = sOT.vecStimTypes; %[1 by S] cell with [chan x rep] matrix
	vecStimOriDeg = sOT.vecStimOriDeg; %[1 by S] cell with [chan x rep] matrix
	intNumStimTypes = numel(vecUnique);
	
	%% plot OT estimate
	matRelResp = matRespStim-matRespBase;
	matRelRespZ = zscore(matRelResp,[],2);
	
	%remove outliers
	matRelResp(abs(matRelRespZ)>3) = nan;
	
	%% select matrix to use
	if intProcessType == 1 %stim
		matUseResp = matRespStim;
	elseif intProcessType == 2 %base
		matUseResp = matRespBase;
	elseif intProcessType == 3 %stim - base
		matUseResp = matRelResp;
	end
	matUseResp = matUseResp(:,1:intTrials);
	
	%% get directionality data
	%get quadrant inclusion lists
	vecHorizontal = deg2rad([0 180]);
	vecVertical = deg2rad([90 270]);
	vecDistLeft = circ_dist(deg2rad(vecOriDegs),vecHorizontal(1));
	vecDistRight = circ_dist(deg2rad(vecOriDegs),vecHorizontal(2));
	vecDistUp = circ_dist(deg2rad(vecOriDegs),vecVertical(1));
	vecDistDown = circ_dist(deg2rad(vecOriDegs),vecVertical(2));
	indIncludeLeft = abs(vecDistLeft) < deg2rad(10);
	indIncludeRight= abs(vecDistRight) < deg2rad(10);
	indIncludeUp= abs(vecDistUp) < deg2rad(10);
	indIncludeDown= abs(vecDistDown) < deg2rad(10);
	%get data
	vecRespLeft = nanmean(matUseResp(:,indIncludeLeft),2);
	vecRespRight = nanmean(matUseResp(:,indIncludeRight),2);
	vecRespUp = nanmean(matUseResp(:,indIncludeUp),2);
	vecRespDown = nanmean(matUseResp(:,indIncludeDown),2);
	vecLRIndex = (vecRespLeft - vecRespRight) ./ (vecRespLeft + vecRespRight);
	vecUDIndex = (vecRespUp - vecRespDown) ./ (vecRespUp + vecRespDown);
	vecVHIndex = ((vecRespLeft + vecRespRight) - (vecRespUp + vecRespDown)) ./ ((vecRespLeft + vecRespRight) + (vecRespUp + vecRespDown));
	
	%% get metrics
	try
		vecDeltaPrime = getDeltaPrime(matUseResp,deg2rad(vecStimOriDeg),true);
		vecRho_bc = zeros(size(vecDeltaPrime));%getTuningRho(matUseResp,deg2rad(vecStimOriDeg));
		vecOPI = getOPI(matUseResp,deg2rad(vecStimOriDeg));
		vecOSI = getOSI(matUseResp,deg2rad(vecStimOriDeg));
	catch
		vecDeltaPrime = nan;
		vecRho_bc = nan;
		vecOPI = nan;
		vecOSI = nan;
	end
	
	%% select metric
	if intMetric == 1
		vecTuningValue = vecDeltaPrime;
	elseif intMetric == 2
		vecTuningValue = vecRho_bc;
	elseif intMetric == 3
		vecTuningValue = vecOPI;
	elseif intMetric == 4
		vecTuningValue = vecOSI;
	elseif intMetric == 5
		vecTuningValue = vecLRIndex;
	elseif intMetric == 6
		vecTuningValue = vecUDIndex;
	elseif intMetric == 7
		vecTuningValue = vecVHIndex;
	end
	
	%% get plotting data
	%select channel
	if strcmp(strChannel,'Best')
		[dummy,intChNr] = max(vecTuningValue);
		vecUseResp = matUseResp(intChNr,:);
		strChannel = strcat(strChannel,sprintf('=%d',intChNr));
	elseif strcmp(strChannel,'Mean')
		intChNr = 0;
		vecUseResp = mean(matUseResp,1);
	elseif strcmp(strChannel(1:2),'Ch')
		intChNr = str2double(getFlankedBy(strChannel,'Ch-',''));
		vecUseResp = matUseResp(intChNr,:);
	else
		OT_updateTextInformation({sprintf('Channel "%s" not recognized',strChannel)});
		return;
	end
	%add tuning metrics to title
	if intChNr > 0
		strTitle = strcat(strChannel,sprintf('; %s''=%.3f; %s=%.3f; OPI=%.3f; OSI=%.3f; LR=%.3f; UD=%.3f; VH=%.3f',...
			getGreek(4,'lower'),vecDeltaPrime(intChNr),getGreek(17,'lower'),vecRho_bc(intChNr),...
			vecOPI(intChNr),vecOSI(intChNr),vecLRIndex(intChNr),vecUDIndex(intChNr),vecVHIndex(intChNr)));
	else
		strTitle = ' Mean';
	end
	
	%% plot 
	vecPlotRespMean = nan(1,intNumStimTypes);
	vecPlotRespErr = nan(1,intNumStimTypes);
	for intStimType=1:intNumStimTypes
		vecTheseResps = vecUseResp(vecStimTypes==intStimType);
		vecPlotRespMean(intStimType) = nanmean(vecTheseResps);
		vecPlotRespErr(intStimType) = nanstd(vecTheseResps)./sqrt(sum(~isnan(vecTheseResps)));
	end
	cla(sFig.ptrAxesHandle);
	if intScatterPlot == 1
		scatter(sFig.ptrAxesHandle,vecOriDegs,vecUseResp,'kx');
	end
	hold(sFig.ptrAxesHandle,'on');
	errorbar(sFig.ptrAxesHandle,vecUnique,vecPlotRespMean,vecPlotRespErr);
	hold(sFig.ptrAxesHandle,'off');
	
	%clean up figure
	ylabel(sFig.ptrAxesHandle,'MUA (a.u.)');
	xlabel(sFig.ptrAxesHandle,'Stimulus Orientation (deg)');
	fixfig(sFig.ptrAxesHandle,false);
	title(sFig.ptrAxesHandle,strTitle,'FontSize',10);
	
	drawnow;
end