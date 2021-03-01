function ET_setVidOut(strRecFile)
	%UNTITLED Summary of this function goes here
	%   Detailed explanation goes here
	
	%% globals
	global sET;
	global sEyeFig;
	
	%% set video writer
	%create videowriter object to save video using MPEG-4
	cellVidFormats = {'Motion JPEG AVI','Motion JPEG 2000','MPEG-4'};
	cellVidExtensions = {'.avi','.mj2','.mp4'};
	intUseFormat = 3;
	
	% get file location
	%switch path
	try
		if ~exist(sET.strDirDataOut,'dir')
			mkdir(sET.strDirDataOut);
		end
		oldPath = cd(sET.strDirDataOut);
	catch
		oldPath = cd();
	end
	
	%get file
	strPrefix = 'PupVid_';
	if exist('strRecFile','var')
		strRecPath = sET.strDirDataOut;
		strRecFile = strcat(strPrefix,strRecFile);
		%add extension
		if ~contains(strRecFile((end-3):end),cellVidExtensions)
			strRecFile = strcat(strRecFile,cellVidExtensions{intUseFormat});
		end
	else
		[strRecFile, strRecPath] = uiputfile(cellVidExtensions{intUseFormat}, sprintf('Save Video As (*.%s)',cellVidExtensions{intUseFormat}),strcat(strPrefix,getDate,'_R'));
	end
	
	%back to old path
	cd(oldPath);
	
	%check if output is okay
	if isempty(strRecFile) || ~ischar(strRecFile)
		return;
	end
	
	%check path ends with filesep
	if ~strcmp(strRecPath(end),filesep)
		strRecPath(end+1) = filesep;
	end
	
	%check if previous video file exists and close it
	if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Filename') && ~isempty(sET.objVidWriter.Filename)
		close(sET.objVidWriter);
	end
	
	%save video writer data
	objVidWriter = VideoWriter(strcat(strRecPath,strRecFile), cellVidFormats{intUseFormat});
	objVidWriter.FrameRate = sET.dblRealFrameRate;
	sET.objVidWriter = objVidWriter;
	sET.strRecPath = strRecPath;
	sET.strRecFile = strRecFile;
	
	%switch raw video recording to on
	ET_SwitchRecordVideo('On');
	ET_SwitchOnlineDetection('On');
	
	%enable recording button
	set(sEyeFig.ptrToggleRecord,'Enable','on');
	
	%check to enable auto-start
	sET.boolAutoStart = sEyeFig.ptrButtonAutoStart.Value;
	
	%% update text
	set(sEyeFig.ptrTextVidOutFile,'String',objVidWriter.Filename);
	set(sEyeFig.ptrTextVidOutPath,'String',objVidWriter.Path);
end

