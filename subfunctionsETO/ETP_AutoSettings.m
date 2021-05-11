function ETP_AutoSettings(hObject,eventdata)
	
	%get globals
	global sETP;
	global sFigETP;
	global ETP_Fit;
	
	%% lock gui
	SC_lock(sFigETP);
	
	%% check bounds
	intTempAvg = str2double(sFigETP.sHandles.TempAvg.String);
	if ~isnumeric(intTempAvg) || intTempAvg < 1
		sFigETP.sHandles.TempAvg.String = '1';
	elseif intTempAvg > sETP.intS
		sFigETP.sHandles.TempAvg.String = num2str(sETP.intS);
	end
	
	%% get values
	sHandles = sFigETP.sHandles;
	dblGain = str2double(sFigETP.sHandles.Gain.String);
	dblGamma = str2double(sFigETP.sHandles.Gamma.String);
	intTempAvg = str2double(sFigETP.sHandles.TempAvg.String);
	dblGaussWidth = str2double(sFigETP.sHandles.Blur.String);
	dblThreshReflect = str2double(sFigETP.sHandles.ReflLum.String);
	dblThreshPupil = str2double(sFigETP.sHandles.PupLum.String);
	
	%save to original vars
	dblManualGain = dblGain;
	dblManualGamma = dblGamma;
	intManualTempAvg = intTempAvg;
	dblManualGaussWidth = dblGaussWidth;
	dblManualThreshReflect = dblThreshReflect;
	dblManualThreshPupil = dblThreshPupil;
	
	%% get or assign labels; this also assigns the required globals for ETP_FitWrapper
	sLabels = ETP_SetLabels();
	
	%% perform initial grid search
	%wait bar
	ptrWaitbarHandle = waitbar(0, 'Running grid search ...');
	ptrWaitbarHandle.Name = 'Grid search';
	
	%prep data
	vecGainGamma = logspace(-0.2,0.5,4);
	intNumGG = numel(vecGainGamma);
	vecFrAvg = 2;
	intNumAv = numel(vecFrAvg);
	vecBlur = 0:0.5:2;
	intNumB = numel(vecBlur);
	vecReflT = linspace(70,250,4);
	intNumRT = numel(vecReflT);
	vecPupilT = linspace(10,80,7);
	intNumPT = numel(vecPupilT);
	
	vecX = zeros(1,6);
	ETP_Fit.vecOrigX = ones(size(vecX));
	ETP_Fit.vecPrevX = -ones(size(vecX));
	intP = intNumGG * intNumAv * intNumB * intNumRT * intNumPT;
	intC = 0;
	matE = ones(intNumGG, intNumAv, intNumB, intNumRT, intNumPT)*inf;
	for intGG=1:intNumGG
		dblGG = vecGainGamma(intGG);
		for intAv=1:intNumAv
			dblAvg = vecFrAvg(intAv);
			for intB=1:intNumB
				dblB = vecBlur(intB);
				for intRT=1:intNumRT
					dblRT = vecReflT(intRT);
					for intPT=1:intNumPT
						dblPT = vecPupilT(intPT);
						if dblPT > dblRT
							continue;
						end
						
						%run
						vecX = [dblGG dblGG dblAvg dblB dblRT dblPT];
						dblE = ETP_FitWrapper(vecX,false);
						matE(intGG, intAv, intB, intRT, intPT) = dblE;
						
						%waitbar
						intC = intC + 1;
						waitbar(intC/intP, ptrWaitbarHandle,sprintf('Running grid search... Finished %d/%d',intC,intP));
					end
				end
			end
		end
	end
	
	%% get best result
	waitbar(intP/intP, ptrWaitbarHandle,sprintf('Running grid search... Finished %d/%d',intP,intP));
	%run manual settings
	vecManualX = [dblManualGain dblManualGamma intManualTempAvg dblManualGaussWidth dblManualThreshReflect dblManualThreshPupil];
	dblManualE = ETP_FitWrapper(vecManualX,false);
	
	%get best from grid search
	delete(ptrWaitbarHandle);
	[dblMinE,intI]=min(matE,[],'all','linear');
	[intMinGG,intMinAv,intMinB,intMinRT,intMinPT]=ind2sub(size(matE),intI);
	
	dblGain = vecGainGamma(intMinGG);
	dblGamma = vecGainGamma(intMinGG);
	intTempAvg = vecFrAvg(intMinAv);
	dblGaussWidth = vecBlur(intMinB);
	dblThreshReflect = vecReflT(intMinRT);
	dblThreshPupil = vecPupilT(intMinPT);
	vecBestX = [dblGain dblGamma intTempAvg dblGaussWidth dblThreshReflect dblThreshPupil];
	dblAutoE = ETP_FitWrapper(vecBestX,false);
						
	%figure,plot(matE(:))
	%compare manual & auto
	if dblManualE < dblAutoE
		vecX0 = vecManualX;
	else
		vecX0 = vecBestX;
	end
	
	%% find minimum
	if sFigETP.boolAutoRun
		sOpts = [];
		ptrDlg = helpdlg('Running optimization search','Minimizing error');
	else
		sOpts = optimset('PlotFcns','optimplotfval');
	end
	%try bayesopt?
	ETP_Fit.vecOrigX = vecX0;
	ETP_Fit.vecPrevX = zeros(size(vecX0));
	vecScaledX = fminsearch(@ETP_FitWrapper,ones(size(vecX0)),sOpts);
	vecFitX = vecScaledX.*vecX0;
	
	if sFigETP.boolAutoRun
		close(ptrDlg);
	end
	
	%% assign new values
	sFigETP.sHandles.Gain.String = sprintf('%.2f',vecFitX(1));
	sFigETP.sHandles.Gamma.String = sprintf('%.2f',vecFitX(2));
	sFigETP.sHandles.TempAvg.String = sprintf('%.2f',vecFitX(3));
	sFigETP.sHandles.Blur.String = sprintf('%.2f',vecFitX(4));
	sFigETP.sHandles.ReflLum.String = sprintf('%.2f',vecFitX(5));
	sFigETP.sHandles.PupLum.String = sprintf('%.2f',vecFitX(6));
	
	%% redraw
	ETP_DetectEdit();
	
	%% unlock
	SC_unlock(sFigETP);
	
	
end