function ETO_ROICallback(hObject,eventdata,strLocation)
	
	%get globals
	global sETO;
	
	%check which slider
	dblVal = get(hObject,'Value');
	if strcmp(strLocation,'LT')
		%start x
		intType = 1;
	elseif strcmp(strLocation,'RT')
		%stop x
		intType = 13;
	elseif strcmp(strLocation,'LB')
		%start y
		intType = 2;
	elseif strcmp(strLocation,'RB')
		%stop y
		intType = 24;
	end
	
	%check where to assign
	if contains(hObject.Parent.Title,'Pupil')
		sETO.vecRectROI = updatePos(sETO.vecRectROI,dblVal,intType);
		
	elseif contains(hObject.Parent.Title,'Sync')
		sETO.vecRectSync = updatePos(sETO.vecRectSync,dblVal,intType);
	else
		error('impossibru!')
	end
	
	%update drawing
	
end
function vecRect = updatePos(vecRect,dblVal,intType)
	if intType < 5
		vecRect(intType) = dblVal;
	elseif intType == 13
		%val = vecRect(1) + vecRect(3)
		vecRect(3) = dblVal - vecRect(1);
	elseif intType == 24
		%val = vecRect(2) + vecRect(4)
		vecRect(4) = dblVal - vecRect(2);
	end
end