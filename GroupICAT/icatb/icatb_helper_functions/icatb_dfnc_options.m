function input_parameters = icatb_dfnc_options(varargin)
%% Feature selection options
%

icatb_defaults;
global DETRENDNUMBER;
global DFNC_DEFAULTS;

modulation_freq = '';
try
    modulation_freq = num2str(DFNC_DEFAULTS.SSB_SWPC.MODULATION_FREQUENCY);
catch
    
end

if (isempty(modulation_freq))
    modulation_freq = '0.015';
end

for ii = 1:2:length(varargin)
    if (strcmpi(varargin{ii}, 'covInfo'))
        covInfo = varargin{ii + 1};
    end
end



% Pre-processing

numParameters = 1;
inputParameters(numParameters).listString = 'Pre-processing';
optionNumber = 1;
% Option 1 of parameter 1
options(optionNumber).promptString = 'Detrend number';
options(optionNumber).answerString = char('0', '1', '2', '3');
matchedIndex = strmatch(num2str(DETRENDNUMBER), options(optionNumber).answerString, 'exact');
options(optionNumber).uiType = 'popup'; options(optionNumber).value = matchedIndex;
options(optionNumber).tag = 'tc_detrend'; options(optionNumber).answerType = 'numeric';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];

optionNumber = optionNumber + 1;
% Option 2 of parameter 1
options(optionNumber).promptString = 'Despike Timecourses?';
options(optionNumber).answerString = char('Yes', 'No');
options(optionNumber).uiType = 'popup'; options(optionNumber).value = 1;
options(optionNumber).tag = 'tc_despike'; options(optionNumber).answerType = 'string';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];

optionNumber = optionNumber + 1;
% Option 3 of parameter 1
options(optionNumber).promptString = 'Filter cutoff (Hz)';
options(optionNumber).answerString = '0.15';
options(optionNumber).uiType = 'edit'; options(optionNumber).value = 1;
options(optionNumber).tag = 'tc_filter'; options(optionNumber).answerType = 'numeric';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];


optionNumber = optionNumber + 1;
% Option 4 of parameter 1
options(optionNumber).promptString = 'Regress covariates';
options(optionNumber).answerString =  char('None', 'Select');
options(optionNumber).uiType = 'popup'; options(optionNumber).value = 1;
options(optionNumber).tag = 'tc_covariates'; options(optionNumber).answerType = 'string';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [];
options(optionNumber).enable = [];
options(optionNumber).callback = {@selectParams, covInfo};



optionNumber = optionNumber + 1;
% Option 5 of parameter 1
options(optionNumber).promptString = 'Remove subject FNC mean over time?';
options(optionNumber).answerString =  char('No', 'Yes');
options(optionNumber).uiType = 'popup'; options(optionNumber).value = 1;
options(optionNumber).tag = 'dfnc_mn_remov_yn'; options(optionNumber).answerType = 'string';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];

inputParameters(numParameters).options = options; % will be used in plotting the controls in a frame
clear options;


%% Dynamic FNC options
numParameters = numParameters + 1;
inputParameters(numParameters).listString = 'Dynamic FNC';
optionNumber = 1;
% Option 1 of parameter 2
options(optionNumber).promptString = 'Select dFNC method';
options(optionNumber).answerString = char('SWPC (Correlation)', 'L1 Reg. SWPC', 'Shared Trajectory', 'SSB + SWPC');
options(optionNumber).uiType = 'popup'; options(optionNumber).value = 1;
options(optionNumber).tag = 'method'; options(optionNumber).answerType = 'string';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];
options(optionNumber).callback = {@L1ControlCallback};

optionNumber = optionNumber + 1;
% Option 2 of parameter 2
options(optionNumber).promptString = 'Window size (TRs)';
options(optionNumber).answerString = DFNC_DEFAULTS.WINDOW_SIZE;
options(optionNumber).uiType = 'edit'; options(optionNumber).value = 1;
options(optionNumber).tag = 'wsize'; options(optionNumber).answerType = 'numeric';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];

