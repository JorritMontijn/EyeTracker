function ETP_ROICallback(hObject,eventdata,strLocation)
	
	%get globals
	global sETP;
	global sFigETP;
	
	%check which slider
	dblVal = get(hObject,'Value');
	if strcmp(strLocation,'LT')
		%start x
		intType = 11;
	elseif strcmp(strLocation,'RT')
		%stop x
		intType = 13;
	elseif strcmp(strLocation,'LB')
		%start y
		intType = 12;
	elseif strcmp(strLocation,'RB')
		%stop y
		intType = 14;
	end
	
	%check where to assign
	if contains(hObject.Parent.Title,'Pupil')
		sETP.vecRectROI = updatePos(sETP.vecRectROI,dblVal,intType);
	elseif contains(hObject.Parent.Title,'Sync')
		sETP.vecRectSync = updatePos(sETP.vecRectSync,dblVal,intType);
	else
		error('impossibru!')
	end
	
	%redraw
	ETP_DetectEdit();
end
function vecRect = updatePos(vecRect,dblVal,intType)
	if intType < 5
		vecRect(intType) = dblVal;
	elseif intType == 11
		%val = vecRect(1) + vecRect(3)
		vecRect(3) = vecRect(3) + vecRect(1) - dblVal;
		vecRect(1) = dblVal;
	elseif intType == 12
		%val = vecRect(1) + vecRect(3)
		vecRect(4) = vecRect(4) + vecRect(2) - dblVal;
		vecRect(2) = dblVal;
	elseif intType == 13
		%val = vecRect(1) + vecRect(3)
		vecRect(3) = dblVal - vecRect(1);
	elseif intType == 14
		%val = vecRect(2) + vecRect(4)
		vecRect(4) = dblVal - vecRect(2);
	end
end