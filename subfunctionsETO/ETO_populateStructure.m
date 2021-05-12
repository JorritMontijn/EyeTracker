function sETO = ETO_populateStructure(sETO)
	%ET_populateStructure Prepares EyeTracker parameters by loading ini file,
	%						or creates one with default values
	
	%check for ini file
	strPathFile = mfilename('fullpath');
	cellDirs = strsplit(strPathFile,filesep);
	strPath = strjoin(cellDirs(1:(end-2)),filesep);
	strIni = strcat(strPath,filesep,'configETO.ini');
	
	%get defaults
	sDETO = ETO_defaultValues();
	
	%load ini
	if exist(strIni,'file')
		%load data
		fFile = fopen(strIni,'rt');
		vecData = fread(fFile);
		fclose(fFile);
		%convert
		strData = cast(vecData','char');
		[cellStructs,cellStructNames] = ini2struct(strData);
		eval([cellStructNames{1} '= cellStructs{1};']);
		%merge structures
		warning('off','catstruct:DuplicatesFound');
		sETO=catstruct(sDETO,sETO);
		warning('on','catstruct:DuplicatesFound');
	else
		sETO=sDETO;
	end
end
function sETO = ETO_defaultValues()
	%define defaults
	sETO.strRootPath = 'P:\Montijn\DataNeuropixels\';
	sETO.strTempPath = 'E:\_TempData'; %fast & reliable ssd;
end