function ETP_redraw()
	
	%get globals
	global sETP;
	global sFigETP;
	
	%% redraw image, boxes & detection
	%redraw image
	cla(sFigETP.ptrAxesMainVid);
	sFigETP.ptrCurFrame=imshow(sFigETP.matMain,'Parent', sFigETP.ptrAxesMainVid);
	hold(sFigETP.ptrAxesMainVid,'on');
	
	%redraw boxes
	vecRectSyncPix = [sETP.vecRectSync(1)*sETP.intX sETP.vecRectSync(2)*sETP.intY sETP.vecRectSync(3)*sETP.intX sETP.vecRectSync(4)*sETP.intY];
	vecRectROIPix = [sETP.vecRectROI(1)*sETP.intX sETP.vecRectROI(2)*sETP.intY sETP.vecRectROI(3)*sETP.intX sETP.vecRectROI(4)*sETP.intY];
	sFigETP.hSyncBox = plotRect(sFigETP.ptrAxesMainVid,vecRectSyncPix,'c--');
	sFigETP.hROIBox = plotRect(sFigETP.ptrAxesMainVid,vecRectROIPix,'b--');
	
	%extract parameters
	sPupil = sFigETP.sPupil;
	
	vecCentroid = sPupil.vecCentroid;
	dblMajAx = sPupil.dblRadius;
	dblMinAx = dblMajAx;
	dblOri = 0;
	
	%orig with overlays
	dblX = vecCentroid(1) + vecRectROIPix(1);
	dblY = vecCentroid(2) + vecRectROIPix(2);
	ellipse(sFigETP.ptrAxesMainVid,dblX,dblY,dblMajAx,dblMinAx,deg2rad(dblOri)-pi/4,'Color','r','LineStyle',':');
	
	%closed
	cla(sFigETP.ptrAxesSubVid1);
	imshow(sFigETP.imGrey/single(intmax(class(sETP.matFrames))),'Parent', sFigETP.ptrAxesSubVid1);
	hold(sFigETP.ptrAxesSubVid1,'on');
	ellipse(sFigETP.ptrAxesSubVid1,vecCentroid(1),vecCentroid(2),dblMajAx,dblMinAx,deg2rad(dblOri)-pi/4,'Color','r','LineStyle',':');
	hold(sFigETP.ptrAxesSubVid1,'off');
	title(sFigETP.ptrAxesSubVid1,sprintf('Edge hardness: %.3f',sFigETP.sPupil.dblEdgeHardness));
	
	%regions
	matRGB = cat(3,double(sFigETP.imReflection),double(sFigETP.imPupil),double(sFigETP.imBW));
	imshow(matRGB,'Parent', sFigETP.ptrAxesSubVid2);
	title(sFigETP.ptrAxesSubVid2,sprintf('BW roundness: %.3f',sFigETP.sPupil.dblApproxRoundness));
	
end