%% set params
strPath = 'D:\_Data\Exp2019-11-06\';
strVideoFile = 'EyeTrackingRaw2019-11-06_R1_MP1.mp4';
strParamsFile = 'EyeTrackingRaw2019-11-06_R1_MP1.mat';
strCSVFile = 'EyeTrackingRaw2019-11-06_R1_MP1.csv';

%% make figure
hFig = figure;
ptrAxesMainVideo = subplot(2,3,[1 2 4 5]);
ptrAxesSubVid1 = subplot(2,3,3);
ptrAxesSubVid2 = subplot(2,3,6);

%% load data
sCSV = loadcsv([strPath strCSVFile]);
sLoad = load([strPath strParamsFile]);
sET = sLoad.sET;
objVid = VideoReader([strPath strVideoFile]);

%% get data
intSizeX = objVid.Width;
intSizeY = objVid.Height;
dblTotDur = objVid.Duration;
dblFrameRate = objVid.FrameRate;
intTotFrames = objVid.NumberOfFrames;

%subsample
vecSubY = 1:sET.intSubSample:intSizeY;
vecSubX = 1:sET.intSubSample:intSizeX;

%csv
vecCenterX_CSV = zscore(sCSV.CenterX);
vecCenterY_CSV = zscore(sCSV.CenterY);

%% define variables from parameters
%build structuring elements
intRadStrEl = 2;
objSE = strel('disk',intRadStrEl,4);
%sync threshold luminance
dblThreshSync = sET.dblThreshSync;
intTempAvg = sET.intTempAvg;
%Pupil ROI: [x-from-left y-from-top x-width y-height]
vecRectROI = round(sET.vecRectROI);
vecKeepY = vecRectROI(2):(vecRectROI(2)+vecRectROI(4));
vecKeepX = vecRectROI(1):(vecRectROI(1)+vecRectROI(3));
%rebuild ROI
vecPlotRectX = [vecRectROI(1) vecRectROI(1) vecRectROI(1)+vecRectROI(3) vecRectROI(1)+vecRectROI(3) vecRectROI(1)];
vecPlotRectY = [vecRectROI(2) vecRectROI(2)+vecRectROI(4) vecRectROI(2)+vecRectROI(4) vecRectROI(2) vecRectROI(2)];

%Sync ROI: [x-from-left y-from-top x-width y-height]
vecRectSync = round(sET.vecRectSync);
vecSyncY = vecRectSync(2):(vecRectSync(2)+vecRectSync(4));
vecSyncX = vecRectSync(1):(vecRectSync(1)+vecRectSync(3));
%rebuild ROI
vecPlotSyncX = [vecRectSync(1) vecRectSync(1) vecRectSync(1)+vecRectSync(3) vecRectSync(1)+vecRectSync(3) vecRectSync(1)];
vecPlotSyncY = [vecRectSync(2) vecRectSync(2)+vecRectSync(4) vecRectSync(2)+vecRectSync(4) vecRectSync(2) vecRectSync(2)];

%blur width
dblGaussWidth = sET.dblGaussWidth;
if dblGaussWidth == 0
	gMatFilt = gpuArray(single(1));
else
	intGaussSize = ceil(dblGaussWidth*2);
	vecFilt = normpdf(-intGaussSize:intGaussSize,0,dblGaussWidth);
	matFilt = vecFilt' * vecFilt;
	matFilt = matFilt / sum(matFilt(:));
	gMatFilt = gpuArray(single(matFilt));
end
%thresholds
dblThreshReflect = sET.dblThreshReflect;
sglReflT = single(dblThreshReflect);
dblThreshPupil = sET.dblThreshPupil;
sglPupilT = single(dblThreshPupil);
dblPupilMinRadius = 2;
dblPupilMinPixSize = pi*dblPupilMinRadius^2;

%% pre-allocate
%save output
vecPupilTime = nan(1,intTotFrames);
vecPupilVidFrame = nan(1,intTotFrames);
vecPupilSyncLum = nan(1,intTotFrames);
vecPupilSyncPulse = nan(1,intTotFrames);
vecPupilCenterX = nan(1,intTotFrames);
vecPupilCenterY = nan(1,intTotFrames);
vecPupilMajorAxis = nan(1,intTotFrames);
vecPupilMinorAxis = nan(1,intTotFrames);
vecPupilOrientation = nan(1,intTotFrames);
vecPupilEccentricity = nan(1,intTotFrames);
vecPupilRoundness = nan(1,intTotFrames);

