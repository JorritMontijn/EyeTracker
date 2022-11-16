function uilock(handles)
	%uilock Shared Core GUI locker
	%   uilock(handles)
	%Enable,'off'
	%{
	cellNames = fieldnames(handles);
	for intPtr=1:numel(cellNames)
		if (~isempty(strfind(cellNames{intPtr},'ptrButton')) || ...
				~isempty(strfind(cellNames{intPtr},'ptrList')) || ...
				~isempty(strfind(cellNames{intPtr},'ptrEdit'))) && ...
				isempty(strfind(cellNames{intPtr},'ptrButtonSave'))
			set(handles.(cellNames{intPtr}),'Enable','off');
			if strcmpi(get(handles.(cellNames{intPtr}),'UserData'),'lock')
				set(handles.(cellNames{intPtr}),'UserData','unlock');
			end
		end
	end
	%}
	%% new
	if isstruct(handles) && isfield(handles,'output')
		uilock(handles.output);
	end
	cellLockTypes = {'pushbutton','togglebutton','checkbox','radiobutton','edit','slider','listbox','popupmenu'};
	if isprop(handles,'Type') && strcmp(handles.Type,'uicontrol') && isprop(handles,'Style') && contains(handles.Style,cellLockTypes)
		if ~(isprop(handles,'String') && all(contains(handles.String,'save','IgnoreCase',true))) && ...
				(~isempty(get(handles,'UserData')) && ~strcmpi(get(handles,'UserData'),'open'))
			set(handles,'Enable','off');
			if strcmpi(get(handles,'UserData'),'lock')
				set(handles,'UserData','unlock');
			end
		end
	end
	if isprop(handles,'Children')
		vecChildren = handles.Children;
		for intChild=1:numel(vecChildren)
			uilock(handles.Children(intChild));
		end
	end
end

