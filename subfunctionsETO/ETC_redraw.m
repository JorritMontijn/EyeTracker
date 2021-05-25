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
	end
	
	%redraw image
	cla(sFigETC.ptrAxesMainVid);
	sFigETC.ptrCurFrame=imshow(matFrame,'Parent', sFigETC.ptrAxesMainVid);
	hold(sFigETC.ptrAxesMainVid,'on');
	
	%extract parameters
	dblMajAx = vecR(sFigETC.intCurFrame);
	dblMinAx = dblMajAx;
	dblOri = 0;
	dblX = vecX(sFigETC.intCurFrame);
	dblY = vecY(sFigETC.intCurFrame);
	
	%orig with overlays
	ellipse(sFigETC.ptrAxesMainVid,dblX,dblY,dblMajAx,dblMinAx,deg2rad(dblOri)-pi/4,'Color','r','LineStyle','--');
	
	%% redraw current x/y/r scatters
	delete(sFigETC.ptrScatterR);
	delete(sFigETC.ptrScatterY);
	delete(sFigETC.ptrScatterX);
	delete(sFigETC.ptrScatterTxtR);
	delete(sFigETC.ptrScatterTxtY);
	delete(sFigETC.ptrScatterTxtX);
	dblT = vecT(sFigETC.intCurFrame);
	dblR = vecR(sFigETC.intCurFrame);
	dblY = vecY(sFigETC.intCurFrame);
	dblX = vecX(sFigETC.intCurFrame);
	
	sFigETC.ptrScatterR = scatter(sFigETC.ptrAxesR,dblT,dblR,48,'kx','LineWidth',2);
	sFigETC.ptrScatterTxtR = text(sFigETC.ptrAxesR,dblT,dblR+range(sFigETC.ptrAxesR.YLim)/7,sprintf('R=%.3f',dblR));
	sFigETC.ptrScatterY = scatter(sFigETC.ptrAxesY,dblT,dblY,48,'bx','LineWidth',2);
	sFigETC.ptrScatterTxtY = text(sFigETC.ptrAxesY,dblT,dblY+range(sFigETC.ptrAxesY.YLim)/7,sprintf('Y=%.3f',dblY));
	sFigETC.ptrScatterX = scatter(sFigETC.ptrAxesX,dblT,dblX,48,'rx','LineWidth',2);
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
	sFigETC.ptrScatterL = scatter(sFigETC.ptrAxesS,dblT,dblS,48,'kx','LineWidth',2);
	sFigETC.ptrScatterTxtL = text(sFigETC.ptrAxesS,dblT,dblS+range(sFigETC.ptrAxesS.YLim)/7,sprintf('L=%.3f',dblS));
	sFigETC.ptrScatterVL = scatter(sFigETC.ptrAxesVL,dblT,dblVL,48,'bx','LineWidth',2);
	sFigETC.ptrScatterTxtVL = text(sFigETC.ptrAxesVL,dblT,dblVL+range(sFigETC.ptrAxesVL.YLim)/7,sprintf('B=%.3f',dblVL));
		
	%% update time
	sFigETC.ptrTextTime.String = sprintf('%.3f',dblT);
		
end