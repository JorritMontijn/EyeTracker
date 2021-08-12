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
			%save
			ETC_SaveEpochs();
			
			%quit
			delete(sFigETC.output);
			clear('sFigETC');
			sETC.boolForceQuit = true;
		case 'Exit & Discard data'
			%quit
			sFigETC.sPupil.sEpochs = sFigETC.sOldEpochs;
			delete(sFigETC.output);
			clear('sFigETC');
			sETC.boolForceQuit = true;
	end
end

