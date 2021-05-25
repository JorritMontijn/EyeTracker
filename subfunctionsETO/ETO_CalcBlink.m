function [dblBlinkiness,dblCenter] = ETO_CalcBlink(vecLum)
	
	%fill
	vecFilledData = fillfromtrough(vecLum);
	%invert
	vecHill = max(vecFilledData(:)) - vecFilledData;
	
	%estimate mean + sd
	vecX = (1:numel(vecHill))';
	vecM = vecHill(:).*vecX;
	dblMean = sum(vecM)/sum(vecHill);
	vecV = vecHill(:).*((vecX-dblMean).^2);
	dblSd = sqrt(sum(vecV)/sum(vecHill));
	
	%fit
	vecP0 = [dblMean dblSd max(vecHill) 0];
	sOpt = struct;
	sOpt.Display = 'off';
	[vecFitP]=lsqcurvefit(@getGaussian,vecP0,vecX,vecHill,[1 1 mean(vecHill) 0],[numel(vecHill) numel(vecHill) 1.5*max(vecHill) mean(vecHill)],sOpt);
	dblCenter = vecFitP(1);
	dblBlinkiness = vecFitP(2);
end
%{
global intWaitbarTotal;
intWaitbarTotal = size(matLum,2);
ptrProgress = parallel.pool.DataQueue;
afterEach(ptrProgress, @UpdateWaitbar);

tic
vecSelectPixels = round(size(sETC.matVid,2)*[1/7 6/7]);
matLum = squeeze(mean(sETC.matVid(:,vecSelectPixels(1):vecSelectPixels(2),1,:),2));
vecB = zeros(1,size(matLum,2));
vecC = zeros(1,size(matLum,2));
parfor i=1:size(matLum,2)
	[vecB(i),vecC(i)] = ETO_CalcBlink(matLum(:,i));
	send(ptrProgress, i);
end
toc

vecB = (max(vecB(:))-vecB);
vecB = vecB - median(vecB);
vecB(vecB<0)=0;
figure,plot(vecB);

%}