% optionNumber = optionNumber + 1;
% % Option 3 of parameter 2
% options(optionNumber).promptString = 'Window Type';
% options(optionNumber).answerString = char('Tukey', 'Gaussian');
% options(optionNumber).uiType = 'popup'; options(optionNumber).value = 2;
% options(optionNumber).tag = 'window_type'; options(optionNumber).answerType = 'string';
% options(optionNumber).flag = 'delete';
% options(optionNumber).uiPos = [0.16 0.045];

optionNumber = optionNumber + 1;
% Option 3 of parameter 2
options(optionNumber).promptString = 'Window size (TRs) for Shared Traj';
options(optionNumber).answerString = DFNC_DEFAULTS.WINDOW_SIZE_STRAJECT;
options(optionNumber).uiType = 'edit'; options(optionNumber).value = 1;
options(optionNumber).tag = 'wsize_tmp'; options(optionNumber).answerType = 'numeric';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];

optionNumber = optionNumber + 1;
% Option 4 of parameter 2
options(optionNumber).promptString = 'Gaussian Window Alpha Value (TRs)';
options(optionNumber).answerString = '3';
options(optionNumber).uiType = 'edit'; options(optionNumber).value = 0;
options(optionNumber).tag = 'window_alpha'; options(optionNumber).answerType = 'numeric';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];

optionNumber = optionNumber + 1;
% Option 5 of parameter 2
options(optionNumber).promptString = 'Enter average sliding window in TRs. Set 0 for default dfnc';
options(optionNumber).answerString = '0';
options(optionNumber).uiType = 'edit'; options(optionNumber).value = 0;
options(optionNumber).tag = 'awsc'; options(optionNumber).answerType = 'numeric';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];

optionNumber = optionNumber + 1;
% Option 6 of parameter 2
options(optionNumber).promptString = 'Do you want to compute temporal variation of dfnc?';
options(optionNumber).answerString = char('No', 'Yes');
options(optionNumber).uiType = 'popup'; options(optionNumber).value = 1;
options(optionNumber).tag = 'tv_dfnc'; options(optionNumber).answerType = 'string';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];



optionNumber = optionNumber + 1;
% Option 7 of parameter 2
options(optionNumber).promptString = 'No. of repetitions (L1 regularisation)';
options(optionNumber).answerString = '10';
options(optionNumber).uiType = 'edit'; options(optionNumber).value = 1;
options(optionNumber).tag = 'num_repetitions'; options(optionNumber).answerType = 'numeric';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];
options(optionNumber).callback = {@L1ControlCallback};
options(optionNumber).enable = 'inactive';
options(optionNumber).visible = 'off';

optionNumber = optionNumber + 1;
% Option 8 of parameter 2
options(optionNumber).promptString = 'Modulation Frequency (Hz)';
options(optionNumber).answerString = modulation_freq;
options(optionNumber).uiType = 'edit'; options(optionNumber).value = 1;
options(optionNumber).tag = 'modulation_freq'; options(optionNumber).answerType = 'numeric';
options(optionNumber).flag = 'delete';
options(optionNumber).uiPos = [0.12 0.045];
options(optionNumber).callback = {@L1ControlCallback};
options(optionNumber).enable = 'inactive';
options(optionNumber).visible = 'off';


inputParameters(numParameters).options = options; % will be used in plotting the controls in a frame
clear options;

% store the input parameters in two fields
input_parameters.inputParameters = inputParameters;
input_parameters.defaults = inputParameters;


function selectParams(hObject, event_data, covInfo)
%% Select covariates of interest
%


