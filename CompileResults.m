clear; close all; 
path1 = 'D:\Projects\Doppler Project\Heart Rate Detection\Results_1_28_22'; 
cd(path1)
direc_s = dir(path1); 
%%
count = 1; 
data = struct;
for nmx = 3:size(direc_s,1)
    
    sf = load(direc_s(nmx).name); 
    data(count).name = sf.filename;
    data(count).error_all = sf.diffVars'; 
    data(count).error = sf.diffVars2';
    data(count).abs_error = abs(sf.diffVars2)';
    data(count).NaNtotal = sum(isnan(sf.diffVars)); 
    data(count).totalWindows = size(sf.diffVars,2); 
    data(count).avgData = sf.avgData;
    data(count).GTdata = sf.finalInstHBR; 
    count = count+1; 
end

%%
sorted{1} = [1,2,4,6,7,8,9,20]; %lowrest
sorted{2} = [3,5];  %lowflex
sorted{3} = [13,14,21];  %highrest
sorted{4} = [10,11,12,15,16,17,18,19]; %highflex

nans = 0; 
allwindows = 0; 
all_errors = {}; 
all_bpm = {}; 

all_avg_data = []; 
all_gt_data = []; 
for nmx = 1:size(sorted,2)
s = data(sorted{nmx}); 
all_error = []; 
all_avg_data = []; 
all_gt_data = []; 
    for i = 1:size(s,2)
        all_error = cat(1,s(i).abs_error,all_error); 
        
        nans = nans+s(i).NaNtotal; 
        allwindows = allwindows+s(i).totalWindows;

        all_avg_data = cat(1,all_avg_data,s(i).avgData');
        all_gt_data = cat(1,all_gt_data,s(i).GTdata');

        all_gt_data(isnan(all_avg_data))= []; 
        all_avg_data(isnan(all_avg_data)) = []; 
        all_avg_data(isnan(all_gt_data)) = []; 
        all_gt_data(isnan(all_gt_data))= []; 
        
    end
    all_errors{nmx}= all_error;
    all_bpm{nmx} = [all_avg_data,all_gt_data]; 
end

percentage  = nans/allwindows;

sof = [];
for i = 1:4
    sof = cat(1,sof,all_errors{i});
end

