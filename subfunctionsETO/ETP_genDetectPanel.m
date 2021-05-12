function [hPanelD,sHandles] = ETP_genDetectPanel(ptrMainGUI,vecLocation,strName,sET)
	%ETP_genQuadSliders Generates quad sliders
	%   [hPanelD,hGain,hGamma,hTempAvg,hBlur,hMinRad,hReflLum,hPupLum] = ETP_genDetectPanel(ptrMainGUI,vecLocation,'Detection settings');
	
	%% get parameters
	%get defaults & overwrite with supplied parameters
	sDET = ET_populateStructure();
	sET = catstruct(sDET,sET);
	sDET.dblGain = 1;
	sDET.dblGamma = 1;
	%retrieve parameters
	dblGain = sET.dblGain;%: 0.2000
	dblGamma = sET.dblGamma;%: 0.5000
	intTempAvg = sET.intTempAvg;%: 10
	dblGaussWidth = sET.dblGaussWidth;%: 0.2000
	dblStrEl = sET.dblStrEl;%: 0.5000
	dblThreshPupil = sET.dblThreshPupil;%: 21
	dblThreshReflect = sET.dblThreshReflect;%: 70
	
	%gain / gamma / temp avg / blur width
	%min radius / reflect lum / pupil lum
	%x locations
	dblSpacing = 0.01;
	dblTxtW = 0.13;
	vecX_txt = linspace(dblSpacing,1-dblSpacing,5);
	vecX_txt = vecX_txt(1:(end-1)) - dblSpacing;
	vecX_Edit = vecX_txt + dblTxtW + dblSpacing;
	dblEditW = mean(vecX_txt(2:end) - vecX_Edit(1:(end-1))) - dblSpacing;
	%y locations
	vecY = linspace(dblSpacing,1-dblSpacing,6);
	vecY = vecY([2 4]);
	%dblH = mean(vecY(2:end) - vecY(1:(end-1))) - dblSpacing;
	dblH = 0.25;
	
	%% make panel
	hPanelD = uipanel('Parent',ptrMainGUI);
	vecColor = get(ptrMainGUI,'Color');
	set(hPanelD,'Position',vecLocation,'BackgroundColor',vecColor,'Title',strName,'FontSize',10);
	
	%% build elements
	%set identifiers
	cellPtr = {'Gain','Gamma','TempAvg','Blur','StrEl','ReflLum','PupLum'};
	cellTxt = {'Gain:','Gamma:','Fr. Avg.:','Blur:','Erode:','Refl. T.:','Pupil T.:'};
	cellTip = {'Image Gain','Image Gamma','Temporal averaging (# of frames)','Gaussian sd of spatial smoothing','Size of erosion','Pixel brighter than this will be ignored','Pixels darker than this might be the pupil'};
	cellVal = {'dblGain','dblGamma','intTempAvg','dblGaussWidth','dblStrEl','dblThreshReflect','dblThreshPupil'};
	cellFmt = {'%.2f','%.2f','%.0f','%.2f','%.0f','%.1f','%.1f'};
	%set structure
	intX = 0;
	intY = numel(vecY);
	for intEl=1:numel(cellPtr)
		%get location
		intX = intX + 1;
		if intX > numel(vecX_txt)
			intX = 1;
			intY = intY - 1;
		end
		dblTextX = vecX_txt(intX);
		dblTextY = vecY(intY)+2*dblSpacing;
		dblEditX = vecX_Edit(intX);
		dblEditY = vecY(intY);
		
		%static text
		vecLocTxt = [dblTextX dblTextY dblTxtW dblH];
		%vecLocTxt = [0.5 0.5 20 20]
		ptrText=uitext('Parent',hPanelD,...
			'Units','normalized',...
			'Style','text',...
			'HorizontalAlignment','right',...
			'Position',vecLocTxt,...
			'FontSize',10,...
			'String',cellTxt{intEl});
		
		%edit text
		sData = struct;
		sData.Ptr = cellPtr{intEl};
		sData.Txt = cellTxt{intEl};
		sData.Tip = cellTip{intEl};
		sData.Val = cellVal{intEl};
		sData.Fmt = cellFmt{intEl};
		
		hEdit = uicontrol('Parent',hPanelD,...
			'Units','normalized',...
			'Style','edit',...
			'Position',[dblEditX dblEditY dblEditW dblH],...
			'FontSize',10,...
			'String',sprintf(sData.Fmt,sET.(cellVal{intEl})),...
			'Callback',{@ETP_DetectEdit,cellPtr{intEl}},...
			'UserData',sData,...
			'Tooltip',cellTip{intEl});
		
		%assign handle
		sHandles.(cellPtr{intEl}) = hEdit;
	end
	
	%% end with auto button
	%get location
	intX = intX + 1;
	if intX > numel(vecX_txt)
		intX = 1;
		intY = intY - 1;
	end
	dblButX = vecX_Edit(intX)-dblEditW;
	dblButY = vecY(intY)+2*dblSpacing;
	vecLocBut = [dblButX dblButY dblEditW*2 dblH];
	
	%button
	hButton = uicontrol('Parent',hPanelD,...
		'Units','normalized',...
		'Style','pushbutton',...
		'Position',vecLocBut,...
		'FontSize',10,...
		'String','Auto set',...
		'Callback',{@ETP_AutoSettings},...;
		'Tooltip','Automatically detect best settings');
	
	%assign handle
	sHandles.ptrButtonAutoSettings = hButton;
end