if (get(hObject, 'value') == 2)
    
    if (~isempty(get(hObject, 'userdata')))
        covInfo = get(hObject, 'userdata');
    end
    
    icatb_defaults;
    global UI_FS;
    
    filesList = '';
    file_numbers = '';
    numOfDataSets = covInfo.numOfDataSets;
    
    try
        filesList = covInfo.filesList;
    catch
    end
    
    try
        file_numbers = covInfo.file_numbers;
    catch
    end
    
    if (isnumeric(file_numbers))
        file_numbers = num2str(file_numbers);
    end
    
    figTag = 'select_motion_params';
    
    % Delete figures that have tag
    if ~isempty(findobj(0, 'tag', figTag))
        delete(findobj(0, 'tag', figTag));
    end
    
    graphicsHandle = icatb_getGraphics('Select motion parameters', 'normal', figTag, 'on');
    set(graphicsHandle, 'menubar', 'none');
    set(graphicsHandle, 'CloseRequestFcn', {@figCloseCallback, hObject});
    
    % if ispc
    %     set(graphicsHandle, 'windowstyle', 'modal');
    % end
    
    % Offsets
    xOffset = 0.05; yOffset = 0.05;
    buttonHeight = 0.052; promptHeight = 0.052;
    editTextHeight = 0.05; editTextWidth = 0.7; yPos = 0.92;
    
    editTextPos = [xOffset, yPos - 0.5*yOffset - 0.5*promptHeight, editTextWidth, promptHeight];
    
    % Plot Text
    promptH = icatb_uicontrol('parent', graphicsHandle, 'units', 'normalized', 'style', 'text', ...
        'position', editTextPos, 'String', 'Select covariates for all subjects and sessions ...', 'fontsize', UI_FS - 1, ...
        'horizontalalignment', 'center');
    
    promptH = icatb_wrapStaticText(promptH);
    
    editTextPos = get(promptH, 'position');
    
    editTextHeight = 0.52;
    editTextPos(2) = editTextPos(2)  - yOffset - editTextHeight;
    editTextPos(4) = editTextHeight;
    
    % Plot edit
    editTextH = icatb_uicontrol('parent', graphicsHandle, 'units', 'normalized', 'style', 'edit', ...
        'position', editTextPos, 'String', filesList, 'fontsize', UI_FS - 1, ...
        'horizontalalignment', 'left', 'min', 0, 'max', 2, 'tag', 'regress_files');
    
    % Browse
    buttonPos = [editTextPos(1) + editTextPos(3) + xOffset, editTextPos(2) + 0.5*editTextPos(4) - 0.5*yOffset, 0.12, buttonHeight];
    buttonH = icatb_uicontrol('parent', graphicsHandle, 'units', 'normalized', 'style', 'pushbutton', ...
        'position', buttonPos, 'String', 'browse', 'fontsize', UI_FS - 1, 'horizontalalignment', 'center', 'tooltipstring', ...
        'Select files or paste files in the editbox ...', 'callback', {@selectFiles, editTextH});
    
    % Prompt
    editTextPos(2) = editTextPos(2) - 1.5*yOffset - promptHeight;
    editTextPos(4) = promptHeight;
    
    % Plot Text
    promptH = icatb_uicontrol('parent', graphicsHandle, 'units', 'normalized', 'style', 'text', ...
        'position', editTextPos, 'String', 'Enter scans to include. Leave empty to select all scans.', 'fontsize', UI_FS - 1, ...
        'horizontalalignment', 'center');
    
    promptH = icatb_wrapStaticText(promptH);
    
    editTextPos = get(promptH, 'position');
    
    editTextPos(1) = editTextPos(1) + editTextPos(3) + xOffset;
    editTextPos(3) = 0.15;
    editTextPos(2) = editTextPos(2) + (0.5*editTextPos(4) - 0.5*promptHeight);
    editTextPos(4) = promptHeight;
    
    % Plot edit
    editTextH = icatb_uicontrol('parent', graphicsHandle, 'units', 'normalized', 'style', 'edit', ...
        'position', editTextPos, 'String', file_numbers, 'fontsize', UI_FS - 1, ...
        'horizontalalignment', 'left', 'tag', 'file_numbers');
    
    % Plot done
    buttonWidth = 0.12;
    editTextPos(4) = buttonHeight;
    editTextPos(1) = 0.5 - 0.5*buttonWidth;
    editTextPos(2) = yOffset + 0.01;
    editTextPos(3) = buttonWidth;
    
    % Plot done
    icatb_uicontrol('parent', graphicsHandle, 'units', 'normalized', 'style', 'pushbutton', ...
        'position', editTextPos, 'String', 'Done', 'fontsize', UI_FS - 1, 'horizontalalignment', 'center', 'callback', ...
        {@doneCallback, graphicsHandle, covInfo, hObject});
    
end


function selectFiles(hObject, event_data, handles)
%% Select files
%

parentH = get(hObject, 'parent');

set(parentH, 'pointer', 'watch');

