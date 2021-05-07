function ETO_redraw(sFigETOM,sIms,sPupil,matVid)
	
	%% redraw image, boxes & detection
	%redraw image
	if nargin > 3
		cla(sFigETOM.ptrAxesMainVid);
		sFigETOM.ptrCurFrame=imshow(matVid,'Parent', sFigETOM.ptrAxesMainVid);
		hold(sFigETOM.ptrAxesMainVid,'on');
	end
	
	%closed
	cla(sFigETOM.ptrAxesSubVid1);
	imshow(sIms.imGrey/255,'Parent', sFigETOM.ptrAxesSubVid1);
	hold(sFigETOM.ptrAxesSubVid1,'on');
	ellipse(sFigETOM.ptrAxesSubVid1,sPupil.vecCentroid(1),sPupil.vecCentroid(2),sPupil.dblRadius,sPupil.dblRadius,deg2rad(0)-pi/4,'Color','r','LineStyle','--');
	hold(sFigETOM.ptrAxesSubVid1,'off');
	title(sFigETOM.ptrAxesSubVid1,sprintf('Edge hardness: %.3f',sPupil.dblEdgeHardness));
	
	%regions
	cla(sFigETOM.ptrAxesSubVid2);
	matRGB = cat(3,double(sIms.imReflection),double(sIms.imPupil),double(sIms.imBW));
	imshow(matRGB,'Parent', sFigETOM.ptrAxesSubVid2);
	title(sFigETOM.ptrAxesSubVid2,sprintf('BW roundness: %.3f',sPupil.dblApproxRoundness));
	
end