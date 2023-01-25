% Andrew Hoang/David Le
% ahhoang@ncsu.edu/dle4@email.unc.edu
% 7/23/2021
% Short-Term Autocorrelation on Doppler Data

%% Housekeeping
clear; close all; clc;
cd('D:\Projects\Doppler Project\Heart Rate Detection'); 
datafilepath ='D:\Projects\Doppler Project\Heart Rate Detection\Dataset\Dataset';
addpath(genpath(datafilepath)); 

direc = dir(datafilepath);
datafilepath2 = 'D:\Projects\Doppler Project\Heart Rate Detection\TextData\TextData';
addpath(genpath(datafilepath2)); 
direc2 = dir(datafilepath2);


savefilefolder_1 = 'D:\Projects\Doppler Project\Heart Rate Detection\Results_1_28_22/';


[~, files] = xlsread('DUvsGT.xlsx');
files = string(files(2:end,:));

%% Load Data
total_window_count = 0; 
for i = 1:size(files, 1)
    
    fileChosen2 = files(i, 1);
    folderpath2 = fullfile(datafilepath, fileChosen2);
    filelist2 = dir(folderpath2);
    name2 = {filelist2.name};
    filenameDU = name2(~strncmp(name2, '.', 1));   % No files starting with '.'
    
    disp(fileChosen2) % check to see if filename matches
    disp(filenameDU)
    
    fileChosen = files(i,2);
    folderpath = fullfile(datafilepath2, fileChosen);
    filelist = dir(folderpath);
    name = {filelist.name};
    filenameLesley = name(~strncmp(name, '.', 1));   % No files starting with '.'
    load(fileChosen)
    
    disp(fileChosen) % check to see if filename matches
    disp(filenameLesley)
    
    [y, Fs] = audioread(fileChosen2); % y = amplitude 

    newL = size(y, 1);       % length of amplitude (all rows in column #1)
    T = 1 / Fs;           % period of wave
    tZero = 0:T:newL*T-T;        % length of time domain
    y = y(:, 1);          % index the amplitude values into rows of a single column
    tOrig = 0:T:newL*T-T;    % length of time domain
    yOrig = y(:,1);
    % maxT = max(tZero)

    %% Filter to Listen to Audio
    NyqFreq = Fs/2;
    cutoffFreq = 1;
    cutoffFreq2 = 3;
    Wn = cutoffFreq/NyqFreq;
    Wn2 = cutoffFreq2/NyqFreq;
    Wn = [Wn Wn2];
    yBand = fir1(4, Wn);
    y2 = filtfilt(yBand, 1, y);
%     y3 = filtfilt(yBand, 1, hilbert(yOrig));

    %% Define Boundaries to Create Window Size
    Nmin = (60*Fs)/190; % minimum sample index (searching window for both)
    Nmax = (60*Fs)/50;  % maximum sample index

    overlap = 0.5;       % 90% overlap
    windowSize = Fs * 2; % 2 seconds long

    %% Zero Pad Lesley's Data
    newNum = zeros(1, size(tZero, 2));
    newNum(round(result.*Fs)) = 1;

    %% Short-term Autocorrelation
    % total_steps = 1:round(windowSize*(1-overlap)):size(tZero')-windowSize;
    total_steps = 1:1*Fs:size(tZero')-windowSize;
    HBR = []; % create empty vector
    finalHBR = []; 
    finalInstHBR = []; 
    for j = 1 :size(total_steps, 2)      % creating a range from the first window 
        chunkStart = total_steps(j); 
        chunkEnd = chunkStart+windowSize-1; % size to the end by increments of the noverlap value
        chunk1 = abs(y2(chunkStart:chunkEnd));  % create chunk1 to run through all the window samples
        normChunk = chunk1/max(chunk1);

        %% Short-term Autocorrelation
        [autocor,lags] = xcorr(normChunk, 'unbiased');
        autocor(1:windowSize-1) = [];  % removing the unnecessary part
        lags(1:windowSize-1) = []; 
        lagfinalInstHBR = lags; 
        lagfinalInstHBR(Nmax:end) = [];
        lagfinalInstHBR(1:Nmin) = [];
        autocor2 = autocor;
        autocor2(Nmax:end) = [];
        autocor2(1:Nmin) = [];
        [pks, locs] = findpeaks(autocor2);

        if isempty(pks)
           finalHBR(j) = NaN; 
        else
            [maxVal, maxLoc] = max(pks);
            HBR = (60*Fs) / lagfinalInstHBR(locs(maxLoc));
            finalHBR(j) = HBR;
        end

    %% Find Difference between Heartbeats (Lesley's Data)
    chunkTime = tZero(chunkStart:chunkEnd);
    chunk2 = newNum(chunkStart:chunkEnd);
    [pksLesley, locsLesley] = findpeaks(chunk2);

        if isempty(pksLesley)
           finalInstHBR(j) = NaN;
        elseif numel(pksLesley) < 2
           finalInstHBR(j) = NaN;
        else
           instPeriod = diff(chunkTime(locsLesley)); 
           instHBR = (1./instPeriod) * 60;
           instHBR = mean(instHBR);
           finalInstHBR(j) = instHBR;
        end
    end
    
    avgData = finalHBR;
    
    %% Remove Outliers and NaN
    outIdx = isoutlier(avgData);
    avgData(outIdx) = NaN;

    %% Align Data
%     [avgData, finalInstHBR] = alignsignals(avgData,finalInstHBR);

    %% Find Difference Between Datasets
    avgData(avgData == 0) = NaN;
    finalInstHBR(finalInstHBR == 0) = NaN;

    diffVars = finalInstHBR - avgData;
    normVars = diffVars./finalInstHBR;
    newL4 = size(diffVars, 2); 
    TNew = (windowSize * (1-overlap)) / Fs;
    t4 = 0:TNew:newL4*TNew-TNew;
   
    NaNDiffVars = diffVars;
    NaNDiffVars(~isnan(NaNDiffVars)) = [];
    %NaNTotal = sum(isnan(NaNDiffVars));
    %[~, diffVarsTotal] = size(diffVars);
    %NaNPercent = (NaNTotal/diffVarsTotal) * 100;
    
    detectError = sum(diffVars>10);
    undetectError = sum(isnan(diffVars));
    %NaNTotal = detectError + undetectError;
    %NaNTotal = detectError;
    NaNTotal = undetectError;
    % numDiffVars = numel(diffVars)
    [~, diffVarsTotal] = size(diffVars);
    NaNPercent = (NaNTotal/diffVarsTotal) * 100;
    
    %%
    maxError = max(diffVars);
    minError = min(diffVars);
    
    absMaxError = max(abs(diffVars));
 
    diffVars2 = diffVars;
    diffVars2(isnan(diffVars)) = [];
    avgError = mean(diffVars2);
    avgAbsError = mean(abs(diffVars2));
    stdError = std(diffVars2);
    

    figure(1)
    stem(t4, diffVars)
    xlabel('Time (s)')
    ylabel('Error Difference (BPM)')
    title('Short-Term AC vs. Lesley')

    %% Plot Data Together
    figure(2)
    plot(t4, avgData, 'or');
    hold on
    plot(t4, finalInstHBR, '*b');
    set(gca,'FontSize',14)
    ylim([60 120])
    xlim([0 22])
    xlabel('Time (s)','FontSize',16)
    ylabel('Heart Rate (bpm)','FontSize',16)
%     title('Heart Rate Estimation','FontSize',18)
    legend('Algorithm', 'Human', 'Location', 'Southeast', 'FontSize',16)
    hold off
%     pause

    %% Average Heart Rates in Autocorrelation
    finalNewHBR = avgData;
    finalNewHBR(isnan(avgData)) = [];
    avgHBR = mean(finalNewHBR);
    period = 1 / (avgHBR / 60);

    %% Average Heart Rates in Lesley's Analysis
    NewInstHBR = finalInstHBR;
    NewInstHBR(isnan(finalInstHBR)) = [];
    avgInstHBR = mean(NewInstHBR);
    
    %% Mean Difference in Average Heart Rates
    meanAbsAvgDiff = abs(avgHBR - avgInstHBR);

    %% Calculate Heart Rate
    LOrig = size(yOrig, 1); % obtain original size of signal
    beatCountListen = numel(result) + 1;
    beatCountLesley = numel(result);
    durationSec = LOrig/Fs;
    durationMin = durationSec / 60;
    BPM = beatCountListen / durationMin;

     %% Output
%     fprintf('----------AVERAGE HBR---------\n');
%     fprintf('Listening:     %0.01f bpm \n', BPM);
%     fprintf('Short-term AC: %0.01f bpm \n', avgHBR);
%     fprintf('Lesley:        %0.01f bpm \n\n', avgInstHBR);
%     fprintf('----------ERROR---------\n');
%     fprintf('Average:  %0.01f %c %0.01f bpm \n', avgError, 177, stdError);
%     fprintf('Max:  %0.01f bpm \n', maxError);
%     fprintf('Min: %0.01f bpm \n\n', minError);
    
    %% Scaling and Retaining Data
    evalShortAC = avgData;
    evalLesley = finalInstHBR;
    evalShortAC(isnan(avgData)) = 0;
    evalLesley(isnan(finalInstHBR)) = 0;
    
    %% Correlation Coefficient vs. Varying Window Size (Plot)
    format long
    r2 = xcorr(evalShortAC,evalLesley, 0 , 'coeff');
    
    %% Find Difference Between Datasets (Normalized Data)
    newL5 = size(normVars, 2); 
    TNew = (windowSize * (1-overlap)) / Fs;
    t5 = 0:TNew:newL5*TNew-TNew;
    
    maxNormError = max(normVars) * 100;
    minNormError = min(normVars) * 100;
 
    diffNormVars2 = normVars;
    diffNormVars2(isnan(normVars)) = [];
    avgNormError = mean(diffNormVars2) * 100;
    avgAbsNormError = mean(abs(diffNormVars2)) * 100;
    stdNormError = std(diffNormVars2) * 100;

%     figure(3)
%     stem(t5, normVars)
%     xlabel('Time (s)')
%     ylabel('Error Difference (BPM)')
%     title('Short-Term AC vs. Lesley')

     %% Output (Normalized Data-needs fix)
%     fprintf('---------- NORMALIZED ERROR---------\n');
%     fprintf('Average:  %0.01f %c %0.01f bpm \n', avgNormError, 177, stdNormError);
%     fprintf('Max:  %0.01f bpm \n', maxNormError);
%     fprintf('Min: %0.01f bpm \n\n', minNormError);
  
%% Misc. Analysis
%absDiffVars = abs(diffVars');
%absDiffVars(isnan(absDiffVars)) = []
%pause

    %% Save Data

    newfile = split(name2,'.');
    newfile(2,:) = [];
    newfile = append(newfile, '_ShortAC.mat');
    savefilename = newfile{1};
    save([savefilefolder_1 '/' savefilename]);
    
%     clearvars -except DU Lesley datafilepath datafilepath2 files result r2 NaNTotal diffVars savefilefolder_1
    
%     clearvars -except DU Lesley filename datafilepath datafilepath2 files ...
%               result Fs y overlap tZero y2 Nmax Nmin newNum yOrig ...
%               winSizeSet diffVars r2

    total_window_count = total_window_count+size(diffVars,2); 
end
