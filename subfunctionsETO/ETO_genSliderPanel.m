function [ptrPanelParent,ptrSlider,ptrPanelTitle,sPointers] = ETO_genSliderPanel(ptrMasterFigure,vecLocation,sFiles)
	
	%error 'add description of entries (vertical?), add tracking parameter button+gui, and add "run all" button'
	
	%% set constants
	%unpack location vector
	dblTitleHeight = 0.15;
	dblTitleY = vecLocation(2)+vecLocation(4)-dblTitleHeight;
	dblPanelX = vecLocation(1);
	dblPanelY = vecLocation(2);
	dblPanelWidth = vecLocation(3);
	dblPanelHeight = vecLocation(4)-dblTitleHeight;
	dblStartVal = 1;
	
	%size contants
	intHorzYN = 12;
	intHorzCheck = 15;
	intHorzName = 330;
	intHorzDate = 80;
	intHorzBytes = 60;
	
	%calculate the total size of the subpanel content
	intFiles = numel(sFiles);
	ptrMasterFigure.Units = 'pixels';
	vecMasterSize = ptrMasterFigure.Position;
	ptrMasterFigure.Units = 'normalized';
	dblTotSize = (intFiles+1)*30;
	dblRelSize = (dblTotSize/(vecMasterSize(end)*dblPanelHeight))+dblPanelHeight;
	
	%% make title panel
	ptrPanelTitle = uipanel('Parent',ptrMasterFigure);
	set(ptrPanelTitle,'Position',[dblPanelX dblTitleY dblPanelWidth dblTitleHeight]);
	ptrCrapHack = axes(ptrPanelTitle,'Color','none','Position',[0 0 1 1],'Clipping','off');
	axis off;
	
	%output
	dblY = 0.1;
	dblW = vecMasterSize(3)*dblPanelWidth*0.9;
	vecLoc = [0.01 0 intHorzYN/dblW];
	dblAngle = 80;
	text(ptrCrapHack,vecLoc(1),dblY,'Tracked?','Rotation',dblAngle,'FontSize',9);
	%checkbox: run?
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzCheck/dblW];
	text(ptrCrapHack,vecLoc(1),dblY,'Run?','Rotation',dblAngle,'FontSize',9);
	%params
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	text(ptrCrapHack,vecLoc(1),dblY,'Params?','Rotation',dblAngle,'FontSize',9);
	%sync
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	text(ptrCrapHack,vecLoc(1),dblY,'Sync?','Rotation',dblAngle,'FontSize',9);
	%online preset
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzYN/dblW];
	text(ptrCrapHack,vecLoc(1),dblY,'Presets?','Rotation',dblAngle,'FontSize',9);
	%name
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzName/dblW];
	text(ptrCrapHack,vecLoc(1),0.2,'File name','FontSize',12);
	%date
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzDate/dblW];
	text(ptrCrapHack,vecLoc(1)*0.915,0.2,'Date','FontSize',12);
	%size
	vecLoc = [vecLoc(1)+vecLoc(3) 0 intHorzBytes/dblW];
	text(ptrCrapHack,vecLoc(1)*0.918,0.2,'File size','FontSize',12);
	
	
	%% create the subpanels
	ptrPanelParent = uipanel('Parent',ptrMasterFigure);
	set(ptrPanelParent,'Position',[dblPanelX dblPanelY dblPanelWidth dblPanelHeight]);
	ptrPanelChild = uipanel('Parent',ptrPanelParent);
	set(ptrPanelChild,'Position',[0 0 1 dblRelSize]);
	ptrSlider = uicontrol('Style','Slider','Parent',ptrMasterFigure,...
		'Units','normalized','Position',[0.94 dblPanelY 0.05 dblPanelHeight],...
		'Value',dblStartVal,'Callback',{@ETO_SliderCallback,ptrPanelChild});
	
	
	%% add all variables
	sPointers = [];
	for intFile=1:intFiles
		%sFiles.sPupil %output
		if isfield(sFiles(intFile),'sPupil') && ~isempty(sFiles(intFile).sPupil)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = sFiles(intFile).sPupil.name;
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'Not yet pupil-tracked';
		end
		vecLoc = [1 (intFiles*30)-((intFile-1)*30) intHorzYN 25];
		sPointers(intFile).Tracked = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,'Tooltip',strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%checkbox: run?
		strTip = 'Select to run tracking';
		vecLoc = [dblLastX+1 4+(intFiles*30)-((intFile-1)*30) intHorzCheck 25];
		sPointers(intFile).CheckRun = uicontrol(ptrPanelChild,'style','checkbox',...
			'Position',vecLoc,'String','','Tooltip',strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles.sTrackParams %offline tracking parameters;
		if isfield(sFiles(intFile),'sTrackParams') && ~isempty(sFiles(intFile).sTrackParams)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = 'Tracking parameters have been set';
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'No tracking parameters have been set yet';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN 25];
		sPointers(intFile).TrackParams = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,'Tooltip',strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles.sSync %sync data
		if isfield(sFiles(intFile),'sSync') && ~isempty(sFiles(intFile).sSync)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = 'Sync data is present';
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'Did not find synchronization data';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN 25];
		sPointers(intFile).Sync = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,'Tooltip',strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		
		%sFiles.sParams %online parameters
		if isfield(sFiles(intFile),'sParams') && ~isempty(sFiles(intFile).sParams)
			strText = 'Y';
			vecColor = [0 0.8 0];
			strTip = 'Online parameters are present';
		else
			strText = 'N';
			vecColor = [0.8 0 0];
			strTip = 'Did not find online tracking parameters';
		end
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzYN 25];
		sPointers(intFile).OnlineParams = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','ForegroundColor',vecColor,'FontSize',10,'Tooltip',strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles.name %file name
		strText = sFiles(intFile).name;
		strTip = sFiles(intFile).name;
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzName 25];
		sPointers(intFile).Name = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','FontSize',10,'Tooltip',strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles.date %date
		strDate = num2str(yyyymmdd(datetime(sFiles(intFile).date,'Locale','system')));
		strText = strDate;
		strTip = sFiles(intFile).date;
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzDate 25];
		sPointers(intFile).Date = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','FontSize',10,'Tooltip',strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
		
		%sFiles.bytes %date
		strText = sprintf('%.1fMB',sFiles(intFile).bytes/(1024^2));
		strTip = sFiles(intFile).folder;
		vecLoc = [dblLastX+1 (intFiles*30)-((intFile-1)*30) intHorzBytes 25];
		sPointers(intFile).Bytes = uicontrol(ptrPanelChild,'style','text',...
			'Position',vecLoc,'String',strText,'HorizontalAlignment','Left','FontSize',10,'Tooltip',strTip);
		dblLastX = vecLoc(1) + vecLoc(3);
	end
	
	%show panel
	ETO_SliderCallback(ptrSlider,[],ptrPanelChild);
end