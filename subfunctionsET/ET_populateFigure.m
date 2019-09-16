function sEyeFig = ET_populateFigure(handles,boolInit,sFigIn)
	%OT_populateFigure Populates global figure structure
	
	%check for initial run
	if ~exist('boolInit','var') || isempty(boolInit)
		boolInit = true;
	end
	
	%which defaults to save
	cellDefaults = {'String','Value'};
	%populate button pointers
	cellFields = fieldnames(handles);
	for intField=1:length(cellFields)
		strField = cellFields{intField};
		if length(strField) > 3 && strcmp(strField(1:3),'ptr')
			sEyeFig.(strField) = handles.(strField);
			if boolInit
				sEyeFig.sDefaults.(strField) = struct;
				for intDef=1:numel(cellDefaults)
					strDefault = cellDefaults{intDef};
					try
						sEyeFig.sDefaults.(strField).(strDefault) = get(handles.(strField),strDefault);
					catch
					end
				end
			else
				for intDef=1:numel(cellDefaults)
					strDefault = cellDefaults{intDef};
					sEyeFig.sDefaults.(strField) = sFigIn.sDefaults.(strField);
					if isfield(sFigIn.sDefaults.(strField),strDefault)
						sEyeFig.sDefaults.(strField).(strDefault) = sFigIn.sDefaults.(strField).(strDefault);
						set(sEyeFig.(strField),strDefault,sFigIn.sDefaults.(strField).(strDefault));
					end
				end
			end
		end
	end
	
	%allocate other variables
	sEyeFig.ptrMainGUI = handles.output;
	sEyeFig.boolIsRunning = true;
	sEyeFig.boolIsBusy = false;
end