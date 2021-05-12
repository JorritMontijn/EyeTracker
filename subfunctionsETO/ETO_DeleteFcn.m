function ETO_DeleteFcn
	%UNTITLED Summary of this function goes here
	%   Detailed explanation goes here
	
	%globals
	global sFigETO;
	global sETO;
	
	%close
	sFigETO.IsRunning = false;
	
	%save config to ini
	strPathFile = mfilename('fullpath');
	cellDirs = strsplit(strPathFile,filesep);
	strPath = strjoin(cellDirs(1:(end-2)),filesep);
	strIni = strcat(strPath,filesep,'configETO.ini');
	
	%save settings to ini
	sETO2=struct;
	sETO2.strRootPath = sETO.strRootPath;
	sETO2.strTempPath = sETO.strTempPath;
	
	%save ini
	strData = struct2ini(sETO2,'sETO');
	fFile = fopen(strIni,'wt');
	fprintf(fFile,strData);
	fclose(fFile);
end