%% perform pupil detection
dblLastShow = -inf;
dblShowInterval = 10;
vecPrevLoc = [0;0];
objVid = VideoReader([strPath strVideoFile]); %recreate becase of NumberOfFrames... don't ask why...
boolInitDone = false;
intFrame = 0;
intSyncPulse = 0;
boolSyncHigh = false;
while hasFrame(objVid)
	%% read frame and add to buffer
	intFrame = intFrame + 1;
	matVidRaw = readFrame(objVid);
	matVidBuffer = matVidRaw;
	dblCurTime = objVid.CurrentTime;
	
	%select ROI
	matVid = imnorm(mean(single(matVidBuffer(:,:,1,:)),4));
	gMatVid = gpuArray(matVid(vecKeepY,vecKeepX));
	
	%find pupil
	[sPupil,im1,im2] = getPupil(gMatVid,gMatFilt,sglReflT,sglPupilT,objSE,dblPupilMinPixSize,vecPrevLoc);
	
	%get synchronization pulse window luminance
	dblSyncLum = mean(flat(matVidBuffer(vecSyncY,vecSyncX,1,end)));
	boolLastSyncHigh = boolSyncHigh;
	boolSyncHigh = dblSyncLum > dblThreshSync;
	if boolSyncHigh && (boolLastSyncHigh ~= boolSyncHigh)
		intSyncPulse = intSyncPulse + 1;
	end
	
	%extract parameters
	vecCentroid = sPupil.vecCentroid;
	dblMajAx = sPupil.dblMajAx;
	dblMinAx = sPupil.dblMinAx;
	dblOri = sPupil.dblOri;
	dblRoundness = sPupil.dblRoundness;
	dblEccentricity = sPupil.dblEccentricity;
	vecPrevLoc = vecCentroid;
	
	if (dblCurTime - dblLastShow > dblShowInterval) || dblMajAx == 0
		%update counter
		dblLastShow = dblCurTime;
		%show video with overlays
		imagesc(ptrAxesMainVideo,matVid);
		colormap(ptrAxesMainVideo,'grey');
		hold(ptrAxesMainVideo,'on');
		plot(ptrAxesMainVideo,vecPlotSyncX,vecPlotSyncY,'c--');
		plot(ptrAxesMainVideo,vecPlotRectX,vecPlotRectY,'b--');
		dblX = vecCentroid(1) + vecPlotRectX(1);
		dblY = vecCentroid(2) + vecPlotRectY(1);
		ellipse(ptrAxesMainVideo,dblX,dblY,dblMajAx/2,dblMinAx/2,deg2rad(dblOri)-pi/4,'Color','r','LineStyle','--');
		hold(ptrAxesMainVideo,'off');
		title(ptrAxesMainVideo,sprintf('Frame %d/%d (FR: %.3fs), T=%.3fs/%.3fs',intFrame,intTotFrames,dblFrameRate,dblCurTime,dblTotDur));
		
		%closed
		imagesc(ptrAxesSubVid1,im1);
		hold(ptrAxesSubVid1,'on');scatter(ptrAxesSubVid1,vecCentroid(1),vecCentroid(2),'xr');hold(ptrAxesSubVid1,'off');
		colormap(ptrAxesSubVid1,'grey');
		axis(ptrAxesSubVid1,'off');
		
		%regions
		imagesc(ptrAxesSubVid2,im2);
		hold(ptrAxesSubVid2,'on');scatter(ptrAxesSubVid2,vecCentroid(1),vecCentroid(2),'xr');hold(ptrAxesSubVid2,'off');
		colormap(ptrAxesSubVid2,'parula');
		axis(ptrAxesSubVid2,'off');
		drawnow;
		
		%check if we should pause
		%if dblCurTime > 4 && dblMajAx == 0
		%	title(ptrAxesSubVid2,'PAUSED')
		%	drawnow;
		%	pause;
		%end
	end
	
	%save output
	vecPupilTime(intFrame) = dblCurTime;
	vecPupilVidFrame(intFrame) = intFrame;
	vecPupilSyncLum(intFrame) = dblSyncLum;
	vecPupilSyncPulse(intFrame) = intSyncPulse;
	vecPupilCenterX(intFrame) = vecCentroid(1);
	vecPupilCenterY(intFrame) = vecCentroid(2);
	vecPupilMajorAxis(intFrame) = dblMajAx;
	vecPupilMinorAxis(intFrame) = dblMinAx;
	vecPupilOrientation(intFrame) = dblOri;
	vecPupilEccentricity(intFrame) = dblEccentricity;
	vecPupilRoundness(intFrame) = dblRoundness;
end

