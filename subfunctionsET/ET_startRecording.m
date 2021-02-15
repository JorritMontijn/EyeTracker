function ET_startRecording()
	%ET_startRecording Function to run at recording start
	
	%get globals
	global sET;
	global sEyeFig;
	
	%set recording text
	set(sEyeFig.ptrTextRecording,'String','Recording','ForegroundColor',[0 0.8 0]);
	%lock gui
	ET_lock(sEyeFig);
	set(sEyeFig.ptrToggleConnectSGL,'Enable','off');
	sET.boolRecording = true;
	sET.intSyncPulse = 0; %reset sync pulses
	sET.dblRecStart = str2double(get(sEyeFig.ptrTextVidTime,'String')); %reset recording start
end