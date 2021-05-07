function sFigETOM = ETO_genFastMonitor(sTrPar,dblMaxT,intMaxF)
	
	%check inputs
	if ~exist('dblMaxT','var') || isempty(dblMaxT)
		dblMaxT = sTrPar.dblTotDurSecs;
	end
	if ~exist('intMaxF','var') || isempty(intMaxF)
		intMaxF = sTrPar.intAllFrames;
	end
	
	%set size
	dblHeight = 100;
	dblWidth = 500;
	vecMainColor = [0.97 0.97 0.97];
	%vecLocText = [0.02 0.96 0.4 0.1];
	dblPanelStartX = 0.01;
	dblPanelWidth = 1-dblPanelStartX;
	dblTextHeight = 0.21;
	vecPosGUI = [0,0,dblWidth,dblHeight];
	ptrMainGUI = figure('Visible','on','Units','pixels','Position',vecPosGUI,'Color',vecMainColor,'Name','Eye tracker','resize','off','MenuBar', 'none','ToolBar', 'none');
	ptrMainGUI.Units = 'normalized';
	% Move the window to the center of the screen.
	movegui(ptrMainGUI,'center');
	
	%file name
	vecLocText = [dblPanelStartX 0.75 dblPanelWidth dblTextHeight];
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
	
	
	%compile handles
	sFigETOM = struct;
	sFigETOM.ptrMainGUI = ptrMainGUI;
	
	sFigETOM.dblPanelStartX = dblPanelStartX;
	sFigETOM.dblPanelWidth = dblPanelWidth;
	sFigETOM.vecMainColor = vecMainColor;
	sFigETOM.ptrTextCurT = ptrTextCurT;
	
end