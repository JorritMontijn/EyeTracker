function ET_SwitchRecordVideo(strSelected)
	%% globals
	global sET
	global sEyeFig
	
	%% update switch
	if strcmpi(strSelected,'On')
		if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Filename') && ~isempty(sET.objVidWriter.Filename)
			sET.boolSaveToDisk = true;
			open(sET.objVidWriter);
			set(sEyeFig.ptrButtonRecordVidOn,'Value',1);
		else
			set(sEyeFig.ptrButtonRecordVidOff,'Value',1);
		end
	elseif strcmpi(strSelected,'Off')
		sET.boolSaveToDisk = false;
		set(sEyeFig.ptrButtonRecordVidOff,'Value',1);
		close(sET.objVidWriter);
	end
end