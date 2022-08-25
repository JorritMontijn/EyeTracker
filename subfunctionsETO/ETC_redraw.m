function ETC_redraw(varargin)
	
	%get globals
	global sETC;
	global sFigETC;
	
	%% redraw image
	%get data
	vecT = sFigETC.ptrAxesX.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesX.Children,'UniformOutput',false),'line')).XData;
	vecX = sFigETC.ptrAxesX.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesX.Children,'UniformOutput',false),'line')).YData;
	vecY = sFigETC.ptrAxesY.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesY.Children,'UniformOutput',false),'line')).YData;
	vecR = sFigETC.ptrAxesR.Children(contains(arrayfun(@(x) x.Type,sFigETC.ptrAxesR.Children,'UniformOutput',false),'line')).YData;
	
	%load video frame
	if isfield(sETC,'matVid') && ~isempty(sETC.matVid)
		matFrame = sETC.matVid(:,:,:,sFigETC.intCurFrame);
	else
		matFrame = read(sETC.objVid,sFigETC.intCurFrame);
	end
	if sFigETC.ptrImNorm.Value==1
		matFrame = mean(matFrame,3);
		if any(all(matFrame<(max(matFrame(:))/10),2))
			matFrame(all(matFrame<(max(matFrame(:))/10),2),:) = [];
		end
		if any(all(matFrame<(max(matFrame(:))/10),1))
			matFrame(:,all(matFrame<(max(matFrame(:))/10),1)) = [];
		end
		matFrame = imnorm(matFrame);
		
		[matFrame,imReflection] = ET_ImPrep(matFrame,sETC.gMatFilt,sETC.dblThreshReflect,sETC.objSE,sETC.boolInvertImage);
		matFrame(imReflection) = 0;
	end
	
	%redraw image
	cla(sFigETC.ptrAxesMainVid);
	sFigETC.ptrCurFrame=imshow(matFrame,'Parent', sFigETC.ptrAxesMainVid);
	hold(sFigETC.ptrAxesMainVid,'on');
	
	%extract parameters
	dblR = vecR(sFigETC.intCurFrame);
	dblOri = 0;
	dblX = vecX(sFigETC.intCurFrame);
	dblY = vecY(sFigETC.intCurFrame);
	
	%orig with overlays
	ellipse(sFigETC.ptrAxesMainVid,dblX,dblY,dblR,dblR,deg2rad(dblOri)-pi/4,'Color','r','LineStyle','--');
	
	%draw epoch if overlapping
	indHasLabels = arrayfun(@(x) ~isempty(x.BeginLabels) & ~isempty(x.EndLabels),sFigETC.sPupil.sEpochs);
	indHasOverlap = cell2vec({sFigETC.sPupil.sEpochs.BeginFrame}) <= sFigETC.intCurFrame & cell2vec({sFigETC.sPupil.sEpochs.EndFrame}) >= sFigETC.intCurFrame;
	if ~isempty(indHasLabels)
		indEligible = indHasLabels(:) & indHasOverlap;
		intUseEpoch = find(indEligible,1,'last');
		if ~isempty(intUseEpoch)
			%extract parameters
			sEpoch = sFigETC.sPupil.sEpochs(intUseEpoch);
			intFrameInEpoch = sFigETC.intCurFrame - sEpoch.BeginFrame + 1;
			dblR = sEpoch.Radius(intFrameInEpoch);
			dblOri = 0;
			dblX = sEpoch.CenterX(intFrameInEpoch);
			dblY = sEpoch.CenterY(intFrameInEpoch);
			
			%orig with overlays
			ellipse(sFigETC.ptrAxesMainVid,dblX,dblY,dblR,dblR,deg2rad(dblOri)-pi/4,'Color','b','LineStyle','--');
		end
	end
	%% redraw current x/y/r scatters
	delete(sFigETC.ptrScatterR);
	delete(sFigETC.ptrScatterY);
	delete(sFigETC.ptrScatterX);
	delete(sFigETC.ptrScatterTxtR);
	delete(sFigETC.ptrScatterTxtY);
	delete(sFigETC.ptrScatterTxtX);
	dblT = vecT(sFigETC.intCurFrame);
	
	sFigETC.ptrScatterR = scatter(sFigETC.ptrAxesR,dblT,dblR,48,'k.','LineWidth',2);
	sFigETC.ptrScatterTxtR = text(sFigETC.ptrAxesR,dblT,dblR+range(sFigETC.ptrAxesR.YLim)/7,sprintf('R=%.3f',dblR));
	sFigETC.ptrScatterY = scatter(sFigETC.ptrAxesY,dblT,dblY,48,'b.','LineWidth',2);
	sFigETC.ptrScatterTxtY = text(sFigETC.ptrAxesY,dblT,dblY+range(sFigETC.ptrAxesY.YLim)/7,sprintf('Y=%.3f',dblY));
	sFigETC.ptrScatterX = scatter(sFigETC.ptrAxesX,dblT,dblX,48,'r.','LineWidth',2);
	sFigETC.ptrScatterTxtX = text(sFigETC.ptrAxesX,dblT,dblX+range(sFigETC.ptrAxesX.YLim)/7,sprintf('X=%.3f',dblX));
	drawnow;
	
	%% redraw sync scatters
	delete(sFigETC.ptrScatterL);
	delete(sFigETC.ptrScatterVL);
	delete(sFigETC.ptrScatterTxtL);
	delete(sFigETC.ptrScatterTxtVL);
	dblT = vecT(sFigETC.intCurFrame);
	dblS = sFigETC.sPupil.vecPupilFiltSyncLum(sFigETC.intCurFrame);
	dblVL = sFigETC.sPupil.vecPupilFiltAbsVidLum(sFigETC.intCurFrame);
	sFigETC.ptrScatterL = scatter(sFigETC.ptrAxesS,dblT,dblS,48,'k.','LineWidth',2);
	sFigETC.ptrScatterTxtL = text(sFigETC.ptrAxesS,dblT,dblS+range(sFigETC.ptrAxesS.YLim)/7,sprintf('L=%.3f',dblS));
	sFigETC.ptrScatterVL = scatter(sFigETC.ptrAxesVL,dblT,dblVL,48,'b.','LineWidth',2);
	sFigETC.ptrScatterTxtVL = text(sFigETC.ptrAxesVL,dblT,dblVL+range(sFigETC.ptrAxesVL.YLim)/7,sprintf('B=%.3f',dblVL));
		
	%% update time
	sFigETC.ptrTextTime.String = sprintf('%.3f',dblT);
		
	%% redraw zoom plots
	%get current plot limits
	dblT = vecT(sFigETC.intCurFrame);
	vecLimT = [dblT-5 dblT+5];
	vecFrames = find(vecT > vecLimT(1) & vecT < vecLimT(2));
	vecPlotT = vecT(vecFrames);
	vecPlotX = vecX(vecFrames);
	vecPlotY = vecY(vecFrames);
	vecPlotR = vecR(vecFrames);
	vecPlotS = sFigETC.sPupil.vecPupilFiltSyncLum(vecFrames);
	
	%clear plots and redraw
	fCallback = @ETC_GetCurrentFrame;
	dblMeanX = nanmean(vecX);
	dblMeanY = nanmean(vecY);
	vecPlotX = vecPlotX-dblMeanX;
	vecPlotY = vecPlotY-dblMeanY;
	cla(sFigETC.ptrZoomPlot1);
	cla(sFigETC.ptrZoomPlot2);
	cla(sFigETC.ptrZoomPlot3);
	hLine = plot(sFigETC.ptrZoomPlot1,vecPlotT,vecPlotS);
	set(hLine,'ButtonDownFcn',{fCallback,'Click'});
	hLine = plot(sFigETC.ptrZoomPlot1,[dblT dblT],[min(vecPlotS) max(vecPlotS)],'--','Color',[0.5 0.5 0.5]);
	set(hLine,'ButtonDownFcn',{fCallback,'Click'});
	
	hLine = plot(sFigETC.ptrZoomPlot2,vecPlotT,vecPlotR);
	set(hLine,'ButtonDownFcn',{fCallback,'Click'});
	hLine = plot(sFigETC.ptrZoomPlot2,[dblT dblT],[min(vecPlotR) max(vecPlotR)],'--','Color',[0.5 0.5 0.5]);
	set(hLine,'ButtonDownFcn',{fCallback,'Click'});
	
	hLine = plot(sFigETC.ptrZoomPlot3,vecPlotT,vecPlotX,'color',[0.8 0 0]);
	set(hLine,'ButtonDownFcn',{fCallback,'Click'});
	hLine = plot(sFigETC.ptrZoomPlot3,vecPlotT,vecPlotY,'color',[0 0 0.8]);
	set(hLine,'ButtonDownFcn',{fCallback,'Click'});
	hLine = plot(sFigETC.ptrZoomPlot3,[dblT dblT],[min(cat(1,vecPlotX(:),vecPlotY(:))) max(cat(1,vecPlotX(:),vecPlotY(:)))],'--','Color',[0.5 0.5 0.5]);
	set(hLine,'ButtonDownFcn',{fCallback,'Click'});
	xlim(sFigETC.ptrZoomPlot1,vecLimT);
	xlim(sFigETC.ptrZoomPlot2,vecLimT);
	xlim(sFigETC.ptrZoomPlot3,vecLimT);
	
	%add epochs
	indHasLabels = arrayfun(@(x) ~isempty(x.BeginLabels) & ~isempty(x.EndLabels),sFigETC.sPupil.sEpochs);
	vecB = cell2vec({sFigETC.sPupil.sEpochs.BeginFrame});
	vecE = cell2vec({sFigETC.sPupil.sEpochs.EndFrame});
	intEnd = find(vecT >= vecLimT(2),1);
	if isempty(intEnd)
		intEnd = numel(vecT);
	end
	vecLimF = [find(vecT >= vecLimT(1),1) intEnd];
	if ~isempty(indHasLabels)
		%% corrected epochs
		vecPlotEpochs = find(indHasLabels(:) & (vecB <= vecLimF(2) &  vecE >= vecLimF(1)));
		for intEpochIdx=1:numel(vecPlotEpochs)
			intEpoch = vecPlotEpochs(intEpochIdx);
			
			%extract parameters
			sEpoch = sFigETC.sPupil.sEpochs(intEpoch);
			vecEpochFrames = sEpoch.BeginFrame:sEpoch.EndFrame;
			vecE_T = vecT(vecEpochFrames);
			vecE_X = sEpoch.CenterX - dblMeanX;
			vecE_Y = sEpoch.CenterY - dblMeanY;
			vecE_R = sEpoch.Radius;
			
			%plot
			hLine = plot(sFigETC.ptrZoomPlot2,vecE_T,vecE_R,'color',lines(1),'linewidth',2);
			set(hLine,'ButtonDownFcn',{fCallback,'Click'});
			hLine = plot(sFigETC.ptrZoomPlot3,vecE_T,vecE_X,'color',[1 0 0],'linewidth',2);
			set(hLine,'ButtonDownFcn',{fCallback,'Click'});
			hLine = plot(sFigETC.ptrZoomPlot3,vecE_T,vecE_Y,'color',[0 0 1],'linewidth',2);
			set(hLine,'ButtonDownFcn',{fCallback,'Click'});
		end
		%% blink epochs
		vecBlinkEpochs = find(~indHasLabels(:) & (vecB <= vecLimF(2) &  vecE >= vecLimF(1)));
		for intEpochIdx=1:numel(vecBlinkEpochs)
			intEpoch = vecBlinkEpochs(intEpochIdx);
			
			%extract parameters
			sEpoch = sFigETC.sPupil.sEpochs(intEpoch);
			vecEpochFramesBE = [sEpoch.BeginFrame sEpoch.EndFrame];
			vecE_T = vecT(vecEpochFramesBE);
			boolIsRemoveEpoch = all(sEpoch.Blinks==0);
			if boolIsRemoveEpoch
				vecColor = [0.5 0.5 0.5];
			else
				vecColor = [0 0 0];
			end
			%plot
			hLine = plot(sFigETC.ptrZoomPlot1,vecE_T,max(get(sFigETC.ptrZoomPlot1,'ylim'))*[1 1],'color',vecColor,'linewidth',3);
			set(hLine,'ButtonDownFcn',{fCallback,'Click'});
			hLine = plot(sFigETC.ptrZoomPlot2,vecE_T,max(get(sFigETC.ptrZoomPlot2,'ylim'))*[1 1],'color',vecColor,'linewidth',3);
			set(hLine,'ButtonDownFcn',{fCallback,'Click'});
			hLine = plot(sFigETC.ptrZoomPlot3,vecE_T,max(get(sFigETC.ptrZoomPlot3,'ylim'))*[1 1],'color',vecColor,'linewidth',3);
			set(hLine,'ButtonDownFcn',{fCallback,'Click'});
		end
		
	end
	
	%% add blinks saved to vector
	%assert presence
	if ~isfield(sFigETC.sPupil,'vecPupilFixedBlinks') || isempty(sFigETC.sPupil.vecPupilFixedBlinks)
		sFigETC.sPupil.vecPupilFixedBlinks = false(size(vecT));
	end
	
	vecUseBlinkF = find(sFigETC.sPupil.vecPupilFixedBlinks(vecLimF(1):vecLimF(2)));
	if ~isempty(vecUseBlinkF)
		vecBlinkF = sort(vecUseBlinkF+vecFrames(1)-1,'ascend');
		vecBlinkB = 1+[0 find(diff(vecBlinkF)>1)];
		vecBlinkE = [find(diff(vecBlinkF)>1) numel(vecBlinkF)];
		for intBlinkIdx=1:numel(vecBlinkB)
			vecE_T = vecT(vecBlinkF([vecBlinkB(intBlinkIdx) vecBlinkE(intBlinkIdx)]));
			
			%plot
			hLine = plot(sFigETC.ptrZoomPlot1,vecE_T,max(get(sFigETC.ptrZoomPlot1,'ylim'))*[1 1],'color','k','linewidth',3);
			set(hLine,'ButtonDownFcn',{fCallback,'Click'});
			hLine = plot(sFigETC.ptrZoomPlot2,vecE_T,max(get(sFigETC.ptrZoomPlot2,'ylim'))*[1 1],'color','k','linewidth',3);
			set(hLine,'ButtonDownFcn',{fCallback,'Click'});
			hLine = plot(sFigETC.ptrZoomPlot3,vecE_T,max(get(sFigETC.ptrZoomPlot3,'ylim'))*[1 1],'color','k','linewidth',3);
			set(hLine,'ButtonDownFcn',{fCallback,'Click'});
		end
	end
	drawnow;
end