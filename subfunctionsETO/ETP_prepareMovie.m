function strVidFile = ETP_prepareMovie(strPath,strVideoFile,strTempPath,strAnswer)
	%check temp
	if ~strcmp(strTempPath(end),filesep)
		strTempPath(end+1) = filesep;
	end
	if ~isfolder(strTempPath)
		[status0,msg0,msgID0]=mkdir(strTempPath);
		if status0 == 0,error(msgID0,sprintf('Error creating temp path "%s": %s',strTempPath,msg0));end
	end
	
	%check source
	if ~strcmp(strPath(end),filesep)
		strPath(end+1) = filesep;
	end
	
	%get source size
	sSourceFile = dir([strPath strVideoFile]);
	if isempty(sSourceFile)
		error([mfilename ':FileNotFound'],'Could not find video file');
	end
	
	%check if temp and source are the same
	if strcmp(strPath,strTempPath)
		%use file
		strVidFile = [strPath strVideoFile];
		return
	end
	
	%check if old file is present
	if exist([strTempPath strVideoFile],'file')
		%check if file properties match
		sTempFile = dir([strTempPath strVideoFile]);
		dblCompare1 = sTempFile.bytes;
		dblCompare2 = sSourceFile.bytes;
		if dblCompare1 == dblCompare2
			%use file
			fprintf('File "%s" is already present at local path "%s" [%s]\n',strVideoFile,strTempPath,getTime);
			strVidFile = [strTempPath strVideoFile];
			return;
		else
			%delete temp file
			delete([strTempPath strVideoFile]);
		end
	end
	
	if ~exist('strAnswer','var') || isempty(strAnswer)
		%ask whether to copy
		sOpts.Interpreter = 'none';
		sOpts.Default = 'Yes';
		strAnswer = questdlg(sprintf('Make a temporary file for fast access?\n\n%s => %s',strPath,strTempPath), ...
			'Create temporary file?', ...
			'Yes','No',sOpts);
	end
	
	if strcmp(strAnswer,'Yes')
		
		% message
		ptrMsg = dialog('Position',[600 400 250 50],'Name','Copying file');
		ptrText = uicontrol('Parent',ptrMsg,...
			'Style','text',...
			'Position',[20 00 210 40],...
			'FontSize',11,...
			'String',sprintf('Copying video (%.1f MB)...',sSourceFile.bytes/(1024^2)));
		movegui(ptrMsg,'center')
		drawnow;
		
		%copy
		fprintf('Copying "%s" to local path "%s" [%s]\n',strVideoFile,strTempPath,getTime);
		[status1,msg1,msgID1] = copyfile([strPath strVideoFile],[strTempPath strVideoFile]);
		
		%close msg
		if status1 == 0
			error(msgID1,msg1);
			ptrText.String = msg1;
		else
			delete(ptrMsg);
		end
		
		%assign output
		strVidFile = [strTempPath strVideoFile];
	else
		%assign output
		strVidFile = [strPath strVideoFile];
	end
end