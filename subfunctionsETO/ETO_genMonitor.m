function sFigETOM = ETO_genMonitor(sTrPar,dblMaxT,intMaxF)
	
	%check inputs
	if ~exist('dblMaxT','var') || isempty(dblMaxT)
		dblMaxT = sTrPar.dblTotDurSecs;
	end
	if ~exist('intMaxF','var') || isempty(intMaxF)
		intMaxF = sTrPar.intAllFrames;
	end
	
	%set size
	dblHeight = 600;
	dblWidth = 1000;
	vecMainColor = [0.97 0.97 0.97];
	%vecLocText = [0.02 0.96 0.4 0.1];
	dblPanelStartX = 0.01;
	dblAxesStartX = 0.04;
	dblPanelWidth = 0.44-dblAxesStartX;
	dblAxesWidth = dblPanelWidth-dblAxesStartX;
	dblTextHeight = 0.035;
	vecPosGUI = [0,0,dblWidth,dblHeight];
	ptrMainGUI = figure('Visible','on','Units','pixels','Position',vecPosGUI,'Color',vecMainColor);
	ptrMainGUI.Units = 'normalized';
	% Move the window to the center of the screen.
	movegui(ptrMainGUI,'center');
	
	% left
	%locations
	vecStartY = [0.95 0.6 0.33 0.06];
	vecHeight = [0.2 0.2 0.2 0.2];
	
	%text data
					
	%file name
	vecLocText = [dblPanelStartX vecStartY(1) dblPanelWidth dblTextHeight];
	ptrTextRoot = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Units','normalized','Position',vecLocText,...
		'String',sprintf('File: %s',sTrPar.strVidFile));
	
	%recording
	if isfield(sTrPar,'strRecordingNI')
		strRec = sTrPar.strRecordingNI;%: 'RecMA7_2021-02-11R01'
	else
		strRec = 'N/A';
	end
	vecLocText2 = vecLocText - [0 vecLocText(4) 0 0];
	ptrTextRec = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Units','normalized','Position',vecLocText2,...
		'String',sprintf('Rec: %s',strRec));
	
	vecLocText3 = vecLocText2 - [0 vecLocText2(4) 0 0];
	ptrTextStart = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Units','normalized','Position',vecLocText3,...
		'String',sprintf('Started at %s, %s',getTime,getDate));
	
	vecLocText4 = vecLocText3 - [0 vecLocText3(4) 0 0];
	ptrTextCurT = uicontrol(ptrMainGUI,'Style','text','HorizontalAlignment','left','FontSize',11,'BackgroundColor',vecMainColor,'Units','normalized','Position',vecLocText4,...
		'String',sprintf('Now at: t=%.1f s / %.1f s',0,dblMaxT));
	
	%axes 1
	vecLocAxesPlot1 = [dblAxesStartX vecStartY(2) dblAxesWidth vecHeight(2)];
	ptrAxesPlot1 = axes(ptrMainGUI,'Position',vecLocAxesPlot1,'Units','normalized');
	title(ptrAxesPlot1,'R=Edge hardness, B=Sync Lum');
	ylabel(ptrAxesPlot1,'Value');
	xlim(ptrAxesPlot1,[0 dblMaxT]);
	ylim(ptrAxesPlot1,[0 1.1]);
	grid(ptrAxesPlot1,'on');
	hold(ptrAxesPlot1,'on');
			
	%axes 2
	vecLocAxesPlot2 = [dblAxesStartX vecStartY(3) dblAxesWidth vecHeight(3)];
	ptrAxesPlot2 = axes(ptrMainGUI,'Position',vecLocAxesPlot2,'Units','normalized');
	title(ptrAxesPlot2,'R=Pupil Lum, B = Conf');
	ylabel(ptrAxesPlot2,'Value');
	xlim(ptrAxesPlot2,[0 dblMaxT]);
	ylim(ptrAxesPlot2,[0 1]);
	grid(ptrAxesPlot2,'on');
	hold(ptrAxesPlot2,'on');
	
	%axes 3
	vecLocAxesPlot3 = [dblAxesStartX vecStartY(4) dblAxesWidth vecHeight(4)];
	ptrAxesPlot3 = axes(ptrMainGUI,'Position',vecLocAxesPlot3,'Units','normalized');
	title(ptrAxesPlot3,'R=x, G=y, B=Radius');
	xlabel(ptrAxesPlot3,'Time (s)');
	ylabel(ptrAxesPlot3,'Pixels');
	xlim(ptrAxesPlot3,[0 dblMaxT]);
	ylim(ptrAxesPlot3,[-20 20]);
	grid(ptrAxesPlot3,'on');
	hold(ptrAxesPlot3,'on');
	
	%% video
	%main
	dblVidStartX = dblPanelStartX*2+dblPanelWidth;
	dblVidWidth = 1-dblVidStartX;
	vecLocVid = [dblVidStartX 0.4 dblVidWidth 0.6];
	ptrAxesMainVid = axes(ptrMainGUI,'Position',vecLocVid,'Units','normalized');
	axis(ptrAxesMainVid,'off');
	
	%sub1
	vecLocVid1 = [dblVidStartX 0 dblVidWidth/2 vecLocVid(2)];
	ptrAxesSubVid1 = axes(ptrMainGUI,'Position',vecLocVid1,'Units','normalized');
	axis(ptrAxesSubVid1,'off');
					
	%sub2
	vecLocVid2 = [vecLocVid1(1)+vecLocVid1(3) 0 1-(vecLocVid1(1)+vecLocVid1(3)) vecLocVid(2)];
	ptrAxesSubVid2 = axes(ptrMainGUI,'Position',vecLocVid2,'Units','normalized');
	axis(ptrAxesSubVid2,'off');
	
	
	%compile handles
	sFigETOM = struct;
	sFigETOM.ptrMainGUI = ptrMainGUI;
	sFigETOM.ptrAxesMainVid = ptrAxesMainVid;
	sFigETOM.ptrAxesSubVid1 = ptrAxesSubVid1;
	sFigETOM.ptrAxesSubVid2 = ptrAxesSubVid2;
	
	sFigETOM.dblPanelStartX = dblPanelStartX;
	sFigETOM.dblPanelWidth = dblPanelWidth;
	sFigETOM.vecMainColor = vecMainColor;
	sFigETOM.ptrTextCurT = ptrTextCurT;
	sFigETOM.ptrAxesPlot1 = ptrAxesPlot1;
	sFigETOM.ptrAxesPlot2 = ptrAxesPlot2;
	sFigETOM.ptrAxesPlot3 = ptrAxesPlot3;
	
end