function ETO_updateMonitor(sFigETOM,sPupil,sPupil1,dblT,dblTotDurSecs)
	
	%update time
	sFigETOM.ptrTextCurT.String = sprintf('Now at: t=%.3f s / %.3f s',dblT,dblTotDurSecs);
	
	%axes 1
	scatter(sFigETOM.ptrAxesPlot1,dblT,sPupil.dblEdgeHardness,[],[1 0 0],'.');
	scatter(sFigETOM.ptrAxesPlot1,dblT,sPupil.dblSyncLum,[],[0 0 1],'.');
		
	%axes 2
	scatter(sFigETOM.ptrAxesPlot2,dblT,sPupil.dblMeanPupilLum/255,[],[1 0 0],'.');
	scatter(sFigETOM.ptrAxesPlot2,dblT,sPupil.dblApproxConfidence,[],[0 0 1],'.');
	
	%axes 3
	scatter(sFigETOM.ptrAxesPlot3,dblT,sPupil.vecCentroid(1)-sPupil1.vecCentroid(1),[],[1 0 0],'.');
	scatter(sFigETOM.ptrAxesPlot3,dblT,sPupil.dblRadius-sPupil1.dblRadius,[],[0 0 1],'.');
	scatter(sFigETOM.ptrAxesPlot3,dblT,sPupil.vecCentroid(2)-sPupil1.vecCentroid(2),[],[0 1 0],'.');
	drawnow;
end