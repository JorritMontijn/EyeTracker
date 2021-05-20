function [ptrPanel,ptrSliderFrame,ptrEditFrame] = ETP_genMovieSlider(ptrMainGUI,vecLocation,sETP,sFigETP,fCallback)
	
	%% set constants
	%unpack location vector
	dblSliderWidth = 0.8;
	dblSliderHeight = 0.5;
	
	%% make panel
	ptrPanel = uipanel('Parent',ptrMainGUI);
	vecColor = get(ptrMainGUI,'Color');
	set(ptrPanel,'Position',vecLocation,'BackgroundColor',vecColor,'Title','Frame selection','FontSize',10);
	
	ptrSliderFrame= uicontrol('Style','Slider','Parent',ptrPanel,...
		'Units','normalized','Position',[0.01 0.2 dblSliderWidth dblSliderHeight],...
		'Value',1,'Min',1,'Max',sETP.intF,'SliderStep',[1 sETP.intF/10]./sETP.intF,...
		'Callback',{fCallback,'Slider'});
	sFigETP.ptrSliderFrame = ptrSliderFrame;
	
	%edit box for frame selection
	ptrEditFrame= uicontrol('Style','edit','Parent',ptrPanel,...
		'Units','normalized','Position',[0.05+dblSliderWidth 0.2 1-dblSliderWidth-0.05 dblSliderHeight],...
		'String',sprintf('%.0f',sFigETP.intCurFrame),...
		'Callback',{fCallback,'Edit'});
	sFigETP.ptrEditFrame = ptrEditFrame;
end