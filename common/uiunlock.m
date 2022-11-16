function uiunlock(handles)
	%uiunlock Shared Core GUI unlocker
	%   uiunlock(handles)
	%Enable,'off'
	%{
	cellNames = fieldnames(handles);
	for intPtr=1:numel(cellNames)
		if ~isempty(strfind(cellNames{intPtr},'ptrButton')) ||...
				~isempty(strfind(cellNames{intPtr},'ptrList')) ||...
				~isempty(strfind(cellNames{intPtr},'ptrEdit'))
			if ~strcmpi(get(handles.(cellNames{intPtr}),'UserData'),'lock')
				set(handles.(cellNames{intPtr}),'Enable','on');
			end
		end
	end
	%}
	%% new
	if isstruct(handles) && isfield(handles,'output')
		uiunlock(handles.output);
	end
	cellLockTypes = {'pushbutton','togglebutton','checkbox','radiobutton','edit','slider','listbox','popupmenu'};
	if isprop(handles,'Type') && strcmp(handles.Type,'uicontrol') && isprop(handles,'Style') && contains(handles.Style,cellLockTypes)
		if ~strcmpi(get(handles,'UserData'),'lock') && ~strcmpi(get(handles,'UserData'),'closed')
			set(handles,'Enable','on');
		end
	end
	if isprop(handles,'Children')
		vecChildren = handles.Children;
		for intChild=1:numel(vecChildren)
			uiunlock(handles.Children(intChild));
		end
	end
end

