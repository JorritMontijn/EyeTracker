function ETO_Scrollwheel(hObject,eventdata)
	global sFigETO;
	
	if ~isfield(sFigETO,'ptrSliderLibrary') || isempty(sFigETO.ptrSliderLibrary),return;end
	
	%calculate new position
	dblMove = eventdata.VerticalScrollCount*eventdata.VerticalScrollAmount;
	dblNewVal = sFigETO.ptrSliderLibrary.Value - dblMove/100;
	if dblNewVal < 0
		dblNewVal = 0;
	end
	if dblNewVal > 1
		dblNewVal = 1;
	end
	
	%move slider
	sFigETO.ptrSliderLibrary.Value = dblNewVal;
	
	%change window
	ETO_SliderCallback(sFigETO.ptrSliderLibrary,[],sFigETO.ptrSliderLibrary.Callback{2});
	
end