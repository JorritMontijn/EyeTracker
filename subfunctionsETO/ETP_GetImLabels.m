function sLabels = ETP_GetImLabels(matAllIm)
	%%
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
	sLabels.R2 = nan(1,intF);
	sLabels.A = nan(1,intF);
	
	for intIm=1:intF
		%delte old
		cla(hAxis);
		
		%show im
		ptrCurFrame=imshow(imnorm(matAllIm(:,:,intIm)),'Parent', hAxis,'InitialMagnification','fit');
		hold(hAxis,'on');
		
		%wait until mouse is not pressed
		while getAsyncKeyState(1) || getAsyncKeyState(2)
			pause(0.01);
		end
		
		%get center+radius
		boolAccept = false;
		while ~boolAccept
			%delete old
			title(hAxis, sprintf('Image %d/%d; Left click=set center',intIm,intF));
			if exist('hCenter','var')
				delete(hCenter);
			end
			
			%get center
			[dblX,dblY]=ginput(1);
			title(hAxis, sprintf('Image %d/%d; Left click=set inner radius; right=reset center',intIm,intF));
			drawnow;
			
			%get radius
			hCenter = scatter(hAxis,dblX,dblY,'rx');
			
			%wait until button is released
			while getAsyncKeyState(1) || getAsyncKeyState(2)
				pause(0.01);
			end
			
			%plot radius and wait for click
			boolClicked = false;
			dblRadius = 0;
			hBorder = ellipse(hAxis,dblX,dblY,dblRadius,dblRadius,0,'Color','r','LineStyle',':');
			dblLocX = 0;
			dblLocY = 0;
			
			while ~boolClicked
				matLoc = hAxis.CurrentPoint;
				if dblLocX ~= matLoc(1,1) || dblLocY ~= matLoc(1,2)
					dblLocX = matLoc(1,1);
					dblLocY = matLoc(1,2);
					dblRadius = sqrt((dblX-matLoc(1,1)).^2 + (dblY-matLoc(1,2)).^2);
					
					delete(hBorder);
					hBorder = ellipse(hAxis,dblX,dblY,dblRadius,dblRadius,0,'Color','r','LineStyle',':');
				end
				
				%set inner radius
				if getAsyncKeyState(1)
					delete(hBorder);
					sLabels.X(intIm) = dblX;
					sLabels.Y(intIm) = dblY;
					sLabels.R(intIm) = dblRadius;
					
					%wait until button is released
					while getAsyncKeyState(1) || getAsyncKeyState(2)
						pause(0.01);
					end
					
					%ask second radius & angle
					while ~boolClicked
						matLoc = hAxis.CurrentPoint;
						
						dblR2 = sqrt((dblX-matLoc(1,1)).^2 + (dblY-matLoc(1,2)).^2);
						dblA = atan((dblY-matLoc(1,2))/(dblX-matLoc(1,1)))+pi/2;
						delete(hBorder);
						hBorder = ellipse(hAxis,dblX,dblY,dblRadius,dblR2,dblA,'Color','r','LineStyle',':');
						
						%set outer radius
						if getAsyncKeyState(1)
							delete(hBorder);
							sLabels.R2(intIm) = dblR2;
							sLabels.A(intIm) = dblA;
							
							boolAccept = true;
							boolClicked = true;
						end
						if getAsyncKeyState(2)
							boolClicked = true;
							delete(hBorder);
							
						end
						title(hAxis, sprintf('Image %d/%d; Left click=set outer radius and angle; right=reset center; X=%.1f, Y=%.1f, R1=%.1f, R2=%.1f, A=%d',intIm,intF,dblX,dblY,dblRadius,dblR2,rad2deg(dblA)));
						pause(0.01);
					end
				end
				if getAsyncKeyState(2)
					boolClicked = true;
					delete(hBorder);
					
				end
				title(hAxis, sprintf('Image %d/%d; Left click=set inner radius; right=reset center; X=%.1f, Y=%.1f, Radius=%.1f',intIm,intF,dblX,dblY,dblRadius));
				pause(0.01);
			end
		end
	end
	close(h);
end