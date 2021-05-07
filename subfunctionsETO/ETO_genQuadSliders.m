function [ptrPanelParent,ptrSlider,ptrPanel,sPointers] = ETO_genQuadSliders(ptrMainGUI,vecLocation,strName)
	
	%error 'add description of entries (vertical?), add tracking parameter button+gui, and add "run all" button'
	
	%% set constants
	%unpack location vector
	dblPanelX = vecLocation(1);
	dblPanelY = vecLocation(2);
	dblW = vecLocation(3);
	dblH = vecLocation(4);
	
	%calculate the total size of the subpanel content
	dblTextX = 0.02;
	dblSlider1Start = 0.07;
	dblSlider1End = 0.51;
	dblSliderWidth = dblSlider1End-dblSlider1Start;
	dblSlider2Start = 0.53;
	dblSlider2End = 0.97;
	
	dblTextY = 0;%0-20
	dblTopY = 0.25;%25-55
	dblBottomY = 0.6;%60-90
	dblSliderHeight = 0.3;%
	
	%% make panel
	ptrPanel = uipanel('Parent',ptrMainGUI);
	vecColor = get(ptrMainGUI,'Color');
	set(ptrPanel,'Position',vecLocation,'BackgroundColor',vecColor,'Title',strName,'FontSize',10);
	%X
	uicontrol(ptrPanel,'Units','Normalized','Style','text','FontSize',10,...
		'String','X:',...
		'Position',[dblTextX 1-dblTopY-dblSliderHeight dblSlider1Start dblSliderHeight],'BackgroundColor',vecColor);
	%Y
	uicontrol(ptrPanel,'Units','Normalized','Style','text','FontSize',10,...
		'String','Y:',...
		'Position',[dblTextX 1-dblBottomY-dblSliderHeight dblSlider1Start dblSliderHeight],'BackgroundColor',vecColor);
	%Start
	uicontrol(ptrPanel,'Units','Normalized','Style','text','FontSize',10,...
		'String','Start Location',...
		'Position',[dblSlider1Start 1-dblTopY dblSliderWidth dblTopY],'BackgroundColor',vecColor);
	%Stop
	uicontrol(ptrPanel,'Units','Normalized','Style','text','FontSize',10,...
		'String','Stop Location',...
		'Position',[dblSlider2Start 1-dblTopY dblSliderWidth dblTopY],'BackgroundColor',vecColor);
	
	ptrSliderLeftTop = uicontrol('Style','Slider','Parent',ptrPanel,...
		'Units','normalized','Position',[dblSlider1Start 1-dblTopY-dblSliderHeight dblSliderWidth dblSliderHeight],...
		'Callback',{@ETO_ROICallback,'LT'});
	ptrSliderRightTop = uicontrol('Style','Slider','Parent',ptrPanel,...
		'Units','normalized','Position',[dblSlider2Start 1-dblTopY-dblSliderHeight dblSliderWidth dblSliderHeight],...
		'Callback',{@ETO_ROICallback,'RT'});
	
	ptrSliderLeftBot = uicontrol('Style','Slider','Parent',ptrPanel,...
		'Units','normalized','Position',[dblSlider1Start 1-dblBottomY-dblSliderHeight dblSliderWidth dblSliderHeight],...
		'Callback',{@ETO_ROICallback,'LB'});
	ptrSliderRightBot = uicontrol('Style','Slider','Parent',ptrPanel,...
		'Units','normalized','Position',[dblSlider2Start 1-dblBottomY-dblSliderHeight dblSliderWidth dblSliderHeight],...
		'Callback',{@ETO_ROICallback,'RB'});
	
end