%% interpolate detection failures
%initial roundness check
indWrongA = vecPupilRoundness < 1 | vecPupilRoundness > 1.2;
indWrong1 = conv(indWrongA,ones(1,5),'same')>0;
vecAllPoints1 = 1:numel(indWrong1);
vecGoodPoints1 = find(~indWrong1);
vecTempX = interp1(vecGoodPoints1,vecPupilCenterX(~indWrong1),vecAllPoints1);
vecTempY = interp1(vecGoodPoints1,vecPupilCenterY(~indWrong1),vecAllPoints1);
%remove position outliers
indWrongB = abs(nanzscore(vecTempX)) > 4 | abs(nanzscore(vecTempY)) > 4;
%define final removal vector
indWrong = conv(indWrongA | indWrongB,ones(1,5),'same')>0;
vecAllPoints = 1:numel(indWrong);
vecGoodPoints = find(~indWrong);

%fix
vecPupilFixedCenterX = interp1(vecGoodPoints,vecPupilCenterX(~indWrong),vecAllPoints);
vecPupilFixedCenterY = interp1(vecGoodPoints,vecPupilCenterY(~indWrong),vecAllPoints);
vecPupilFixedMajorAxis = interp1(vecGoodPoints,vecPupilMajorAxis(~indWrong),vecAllPoints);
vecPupilFixedMinorAxis = interp1(vecGoodPoints,vecPupilMinorAxis(~indWrong),vecAllPoints);
vecPupilFixedOrientation = interp1(vecGoodPoints,vecPupilOrientation(~indWrong),vecAllPoints);
vecPupilFixedEccentricity = interp1(vecGoodPoints,vecPupilEccentricity(~indWrong),vecAllPoints);
vecPupilFixedRoundness = interp1(vecGoodPoints,vecPupilRoundness(~indWrong),vecAllPoints);

%% gather data
%check which frames to remove
intLastFrame = find(~(isnan(vecPupilRoundness) | vecPupilRoundness == 0),1,'last');
vecPupilTime = vecPupilTime(1:intLastFrame);
vecPupilVidFrame = vecPupilVidFrame(1:intLastFrame);
vecPupilSyncLum = vecPupilSyncLum(1:intLastFrame);
vecPupilSyncPulse = vecPupilSyncPulse(1:intLastFrame);
vecPupilCenterX = vecPupilCenterX(1:intLastFrame);
vecPupilCenterY = vecPupilCenterY(1:intLastFrame);
vecPupilMajorAxis = vecPupilMajorAxis(1:intLastFrame);
vecPupilMinorAxis = vecPupilMinorAxis(1:intLastFrame);
vecPupilOrientation = vecPupilOrientation(1:intLastFrame);
vecPupilEccentricity = vecPupilEccentricity(1:intLastFrame);
vecPupilRoundness = vecPupilRoundness(1:intLastFrame);

%put in struct
sPupil = struct;
sPupil.vecPupilTime = vecPupilTime;
sPupil.vecPupilVidFrame = vecPupilVidFrame;
sPupil.vecPupilSyncLum = vecPupilSyncLum;
sPupil.vecPupilSyncPulse = vecPupilSyncPulse;
%fixed
sPupil.vecPupilIsInterpolated = indWrong;
sPupil.vecPupilCenterX = vecPupilFixedCenterX;
sPupil.vecPupilCenterY = vecPupilFixedCenterY;
sPupil.vecPupilMajorAxis = vecPupilFixedMajorAxis;
sPupil.vecPupilMinorAxis = vecPupilFixedMinorAxis;
sPupil.vecPupilOrientation = vecPupilFixedOrientation;
sPupil.vecPupilEccentricity = vecPupilFixedEccentricity;
sPupil.vecPupilRoundness = vecPupilFixedRoundness;
%raw
sPupil.vecPupilRawCenterX = vecPupilCenterX;
sPupil.vecPupilRawCenterY = vecPupilCenterY;
sPupil.vecPupilRawMajorAxis = vecPupilMajorAxis;
sPupil.vecPupilRawMinorAxis = vecPupilMinorAxis;
sPupil.vecPupilRawOrientation = vecPupilOrientation;
sPupil.vecPupilRawEccentricity = vecPupilEccentricity;
sPupil.vecPupilRawRoundness = vecPupilRoundness;
%extra info
sPupil.strVideoFile = strVideoFile;
sPupil.sET = sET;

%% save file
%create filename
strVideoOut = strrep(strVideoFile,'Raw','Processed');
strVideoOut(find(strVideoOut=='.',1,'last'):end) = [];
strVideoOut = strcat(strVideoOut,'.mat');

%save
save([strPath strVideoOut],'sPupil');
fprintf('Saved data to %s (source: %s, path: %s) [%s]\n',strVideoOut,strVideoFile,strPath,getTime);

%% plot
figure
plot(sPupil.vecPupilTime,sPupil.vecPupilRawCenterX);
hold on
plot(sPupil.vecPupilTime,sPupil.vecPupilCenterX);
hold off
title(sprintf('Pupil x-pos, %s',strVideoFile),'Interpreter','none');
xlabel('Time (s)');
ylabel('Horizontal position (pixels)');
fixfig