% David Le and Andrew Hoang
% Complete script for applying short-term autocorrelation to doppler data

%% 
clear; close all; clc;
%% Data folder pathing

datafilepath ='UserSpecifiedPath/UserSpecifiedLocation';
direc = dir(datafilepath); 

%% parameters
overlap = 0.5;       % 90% overlap
windowSize_seconds = 2; % 2 seconds long
%%
all_heartrates = struct(); 
for nmx = 3%:size(direc, 1)

    % Load audio file and prepare variables
    fileChosen2 = direc(nmx).name;
    folderpath2 = fullfile(datafilepath, fileChosen2);

    [y, Fs] = audioread(fileChosen2); % y = amplitude

    newL = size(y, 1);       % length of amplitude (all rows in column #1)
    T = 1 / Fs;           % period of wave
    tZero = 0:T:newL*T-T;        % length of time domain
    y = y(:, 1);          % index the amplitude values into rows of a single column
    tOrig = 0:T:newL*T-T;    % length of time domain
    yOrig = y(:,1);

    % Filter audio using FIR filter
    NyqFreq = Fs/2;
    cutoffFreq = 1;
    cutoffFreq2 = 3;
    Wn = cutoffFreq/NyqFreq;
    Wn2 = cutoffFreq2/NyqFreq;
    Wn = [Wn Wn2];
    yBand = fir1(4, Wn);
    y2 = filtfilt(yBand, 1, y);

    %Define Boundaries to Create Window Size
    Nmin = (60*Fs)/190; % minimum sample index (searching window for both)
    Nmax = (60*Fs)/50;  % maximum sample index

    windowSize = Fs*windowSize_seconds; 

    total_steps = 1:1*Fs:size(tZero')-windowSize;
    HBR = []; % create empty vector
    finalHR = []; 

    % perform short-term autocorrelation
    for j = 1 :size(total_steps, 2)      % creating a range from the first window
        chunkStart = total_steps(j);
        chunkEnd = chunkStart+windowSize-1; % size to the end by increments of the noverlap value
        chunk1 = abs(y2(chunkStart:chunkEnd));  % create chunk1 to run through all the window samples
        normChunk = chunk1/max(chunk1);

        % Autocorrelation
        [autocor,lags] = xcorr(normChunk, 'unbiased');
        autocor(1:windowSize-1) = [];  % removing the unnecessary part
        lags(1:windowSize-1) = [];
        lagfinalInstHR = lags;
        lagfinalInstHR(Nmax:end) = [];
        lagfinalInstHR(1:Nmin) = [];
        autocor2 = autocor;
        autocor2(Nmax:end) = [];
        autocor2(1:Nmin) = [];
        [pks, locs] = findpeaks(autocor2);

        if isempty(pks)
            finalHR(j) = NaN;
        else
            [maxVal, maxLoc] = max(pks);
            HBR = (60*Fs) / lagfinalInstHR(locs(maxLoc));
            finalHR(j) = HBR;
        end
    end

    % Remove Outliers and NaN
    outIdx = isoutlier(finalHR);
    finalHR(outIdx) = NaN;

    all_heartrates(nmx-2).name = direc(nmx).name; 
    all_heartrates(nmx-2).InstHR = finalHR; 

end

%% Visualize heartrate estimation for each file

for i = 1:size(all_heartrates,2)
    figure(1); 
    plot(all_heartrates(i).InstHR,'r*'); 
    ylim([50,190]); 
    xlabel('Time (s)'); 
    ylabel('HR (bpm)'); 
    title(all_heartrates(i).name,'Interpreter','none'); 
    pause;


end
