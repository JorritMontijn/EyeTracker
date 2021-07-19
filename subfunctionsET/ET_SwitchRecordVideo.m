function ET_SwitchRecordVideo(strSelected)
	%% globals
	global sET
	global sEyeFig
	
	%% update switch
	if strcmpi(strSelected,'On')
		if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Filename') && ~isempty(sET.objVidWriter.Filename)
			sET.boolSaveToDisk = true;
			open(sET.objVidWriter);
			if isfield(sET,'objVidWriterROI') && isprop(sET.objVidWriterROI,'Filename') && ~isempty(sET.objVidWriterROI.Filename)
				open(sET.objVidWriterROI);
			end
			set(sEyeFig.ptrButtonRecordVidOn,'Value',1);
		else
			set(sEyeFig.ptrButtonRecordVidOff,'Value',1);
		end
	elseif strcmpi(strSelected,'Off')
		sET.boolSaveToDisk = false;
		set(sEyeFig.ptrButtonRecordVidOff,'Value',1);
		close(sET.objVidWriter);
		close(sET.objVidWriterROI);
	end
end