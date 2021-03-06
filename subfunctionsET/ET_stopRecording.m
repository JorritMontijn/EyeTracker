function ET_stopRecording()
	%ET_stopRecording Function to run at recording stop
	
	%get globals
	global sET;
	global sEyeFig;
	
	%close video writer
	if isfield(sET,'objVidWriter'),close(sET.objVidWriter);end
	if isfield(sET,'objVidWriterROI')
		close(sET.objVidWriterROI);
		try,fclose(sET.ptrFileLuminance);catch,end
	end
	
	%close csv file
	try,fclose(sET.ptrDataOut);catch,end
    %set switch to off
	sET.boolRecording = false;
    
	%save config to ini
	strPathFile = mfilename('fullpath');
	cellDirs = strsplit(strPathFile,filesep);
	strPath = strjoin(cellDirs(1:(end-2)),filesep);
	strIni = strcat(strPath,filesep,'config.ini');
	
	%save settings to ini
	sET2=struct;
	sET2.intTempAvg = sET.intTempAvg;
	sET2.dblGaussWidth = sET.dblGaussWidth;
	sET2.vecRectROI = sET.vecRectROI;
	sET2.vecRectSync = sET.vecRectSync;
	sET2.dblThreshSync = sET.dblThreshSync;
	sET2.dblThreshReflect = sET.dblThreshReflect;
	sET2.dblThreshPupil = sET.dblThreshPupil;
	sET2.dblPupilMinRadius = sET.dblPupilMinRadius;
	sET2.intSubSample = sET.intSubSample;
	sET2.boolInvertImage = sET.boolInvertImage;
	sET2.boolRotateImage = sET.boolRotateImage;
	sET2.boolFlipImageUpDown = sET.boolFlipImageUpDown;
	sET2.boolSaveVidROI = sET.boolSaveVidROI;
	sET2.dblGain = sET.dblGain;
	sET2.dblGamma = sET.dblGamma;
	sET2.strHostSGL = sET.strHostSGL;
	
	%save ini
	strData = struct2ini(sET2,'sET');
	fFile = fopen(strIni,'wt');
	fprintf(fFile,strData);
	fclose(fFile);
	
	%save sET
	if isfield(sET,'objVidWriter') && isprop(sET.objVidWriter,'Filename') && ~isempty(sET.objVidWriter.Filename)
		%build filename
		strFile = sET.objVidWriter.Filename;
		cellFile = strsplit(strFile,'.');
		strNoExt = strjoin(cellFile(1:(end-1)),'.');
		strMatFile = strcat(strNoExt,'.mat');
		strDataOutPath = sET.objVidWriter.Path;
		sET3 = sET;
		sET = rmfield(sET3,{'sDevices','objCam','objVid','objVidWriter','objVidWriterROI','hSGL'}); %#ok<NASGU>
		save(strcat(strDataOutPath,filesep,strMatFile),'sET');
		sET = sET3;
	end
	
	%switch raw video recording to off
	sET.boolSaveToDisk = false;
	set(sEyeFig.ptrButtonRecordVidOff,'Value',1);
    
	%disable recording button
	set(sEyeFig.ptrToggleRecord,'Enable','off');
	
	%remove target file
	set(sEyeFig.ptrTextVidOutFile,'String','');
	set(sEyeFig.ptrTextVidOutPath,'String','');
	
	%save sync data as separate file
	if isfield(sET,'sSyncData')
		%get data
		sSyncData=sET.sSyncData;
		sET = rmfield(sET,{'sSyncData'});
		
		%remove nans
		sSyncData.matSyncData(:,sSyncData.intSyncCounter:end) = [];
					
		%build filename
		strFile = sET.objVidWriter.Filename;
		cellFile = strsplit(strFile,'.');
		strNoExt = strjoin(cellFile(1:(end-1)),'.');
		strMatFile = strcat(strNoExt,'SyncData.mat');
		strDataOutPath = sET.objVidWriter.Path;
		save(strcat(strDataOutPath,filesep,strMatFile),'sSyncData');
	end
end

