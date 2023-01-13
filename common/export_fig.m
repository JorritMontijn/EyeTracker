function varargout = export_fig(varargin)
	%wrapper for export_fig
	cellExportFigs= which(mfilename,'-all');
	strThisFile = mfilename('fullpath');
	indOtherFiles = ~contains(cellExportFigs,strThisFile);
	if any(indOtherFiles)
		%invoke other function
		strTarget = cellExportFigs{find(indOtherFiles,1)};
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
			[a,b,strExt]=fileparts(strFile);
			if nargout > 0
				varargout{:} = saveas(gcf,[strFile,strExt]);
			else
				saveas(gcf,[strFile,strExt]);
			end
		else
			if nargout > 0
				varargout{:} = saveas(varargin{:});
			else
				saveas(varargin{:});
			end
		end
	end