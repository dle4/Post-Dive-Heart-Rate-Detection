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

diffVarsNew2 = cell(12,1); 
diffVarsNew3 = cell(12,1); 
total_window_count = 0; 
for i = 1:size(files, 1)
    clearvars -except diffVarsNew2 diffVarsNew3 files datafilepath i datafilepath2 ...
        total_window_count
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
    %% Define Number of Window Sizes
    nWinSize = 12;
    diffVarsNew = cell(nWinSize, 1);
    %%
    for k = 1:nWinSize
        windowSize = Fs * k; % 2 seconds long

        %% Zero Pad Lesley's Data
        newNum = zeros(1, size(tZero, 2));
        newNum(round(result.*Fs)) = 1;

        %% Short-term Autocorrelation
        % total_steps = 1:round(windowSize*(1-overlap)):size(tZero')-windowSize;
        total_steps = 1:1*Fs:size(tZero')-windowSize;
        HBR = []; % create empty vector
        finalHBR = [];
        finalInstHBR = [];
        parfor j = 1 :size(total_steps, 2)      % creating a range from the first window
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


        %%
        
        diffVars2 = diffVars;
        diffVars2(isnan(diffVars)) = [];

        diffVarsNew2{k} = cat(1,diffVarsNew2{k}, diffVars2'); %save the error
        diffVarsNew3{k} = cat(1,diffVarsNew3{k}, diffVars'); % error with nans
        


    end

    total_window_count = total_window_count + size(diffVars,2); 
end

%%
% diffVarsNew2(1) = [];
figure(3)
boxplot(diffVarsNew2{1,1}, 'positions', 1)
hold on
boxplot(diffVarsNew2{2,1}, 'positions', 2)
boxplot(diffVarsNew2{3,1}, 'positions', 3)
boxplot(diffVarsNew2{4,1}, 'positions', 4)
boxplot(diffVarsNew2{5,1}, 'positions', 5)
boxplot(diffVarsNew2{6,1}, 'positions', 6)
boxplot(diffVarsNew2{7,1}, 'positions', 7)
boxplot(diffVarsNew2{8,1}, 'positions', 8)
boxplot(diffVarsNew2{9,1}, 'positions', 9)
boxplot(diffVarsNew2{10,1}, 'positions', 10)
boxplot(diffVarsNew2{11,1}, 'positions', 11)
boxplot(diffVarsNew2{12,1}, 'positions', 11)
set(gca,'Xtick', 0:nWinSize,'XTickLabel', 1:12);
xlabel('Window Size (s)')
ylabel('Differential Error (bpm)')
% title('Error vs. Window Size')
hold off

%%
for i = 1:size(diffVarsNew3,1)
    currdata = diffVarsNew3{i}; 
    perNaN(i) = sum(isnan(currdata))/size(currdata,1); 

end

figure; 
plot(perNaN*100, 'r*','LineWidth',1); 
set(gca,'FontSize',14)
% title('Percentage Failures'); 
xlabel('Window size (seconds)', 'FontSize',16); 
ylabel('% not detected', 'Fontsize',16); 
