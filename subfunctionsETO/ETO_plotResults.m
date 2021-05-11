function h=ETO_plotResults(sPupil)
	
	
	%txt / edge+conf / sync+not-refl
	%rad / x / y
	
	%% text
	%figure
	h=figure;
	maxfig(h);
	
	%file name
	vecLocText = [0.01 0.9 0.3 0.05];
	ptrText1 = uicontrol(h,'Style','text','HorizontalAlignment','left','FontSize',11,'Units','normalized','Position',vecLocText,...
		'String',sprintf('File: %s',sPupil.strVidFile));
	
	%recording
	if isfield(sPupil.sTrackParams,'strRecordingNI')
		strRec = sPupil.sTrackParams.strRecordingNI;%: 'RecMA7_2021-02-11R01'
	else
		strRec = 'N/A';
	end
	vecLocText2 = [0.01 vecLocText(2)-2*vecLocText(4) 0.3 vecLocText(4)]; 
	ptrText2 = uicontrol(h,'Style','text','HorizontalAlignment','left','FontSize',11,'Units','normalized','Position',vecLocText2,...
		'String',sprintf('Rec: %s',strRec));
	
	%% edge+round / sync+not-refl
	subplot(2,3,2)
	plot(sPupil.vecPupilTime,zscore(sPupil.vecPupilEdgeHardness));
	hold on
	plot(sPupil.vecPupilTime,zscore(sPupil.vecPupilApproxRoundness));
	hold off
	title(sprintf('Blue=edge hardness,red=roundness'),'Interpreter','none');
	xlabel('Time (s)');
	ylabel('Z-scores value');
	fixfig
	
	subplot(2,3,3)
	plot(sPupil.vecPupilTime,zscore(sPupil.vecPupilSyncLum));
	hold on
	plot(sPupil.vecPupilTime,zscore(sPupil.vecPupilNotReflection));
	hold off
	title(sprintf('Blue=sync lum,red=potential area'),'Interpreter','none');
	xlabel('Time (s)');
	ylabel('Z-scored value');
	fixfig
	
	
	
	
	%% rad/x/y
	subplot(2,3,4)
	plot(sPupil.vecPupilTime,sPupil.vecPupilRadius);
	hold on
	plot(sPupil.vecPupilTime,sPupil.vecPupilFixedRadius);
	hold off
	title(sprintf('Pupil radius, raw + fixed'),'Interpreter','none');
	xlabel('Time (s)');
	ylabel('Pupil radius');
	fixfig
	
	subplot(2,3,5)
	plot(sPupil.vecPupilTime,zscore(sPupil.vecPupilCenterX));
	hold on
	plot(sPupil.vecPupilTime,zscore(sPupil.vecPupilFixedCenterX));
	hold off
	title(sprintf('Pupil pos x, raw + fixed'),'Interpreter','none');
	xlabel('Time (s)');
	ylabel('Pupil x-position');
	fixfig
	
	subplot(2,3,6)
	plot(sPupil.vecPupilTime,zscore(sPupil.vecPupilCenterY));
	hold on
	plot(sPupil.vecPupilTime,zscore(sPupil.vecPupilFixedCenterY));
	hold off
	title(sprintf('Pupil pos y, raw + fixed'),'Interpreter','none');
	xlabel('Time (s)');
	ylabel('Pupil y-position');
	fixfig
	drawnow;
	
end