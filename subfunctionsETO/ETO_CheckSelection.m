function indUseFiles = ETO_CheckSelection(sFigETO)
	%get checked
	if isfield(sFigETO,'sPointers') && isfield(sFigETO.sPointers,'CheckRun')
		indUseFiles = cellfun(@(x) x.Value==1,{sFigETO.sPointers.CheckRun});
	else
		indUseFiles = [];
	end
	
	%check if any
	if ~any(indUseFiles)
		ptrMsg = dialog('Position',[600 400 250 100],'Name','No files selected');
		ptrText = uicontrol('Parent',ptrMsg,...
			'Style','text',...
			'Position',[20 50 210 40],...
			'FontSize',11,...
			'String','You did not select any files');
		ptrButton = uicontrol('Parent',ptrMsg,...
			'Position',[100 20 50 30],...
			'String','OK',...
			'FontSize',10,...
			'Callback','delete(gcf)');
		
		movegui(ptrMsg,'center')
		drawnow;
		return
	end
end