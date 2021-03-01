function ET_SwitchOnlineDetection(strSelected)
	%% globals
	global sET;
	global sEyeFig;

	%% update switch
	if strcmpi(strSelected,'On')
		set(sEyeFig.ptrButtonDetectPupilOn,'Value',1);
		sET.boolDetectPupil = true;
		%check if an output file has been defined
		if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Filename') && ~isempty(sET.objVidWriter.Filename)
			%build filename
			strFile = sET.objVidWriter.Filename;
			cellFile = strsplit(strFile,'.');
			strNoExt = strjoin(cellFile(1:(end-1)),'.');
			sET.strDataOutFile = strcat(strNoExt,'.csv');
			sET.strDataOutPath = sET.objVidWriter.Path;
			
			%open file
			if ~isfield(sET,'ptrDataOut')
				sET.ptrDataOut = fopen(strcat(sET.strDataOutPath,filesep,sET.strDataOutFile),'wt+');
				%write variable names
				strData = '"Time","VidFrame","SyncLum","SyncPulse","CenterX","CenterY","MajorAx","MinorAx","Orient","Eccentric","Roundness","FrameNI","SecsNI"';
				strData = strcat(strData,'\n');
				fprintf(sET.ptrDataOut,strData);
			else
				try,fclose(sET.ptrDataOut);catch,end %try to close, just in case
				sET.ptrDataOut = fopen(strcat(sET.strDataOutPath,filesep,sET.strDataOutFile),'at+');
			end
		end
	elseif strcmpi(strSelected,'Off')
		set(sEyeFig.ptrButtonDetectPupilOff,'Value',1);
		sET.boolDetectPupil = false;
		%close file
		if isfield(sET,'ptrDataOut') && ftell(sET.ptrDataOut) >= 0
			fclose(sET.ptrDataOut);
		end
	end
end