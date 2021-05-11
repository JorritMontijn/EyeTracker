function ETP_AcceptParameters(varargin)
	
	%set accept to true
	global sETP;
	sETP.boolAccept = true;
	
	%save data
	%delete video data
	try
		sETP = rmfield(sETP,{'objVid','matFrames'});
	catch
	end
	%save file
	sET = sETP;
	
	%remove extension & build new name
	cellFile = strsplit(sETP.strVideoFile,'.');
	strFileCore = strjoin(cellFile(1:end-1),'.');
	strName = [strFileCore 'TrackParams.mat'];
	strFolder = sETP.strPath;
	save(fullfile(strFolder,strName),'sET');
	
	%compile structure
	sTrackParams = struct;
	sTrackParams.name = strName;
	sTrackParams.folder = strFolder;
	sTrackParams.sET = sET;
	
	%save
	sETP.sTrackParams = sTrackParams;
	
	%close
	ETP_DeleteFcn();
end