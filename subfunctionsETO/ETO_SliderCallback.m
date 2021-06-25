function ETO_SliderCallback(hObject,eventdata,ptrSubPanel)
	vecSize = ptrSubPanel.Position;
	val = get(hObject,'Value');
	dblRealMax = vecSize(end) - 1;
	dblStartY = val*dblRealMax;
	vecSetPanelPos = [0 dblStartY 1 vecSize(end)];
	set(ptrSubPanel,'Position',vecSetPanelPos);%[from-left from-bottom width height]
end