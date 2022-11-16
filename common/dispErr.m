function dispErr(sME)
	%dispErr Shows error without cancelling script
	%   dispErr(sME)
	
	strID = sME.identifier;
	strMsg = sME.message;
	
	%try error as warning
	try
		fprintf('%s: %s\n',strID,strMsg);
	catch
	end
	%show stack
	intStackLength = numel(sME.stack);
	for intDepth=1:intStackLength
		strFilePath = sME.stack(intDepth).file;
		strName = sME.stack(intDepth).name;
		strLine = sME.stack(intDepth).line;
		strFile = getFlankedBy(strFilePath,filesep,'.m','last');
		fprintf('%s: %s [Line %d]\n',strFile,strName,strLine);
	end
end

