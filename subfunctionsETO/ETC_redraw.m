function ETC_redraw()
	
	%get globals
	global sETC;
	global sFigETC;
	
	%% redraw image
	%load video frame
	matFrame = read(sETC.objVid,sFigETC.intCurFrame);
	
	%redraw image
	cla(sFigETC.ptrAxesMainVid);
	sFigETC.ptrCurFrame=imshow(matFrame,'Parent', sFigETC.ptrAxesMainVid);
	hold(sFigETC.ptrAxesMainVid,'on');
	
	%extract parameters
	sPupil = sFigETC.sPupil;
	
	dblMajAx = sPupil.vecPupilFixedRadius(sFigETC.intCurFrame);
	dblMinAx = dblMajAx;
	dblOri = 0;
	dblX = sPupil.vecPupilFixedCenterX(sFigETC.intCurFrame);
	dblY = sPupil.vecPupilFixedCenterY(sFigETC.intCurFrame);
	
	%orig with overlays
	ellipse(sFigETC.ptrAxesMainVid,dblX,dblY,dblMajAx,dblMinAx,deg2rad(dblOri)-pi/4,'Color','r','LineStyle','--');
	
	%% redraw current x/y/r scatters
	delete(sFigETC.ptrScatterR);
	delete(sFigETC.ptrScatterY);
	delete(sFigETC.ptrScatterX);
	delete(sFigETC.ptrScatterTxtR);
	delete(sFigETC.ptrScatterTxtY);
	delete(sFigETC.ptrScatterTxtX);
	dblT = sFigETC.sPupil.vecPupilTime(sFigETC.intCurFrame);
	dblR = sFigETC.sPupil.vecPupilFixedRadius(sFigETC.intCurFrame);
	dblY = sFigETC.sPupil.vecPupilFixedCenterY(sFigETC.intCurFrame);
	dblX = sFigETC.sPupil.vecPupilFixedCenterX(sFigETC.intCurFrame);
	
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
	dblT = sFigETC.sPupil.vecPupilTime(sFigETC.intCurFrame);
	dblS = sFigETC.sPupil.vecPupilFiltSyncLum(sFigETC.intCurFrame);
	dblVL = sFigETC.sPupil.vecPupilFiltAbsVidLum(sFigETC.intCurFrame);
	sFigETC.ptrScatterL = scatter(sFigETC.ptrAxesS,dblT,dblS,48,'kx','LineWidth',2);
	sFigETC.ptrScatterTxtL = text(sFigETC.ptrAxesS,dblT,dblS+range(sFigETC.ptrAxesS.YLim)/7,sprintf('L=%.3f',dblS));
	sFigETC.ptrScatterVL = scatter(sFigETC.ptrAxesVL,dblT,dblVL,48,'bx','LineWidth',2);
	sFigETC.ptrScatterTxtVL = text(sFigETC.ptrAxesVL,dblT,dblVL+range(sFigETC.ptrAxesVL.YLim)/7,sprintf('B=%.3f',dblVL));
		
end