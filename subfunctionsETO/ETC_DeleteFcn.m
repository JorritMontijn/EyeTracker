function ETC_DeleteFcn
	%UNTITLED Summary of this function goes here
	%   Detailed explanation goes here
	global sETC;
	global sFigETC;
	
	%ask to quit
	opts = struct;
	opts.Default = 'Confirm exit?';
	opts.Interpreter = 'none';
	strAns = questdlg('Are you sure you wish to exit?','Confirm exit','Save & Exit','Exit & Discard data','Cancel',opts);
	switch strAns
		case 'Save & Exit'
			%save epochs
			sPupil = ETC_SaveEpochs();
			
			
			%message
			ptrMsg = dialog('Position',[600 400 250 50],'Name','Saving data');
			ptrText = uicontrol('Parent',ptrMsg,...
				'Style','text',...
				'Position',[20 00 210 40],...
				'FontSize',11,...
				'String','Saving data...');
			movegui(ptrMsg,'center')
			drawnow;
			
			%save file
			strTargetFile = fullpath(sPupil.strProcPath,sPupil.strProcFile);
			save(strTargetFile,'sPupil');
			
			%quit
			delete(ptrMsg);
			delete(sFigETC.output);
			clear('sFigETC');
			sETC.boolForceQuit = true;
			sETC.boolSaveData = true;
		case 'Exit & Discard data'
			%quit
			sFigETC.sPupil.sEpochs = sFigETC.sOldEpochs;
			delete(sFigETC.output);
			clear('sFigETC');
			sETC.boolForceQuit = true;
			sETC.boolSaveData = false;
	end
end

