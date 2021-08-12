function sLabels = ETP_GetImLabels(matAllIm)
	
	set(0,'units','pixels')
	vecScreenRect = get(0,'screensize');
	
	h=figure('Name','Image labeler','Position',round(vecScreenRect/2));
	drawnow;
	movegui(h,'center');
	%global hAxis
	hAxis = axes();
	axis(hAxis,'equal');
	drawnow;
	set (h, 'WindowButtonMotionFcn', @(h,e) ''); %needs a placeholder for some reason...
	
	%pre-allocate
	intF = size(matAllIm,3);
	sLabels = struct;
	sLabels.X = nan(1,intF);
	sLabels.Y = nan(1,intF);
	sLabels.R = nan(1,intF);
	
	for intIm=1:intF
		%delte old
		cla(hAxis);
		
		%show im
		ptrCurFrame=imshow(imnorm(matAllIm(:,:,intIm)),'Parent', hAxis,'InitialMagnification','fit');
		hold(hAxis,'on');
		title(hAxis, sprintf('Image %d/%d; Left click=accept; right=reset center',intIm,intF));
		
		%wait until mouse is not pressed
		while getAsyncKeyState(1) || getAsyncKeyState(2)
			pause(0.01);
		end
		
		%get center+radius
		boolAccept = false;
		while ~boolAccept
			%delete old
			if exist('hCenter','var')
				delete(hCenter);
			end
			
			%get center
			[dblX,dblY]=ginput(1);
			
			%get radius
			hCenter = scatter(hAxis,dblX,dblY,'rx');
			
			%wait until button is released
			while getAsyncKeyState(1) || getAsyncKeyState(2)
				pause(0.01);
			end
			
			%plot radius and wait for click
			boolClicked = false;
			dblRadius = 0;
			hBorder = ellipse(hAxis,dblX,dblY,dblRadius,dblRadius,0,'Color','r','LineStyle','--');
			dblLocX = 0;
			dblLocY = 0;
			
			while ~boolClicked
				matLoc = hAxis.CurrentPoint;
				if dblLocX ~= matLoc(1,1) || dblLocY ~= matLoc(1,2)
					dblLocX = matLoc(1,1);
					dblLocY = matLoc(1,2);
					dblRadius = sqrt((dblX-matLoc(1,1)).^2 + (dblY-matLoc(1,2)).^2);
					
					delete(hBorder);
					hBorder = ellipse(hAxis,dblX,dblY,dblRadius,dblRadius,0,'Color','r','LineStyle','--');
				end
				
				if getAsyncKeyState(1)
					boolAccept = true;
					boolClicked = true;
					delete(hBorder);
					sLabels.X(intIm) = dblX;
					sLabels.Y(intIm) = dblY;
					sLabels.R(intIm) = dblRadius;
				end
				if getAsyncKeyState(2)
					boolClicked = true;
					delete(hBorder);
					
				end
				title(hAxis, sprintf('Image %d/%d; Left click=accept; right=reset center; X=%.1f, Y=%.1f, Radius=%.1f',intIm,intF,dblX,dblY,dblRadius));
				pause(0.01);
			end
		end
	end
	close(h);
end