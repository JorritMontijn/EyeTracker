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
		%just use print
		if numel(varargin) == 1
			strFile = varargin{1};
			[a,b,strExt]=fileparts(strFile);
			if strcmp(strExt,'.jpg') || strcmp(strExt,'.jpeg')
				strFormat = '-djpeg';
			elseif strcmp(strExt,'.tif') || strcmp(strExt,'.tiff')
				strFormat = '-dtiff';
			else
				%just try -d prefix...
				strFormat = ['-d' strExt(2:end)];
			end
			if nargout > 0
				varargout{:} = print(strFile,strFormat);
			else
				print(strFile,strFormat);
			end
		else
			if nargout > 0
				varargout{:} = print(varargin{:});
			else
				print(varargin{:});
			end
		end
	end