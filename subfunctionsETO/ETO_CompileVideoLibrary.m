function sFiles = ETO_CompileVideoLibrary(strMasterPath,cellExt)
	
	%% compile library
	sFiles = [];
	for intExt=1:numel(cellExt)
		filelist = dir(fullfile(strMasterPath, '**',['*.' cellExt{intExt}]));
		sFiles = [sFiles,filelist];
	end
	%remove mini vids
	sFiles(contains({sFiles.name},'MiniVid')) = [];
	
	%% populate parameters
	for intFile=1:numel(sFiles)
		%get mat files
		sMatFiles = dir(fullfile(sFiles(intFile).folder,'*.mat'));
		
		%split into sync data, track params & neither
		indSyncFiles = contains({sMatFiles.name},'SyncData');
		indTrackParamsFiles = contains({sMatFiles.name},'TrackParams');
		indPupilFiles = contains({sMatFiles.name},'Processed');
		sFilesSync = sMatFiles(indSyncFiles);
		sFilesTrackParams = sMatFiles(indTrackParamsFiles & ~indSyncFiles);
		sFilesPupil = sMatFiles(indPupilFiles & ~indTrackParamsFiles & ~indSyncFiles);
		sFilesParams = sMatFiles(~indPupilFiles & ~indTrackParamsFiles & ~indSyncFiles);
		strOrigFile = sFiles(intFile).name;
		
		%pick track params file with greatest name-overlap
		vecDistT = strdist(strOrigFile,{sFilesTrackParams.name});
		[dummy,intFileT] = min(vecDistT);
		if ~isempty(intFileT)
			strTrackFile = sFilesTrackParams(intFileT).name;
			strTrackFolder = sFilesTrackParams(intFileT).folder;
			sTrackParams = load(fullfile(strTrackFolder,strTrackFile));
			sTrackParams.name = strTrackFile;
			sTrackParams.folder = strTrackFolder;
		else
			sTrackParams = [];
		end
		
		%pick sync file with greatest name-overlap
		vecDistS = strdist(strOrigFile,{sFilesSync.name});
		[dummy,intFileS] = min(vecDistS);
		if ~isempty(intFileS)
			strSyncFile = sFilesSync(intFileS).name;
			strSyncFolder = sFilesSync(intFileS).folder;
			sSync = load(fullfile(strSyncFolder,strSyncFile));
			sSync.name = strSyncFile;
			sSync.folder = strSyncFolder;
		else
			sSync = [];
		end
		
		%pick pupil file with greatest name-overlap
		vecDistP = strdist(strOrigFile,{sFilesPupil.name});
		[dummy,intFileP] = min(vecDistP);
		if ~isempty(intFileP)
			strPupilFile = sFilesPupil(intFileP).name;
			strPupilFolder = sFilesPupil(intFileP).folder;
			sPupil = load(fullfile(strPupilFolder,strPupilFile));
			sPupil.name = strPupilFile;
			sPupil.folder = strPupilFolder;
		else
			sPupil = [];
		end
		
		%pick params file with greatest name-overlap
		vecDistP = strdist(strOrigFile,{sFilesParams.name});
		[dummy,intFileP] = min(vecDistP);
		if ~isempty(intFileP)
			strParamsFile = sFilesParams(intFileP).name;
			strParamsFolder = sFilesParams(intFileP).folder;
			sParams = load(fullfile(strParamsFolder,strParamsFile));
			sParams.name = strParamsFile;
			sParams.folder = strParamsFolder;
		else
			sParams = [];
		end
		
		%assign data
		sFiles(intFile).sTrackParams = sTrackParams;
		sFiles(intFile).sParams = sParams;
		sFiles(intFile).sSync = sSync;
		sFiles(intFile).sPupil = sPupil;
	end
end