files = icatb_selectEntry('title', 'Select files ...', 'typeEntity', 'file', 'typeSelection', 'multiple', 'filter', '*.txt;*.dat');

if (~isempty(files))
    set(handles, 'string', files);
end

set(parentH, 'pointer', 'arrow');

function doneCallback(hObject, event_data, handles, covInfo, dropdownH)
%% Done callback
%

editH = findobj(handles, 'tag', 'regress_files');

files = strtrim(deblank(get(editH, 'string')));

if (isempty(files))
    error('Files are not selected');
end

if (size(files, 1) ~= covInfo.numOfDataSets)
    error(['Number of files doesn''t match the no. of data-sets (', num2str(covInfo.numOfDataSets), ')']);
end

fileNumH = findobj(handles, 'tag', 'file_numbers');
file_numbers = str2num(deblank(get(fileNumH, 'string')));
%file_numbers(file_numbers > covInfo.numOfDataSets) = [];

covInfo.file_numbers = file_numbers;
covInfo.filesList = files;

set(dropdownH, 'userdata', covInfo);

delete(handles);


function figCloseCallback(hObject, event_data, dropdownH)
%% Fig close callback

set(dropdownH, 'value', 1);
delete(hObject);


function L1ControlCallback(hObject, event_data, handles)


methodH = findobj(gcbf, 'tag', 'answermethod');
methodval = get(methodH, 'value');
strs = cellstr(get(methodH, 'string'));
repH = findobj(gcbf, 'tag', 'answernum_repetitions');
prompt_repH = findobj(gcbf, 'tag', 'prefixnum_repetitions');
modH = findobj(gcbf, 'tag', 'answermodulation_freq');
prompt_modH = findobj(gcbf, 'tag', 'prefixmodulation_freq');

winSizeH = findobj(gcbf, 'tag', 'answerwsize');
prompt_winSizeH = findobj(gcbf, 'tag', 'prefixwsize');

winSize2H = findobj(gcbf, 'tag', 'answerwsize_tmp');
prompt_winSize2H = findobj(gcbf, 'tag', 'prefixwsize_tmp');

aswcH = findobj(gcbf, 'tag', 'answerawsc');
prompt_aswcH = findobj(gcbf, 'tag', 'prefixawsc');

tv_dfncH = findobj(gcbf, 'tag', 'answertv_dfnc');
prompt_tv_dfncH = findobj(gcbf, 'tag', 'prefixtv_dfnc');

enableval = 'inactive';
methodSel = lower(strs{methodval});


if (methodval == 2)
    enableval = 'on';
end

set(prompt_winSizeH, 'visible', 'off');
set(winSizeH, 'visible', 'off');


set(prompt_winSize2H, 'visible', 'off');
set(winSize2H, 'visible', 'off');

set(prompt_repH, 'visible', 'off');
set(repH, 'visible', 'off');

set(prompt_modH, 'visible', 'off');
set(modH, 'visible', 'off');

set(aswcH, 'visible', 'off');
set(prompt_aswcH, 'visible', 'off');

set(tv_dfncH, 'visible', 'off');
set(prompt_tv_dfncH, 'visible', 'off');


if strcmpi(methodSel, 'swpc (correlation)')
    set(prompt_winSizeH, 'visible', 'on');
    set(winSizeH, 'visible', 'on');

    set(tv_dfncH, 'visible', 'on');
    set(prompt_tv_dfncH, 'visible', 'on');
    
    set(aswcH, 'visible', 'on');
    set(prompt_aswcH, 'visible', 'on');
    
end



if (strcmpi(methodSel, 'l1 reg. swpc'))
    set(prompt_winSizeH, 'visible', 'on');
    set(winSizeH, 'visible', 'on');

    set(prompt_repH, 'visible', 'on');
    set(repH, 'visible', 'on');
end


if (strcmpi(methodSel, 'ssb + swpc'))
    set(prompt_winSizeH, 'visible', 'on');
    set(winSizeH, 'visible', 'on');

    set(prompt_modH, 'visible', 'on');
    set(modH, 'visible', 'on');
end

if (strcmpi(methodSel, 'shared trajectory'))
    set(prompt_winSize2H, 'visible', 'on');
    set(winSize2H, 'visible', 'on');
end



