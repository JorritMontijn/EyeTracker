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
		
		%split into sync data, labels, track params & other
		indLabelFiles = contains({sMatFiles.name},'Labels');
		indSyncFiles = contains({sMatFiles.name},'SyncData');
		indTrackParamsFiles = contains({sMatFiles.name},'TrackParams');
		indPupilFiles = contains({sMatFiles.name},'Processed');
		sFilesLabels = sMatFiles(indLabelFiles);
		sFilesSync = sMatFiles(indSyncFiles & ~indLabelFiles);
		sFilesTrackParams = sMatFiles(indTrackParamsFiles & ~indSyncFiles & ~indLabelFiles);
		sFilesPupil = sMatFiles(indPupilFiles & ~indTrackParamsFiles & ~indSyncFiles & ~indLabelFiles);
		sFilesParams = sMatFiles(~indPupilFiles & ~indTrackParamsFiles & ~indSyncFiles & ~indLabelFiles);
		strOrigFile = sFiles(intFile).name;
		
		%pick track params file with greatest name-overlap
		vecDistL = strdist(strOrigFile,{sFilesLabels.name});
		[dummy,intFileL] = min(vecDistL);
		if ~isempty(intFileL)
			strLabelFile = sFilesLabels(intFileL).name;
			strLabelFolder = sFilesLabels(intFileL).folder;
			sLabelLoad = load(fullfile(strLabelFolder,strLabelFile));
			sLabelLoad.name = strLabelFile;
			sLabelLoad.folder = strLabelFolder;
		else
			sLabelLoad = [];
		end
		%fcheck if file matches
		if isempty(sLabelLoad)
			sLabels = [];
		elseif sLabelLoad.sLabels.ParentVid ~= strOrigFile
			warning([mfilename ':NameMismatch'],sprintf('Video parent of "%s" [%s] does not match "%s"',strLabelFile,sLabelLoad.sLabels.ParentVid,strOrigFile));
			errordlg(sprintf('Label file %s has mismatching video parent: move or delete file',strLabelFile),'Video name mismatch');
			sLabels = [];
		else
			sLabels = sLabelLoad.sLabels;
		end
		
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
		sFiles(intFile).sLabels = sLabels;
		sFiles(intFile).sTrackParams = sTrackParams;
		sFiles(intFile).sParams = sParams;
		sFiles(intFile).sSync = sSync;
		sFiles(intFile).sPupil = sPupil;
	end
end