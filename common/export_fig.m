function varargout = export_fig(varargin)
	%wrapper for export_fig
	cellExportFigs= which(mfilename,'-all');
	strThisFile = mfilename('fullpath');
	indOtherFiles = ~contains(cellExportFigs,strThisFile);
	strFile = varargin{1};
	[a,b,strExt]=fileparts(strFile);
	if any(indOtherFiles) && ~(strcmp(strExt,'.jpg') || strcmp(strExt,'.jpeg') || strcmp(strExt,'.tif') || strcmp(strExt,'.tiff'))
		%invoke other function
		vecOtherFiles = find(indOtherFiles);
		sFiles = dir(cellExportFigs{vecOtherFiles(1)});
		for intFile=2:numel(vecOtherFiles)
			sFiles(intFile) = dir(cellExportFigs{vecOtherFiles(intFile)});
		end
		[dummy,intTargetFile] = max(cell2vec({sFiles.bytes}));
		strTarget = fullpath(sFiles(intTargetFile).folder,sFiles(intTargetFile).name);
		strPath=fileparts(strTarget);
		strOldPath=cd(strPath);
		%get function handle
		fFunc=str2func(mfilename);
		%move back & eval
		cd(strOldPath);
		if nargout > 0
			varargout{:} = feval(fFunc,varargin{:});
		else
			feval(fFunc,varargin{:});
		end
	else
		%just use saveas
		if numel(varargin) == 1
			strFile = varargin{1};
			[strPath,strName,strExt]=fileparts(strFile);
			if nargout > 0
				varargout{:} = saveas(gcf,fullpath(strPath,[strName,strExt]));
			else
				saveas(gcf,fullpath(strPath,[strName,strExt]));
			end
		else
			if nargout > 0
				varargout{:} = saveas(varargin{:});
			else
				saveas(varargin{:});
			end
		end
	end