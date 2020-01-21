function loadBdf(subjectid, subjectname, pattern)
    % loadBdf() - Read bdf file, apply 0.5-90Hz band pass filter,
    %             and split into '.mat' files for each state based on 'EEG.event'
    %
    % Usage:
    %   >> loadBdf( 'name', '名前', 0 );  % Open dialog to generate '.mat' file based on selected file
    %
    % Inputs:
    %   subjectid   - [string] subject identifier
    %   subjectname - [string] subject name
    %   pattern     - [0/1] order of sound source to be presented
    %                    0: baseline1, HR, CD, baseline2
    %                    1: baseline1, CD, HR, baseline2
    %
    % See also:
    %   >> help eeg_checkset           % the EEG dataset structure

    % Confirm args
    if ~ischar(subjectid); error('subjectid must be char'); end
    if ~isnumeric(pattern); error('pattern must be numeric'); end
    if pattern == 0
        section = {'baseline1', 'HR', 'CD', 'baseline2'};
        trial = 'HRtoCD';
    else
        section = {'baseline1', 'CD', 'HR', 'baseline2'};
        trial = 'CDtoHR';
    end

    % Load bdf file
    [filename, filepath] = uigetfile('*.bdf');
    if ~ischar(filename) || ~ischar(filepath)
        error('no files selected');
    end
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_biosig(strcat(filepath, filename), 'channels', constants.BioSemiConstants.Electrodes, 'ref', 32);
    EEG = pop_reref(EEG, []);
    EEG.setname = subjectid;
    EEG.subjectname = subjectname;
    EEG.trial = trial;
    EEG = eeg_checkset(EEG);

    % Apply a 0.5-90Hz bandpass filter to the data
    EEG = pop_eegfiltnew(EEG, 0.5, 90);
    EEG = eeg_checkset(EEG);

    % Remove invalid events due to chattering
    previous = EEG.event(1).latency;
    invalidEvents = [];
    for index = 2:length(EEG.event)
        if EEG.event(index).latency - previous < constants.BioSemiConstants.Fs
            invalidEvents = [invalidEvents index];
        else
            previous = EEG.event(index).latency;
        end
    end
    EEG = pop_editeventvals(EEG, 'delete', invalidEvents);
    EEG = eeg_checkset(EEG);

    % Trim dataset and save the original before separation
    FULLEEG = pop_select(EEG, 'point', [1 constants.BioSemiConstants.Fs * 830]);
    FULLEEG.setname = char(strcat(subjectid, " - full"));
    FULLEEG = eeg_checkset(FULLEEG);
    [ALLEEG] = pop_newset(ALLEEG, FULLEEG, 0, 'gui', 'off');

    % Separate data for each state
    event = EEG.event;
    for index = 1:length(event)
        EEG = pop_editeventvals(EEG, 'delete', 1);
    end
    EEG = eeg_checkset(EEG);
    REFERENCE_EEG = EEG;
    for index = 1:length(section)
        first = event(index).latency;
        last = (first-1) + constants.BioSemiConstants.Fs*200;
        EEG = pop_select(REFERENCE_EEG, 'point', [first last]);
        EEG.setname = char(strcat(subjectid, " - ", section{index}));
        EEG = eeg_checkset(EEG);
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui', 'off');
    end

    % Create datasets for latter half (100sec) of each state
    for index = 1:length(section)
        EEG = pop_select(ALLEEG(constants.ProjectConstants.DataByStateIndex(index)), 'time', [100 200]);
        EEG.setname = char(strcat(subjectid, " - ", section{index}, " - second half"));
        EEG = eeg_checkset(EEG);
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui', 'off');
    end

    % Export data to mat file
    save(strcat(filepath, subjectid, '_', trial, '.mat'), 'ALLEEG', 'EEG', 'CURRENTSET', 'section');
end
