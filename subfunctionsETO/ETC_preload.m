function ETC_preload(varargin)
	
	%get globals
	global sETC;
	global sFigETC;
	
	%% lock
	uilock(sFigETC);
	sFigETC.ptrButtonPreload.UserData = 'closed';
	sFigETC.ptrButtonPreload.Enable = 'off';
	sFigETC.ptrButtonPreload.Value = 1;
	
	%% redraw image
	%msg
	hWaitbar = waitbar(0,sprintf('Loading frame %d/%d',1,sETC.intF),'Name','Loading movie');
	movegui(hWaitbar,'center')
	drawnow;
	
	try
		%load video frame
		hTic=tic;
		matFrame = read(sETC.objVid,1);
		matVid = repmat(matFrame,[1 1 1 sETC.intF]);
		for intFrame=2:sETC.intF
			matVid(:,:,:,intFrame) = read(sETC.objVid,intFrame);
			if toc(hTic) > 1
				waitbar(intFrame/sETC.intF,hWaitbar,sprintf('Loading frame %d/%d',intFrame,sETC.intF));
				drawnow;
				hTic = tic;
			end
		end
		sETC.matVid = matVid;
		delete(hWaitbar);
	catch ME
		sFigETC.ptrButtonPreload.UserData = '';
		sFigETC.ptrButtonPreload.Value = 0;
		sFigETC.ptrButtonPreload.Enable = 'on';
		delete(hWaitbar);
		dispErr(ME);
	end
	
	%% redraw
	ETC_redraw();

	%% unlock
	uiunlock(sFigETC);
end