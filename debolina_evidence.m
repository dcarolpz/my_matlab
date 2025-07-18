 % code debolina asked for
%  -----> Pipeline in NIS001.eeg
% dcaro
% 28/08/2024

% By: Diego Caro López 
% Finished: 03-Sep-2024

% This code's objective is to display the results from 
% Step2_PreProcessICAandDIPFIT, by Alex Steele in a nicely manner. The 
% development of this code required the creation of the function 
% dcaro_stacked(), which now has become very robust. Originally, it was 
% inspired on DH_Raster(), but I wanted to add some features, like scale
% and to be able to use a TiledLayout with it. So now, dcaro_stacked is
% going to be the main function I'll use to generate stacked EEG plots and
% I hope to share it with other members of the lab, so that I can leave a 
% mark while I'm here.
%     Laboratory for Non-Invasive Brain Machine Interface Systems 2024.

%% 1. Loading EEG struct that contains events only to get latencies.
% clear 
clc 
% close all

% Import EEGs structs/data 
% This section requires to have a folder named 'EEGs' in the current 
% directory, or added to the path. I have it in my Current Folder, so no
% addpath() needed. This 'EEGs' folder must contain 6 .mat files, each of
% them saving the variable EEG.data after each preprocessing step in the
% code from Alex Steele. 

% Note that I needed to save some extra info. from the EEGs, thus, for the 
% raw data, I saved the whole EEG struct :). 

allFiles = dir('EEGs');
allFiles = allFiles([allFiles.isdir] == 0);
for i = 1:length(allFiles)
    load(fullfile(cd,'EEGs',allFiles(i).name))
end
clear i

% Movements:
%   'Rest': Resting state.
%   'LPF': Left Plantar Flexion.
%   'RPF': Right Plantar Flexion.
%   'LKE': Left Knee Extension. 
%   'RKE': Right Knee Extension.

% Preprocessing steps:
% 1. Raw.
% 2. H-infinity.
% 3. Bandpass.
% 4. ASR.
% 5. CAR.
% 6. Zapline.

%% 2. Extracting events and adjusting data
% dcaro_stacked() uses the function pop_select, from EEGLAB, which requires
% to have a EEG struct as an input. But thats no problem, because
% specifying 'fs' and 'labels' as name-value arguments, the function
% generates all the other fields needed for the EEG struct. Here I'm
% creating this variables. 

% Also, we are analyzing 4 different movements, so we want a window for
% each of them. Windows are created based on the latencies for the events
% in the EEG_raw struct. I did this part manually bc events have literally
% nothing in common to work with in MATLAB.

fs = EEG_raw.srate;
events = {121040, EEG_raw.event.latency; 'RPF only x 5',EEG_raw.event.type;
    'Comment', EEG_raw.event.code}';
my_events = cell(3,4);
my_events(:,1) = events(2:4,1);
my_events(:,2) = events(23:25,1);
my_events(:,3) = events(36:38,1);
my_events(:,4) = events(50:52,1);

% We want to add a nice title to the figures, so here we are creating a
% cell array that contains the name of the files sorted by date. 

[~,idx] = sort([allFiles.datenum]);
allFiles = allFiles(idx);
names = {allFiles.name};

% We also need the EOG to be displayed dimed at the bottom of each figure,
% so this part adds the EOG to a cell array containing the EEG.data after
% each preprocessing step. 

steps = {EEG_raw.data;EEG_Hinf;EEG_bp;EEG_ASR;EEG_CAR;EEG_zapline};
for i = 1:6
    steps{i} = [steps{i}; EEG_raw.EOG];
end

% As mentioned before, labels are needed so that what we are doing here,
% also including those for the EOG. 

labels = {EEG_raw.chanlocs.labels};
labels_eog = {'EOGU'; 'EOGD'; 'EOGL'; 'EOGR'};
for i = 29:32
    labels{i} = labels_eog{i-28};
end
moves = ["RPF" "LPF" "RKE" "LKE"];

%% Now generating figures
% This section generates a tile for each step of the preprocessing.
% A single figure (TiledLayout) is created for each movement.

% For every movement, the start and end of a single repetition is marked
% with a red xline. 

% The syntax for dcaro_stacked is the following for each iteration:
% dcaro_stacked(data,tile,fs,labels,window,scale,color,scalecol,eog).
        % However, anyone can also try without scale, color and scalecol.
% Some of the arguments are hardcoded but idc. 

close all
for i = 1 % iterating over movement type
    figure
    x = tiledlayout(2,3,'TileSpacing','loose','TileIndexing','rowmajor');
    for j = 6 % iterating over preprocessing steps
        nexttile(j);
        name = names{j}(1:end-4);
        dcaro_stacked(steps{j},'tile',j,'fs',fs,'labels',labels, ...
            'win',[my_events{1,i} my_events{3,i}+5*fs]/fs,'scale',100, ...
            'color','k','scalecol','r','ref',29:32)
        title(name + ". Window: [" + num2str(my_events{1,i}/fs) + " - " + ...
            num2str(my_events{3,i}/fs) + "]s.",'interpreter','none')
        xline(my_events{2,i}/fs,'r','Start','LineWidth',2,'FontSize',10,'FontWeight','bold')
        xline(my_events{3,i}/fs,'r','End','LineWidth',2,'FontSize',10,'FontWeight','bold')
    end
    title(x,moves(i) + " - Window: ["+ num2str((my_events{3,i}-my_events{1,i})/fs) +"]s")
end

%% Figures individually
% This section generates 6 figures for every movement, one for each  
% preprocessing step.

for i = 1 % iterating over movement type
    for j = 6 % iterating over preprocessing steps
        name = names{j}(1:end-4);
        dcaro_stacked(steps{j},'fs',fs,'labels',labels,'win', ...
            [my_events{1,i} my_events{3,i}+5*fs]/fs, ...
            'scale',100, ...
            'color','k','scalecol','r','ref',29:32)
        title(name + ". Window: [" + num2str(my_events{1,i}/fs) + " - " + ...
            num2str(my_events{3,i}/fs) + "]s.",'interpreter','none')
        xline(my_events{2,i}/fs,'r','Start','LineWidth',2,'FontSize',10,'FontWeight','bold')
        xline(my_events{3,i}/fs,'r','End','LineWidth',2,'FontSize',10,'FontWeight','bold')
    end
end
