% exploratory.m
% Exploratory analysis of antibody A/B HALIP tasks for
% false alarm rate, investment time, and accuracy
%
% Omkar N. Athavale; January 2025
% Updated: 5 Jan 2025

addpath('../src');
saveImgPath = '../results';

if ~exist(saveImgPath,'dir')
    mkdir(saveImgPath);
end
%% Prepare data
load('../data/dataImplanted_detectionConfidence_20230516')

% ignore first 20 trials per session (as in Schmack et al. 2021)and join data
trialTabFilt = trialTab(trialTab.trialNumber > 20, :);
joined = join(trialTabFilt, sessionTab, 'Keys', 'sessionId');

% Keep only trials with a signal, and with a valid false alarm determination
joinedSubset = joined(~joined.embedSignal & ~isnan(joined.falseAlarm),["trialId","sessionId","subjectId", "trialNumber","gender", "beforeAfter","antibodyId", "antiBConc", "trialStartTimestamp", "trialEndTimestamp", "confidence", "falseAlarm", "outcome"]);

% separate confidence for false alarms only
joinedSubset.confidenceFA = nan(height(joinedSubset), 1);
joinedSubset.confidenceFA(joinedSubset.falseAlarm==1) = joinedSubset.confidence(joinedSubset.falseAlarm==1);

% summarise mean and std dev by session and join to session data
sessionSummary = groupsummary(joinedSubset, {'sessionId'}, {'mean', 'std', 'sum', @numel}, {'confidenceFA', 'falseAlarm', 'outcome'});
sessionSummary = join(sessionSummary, sessionTab, 'Keys', 'sessionId');

% set antibodyId A to 0, and B to 1 for plotting
sessionSummary.antibodyId = cellfun(@(x) (x =='B'), sessionSummary.antibodyId);
%% plot by session

% Select response variable to plot
% options: 'accuracy', 'mean_confidenceFA', 'mean_falseAlarm'
plotVar = 'mean_confidenceFA';

% plotting options per response variable
plotOptions = table(...
    [0; 0; 0], ...
    [1;8;1], ...
    {'Accuracy (proportion)'; 'False Alarm \newline Confidence (s)'; ...
    'False alarm \newline rate (proportion)'}, {'' ; ''; ''}, ...
    'RowNames', {'accuracy', 'mean_confidenceFA', 'mean_falseAlarm'}, ...
    'VariableNames', {'min', 'max', 'label', 'errorVar'});

colours = {'b', 'r'}; % per group (antibodies)

% plot response variable against daysAfterImplant
h = figure;
set(h, 'units', 'cent', 'position', [3 3 10 8], 'name', plotVar)
hold on

% plot one series per subject
for subjectNum = unique(sessionSummary.subjectId)'
    selRows = sessionSummary(sessionSummary.subjectId == subjectNum, :); 
    xJitter = rand(height(selRows), 1).*0.2-0.1; % consistent jitter
    
    plot(selRows.daysAfterImplant+xJitter,selRows{:, plotVar}, ...
        'Color', colours{selRows.antibodyId(1)+1}, 'LineStyle', '-', ...
        'Marker', '.', 'MarkerSize', 10)
    
    % plot error bars if applicable
    if ~isempty(plotOptions{plotVar, 'errorVar'}{:})
        plot([selRows.daysAfterImplant+xJitter, selRows.daysAfterImplant+xJitter]',...
            [selRows{:, plotVar}+selRows{:, plotOptions{plotVar, 'errorVar'}{:}}, ...
            selRows{:, plotVar}-selRows{:, plotOptions{plotVar, 'errorVar'}{:}}]', ...
            'Color', colours{selRows.antibodyId(1)+1}, 'LineStyle', '-', 'LineWidth',1);
    end
end
% configure plot
ylim([plotOptions{plotVar, 'min'}, plotOptions{plotVar, 'max'}])
xlim([-30 30])
xlabel('Days after implant')
ylabel(plotOptions{plotVar, 'label'})

% configure legend per antibody
legLines = [line([0], [0], 'LineStyle', '-', 'Color', colours{1}), ...
    line([0], [0], 'LineStyle', '-', 'Color', colours{2})];
legend(legLines, {'A', 'B'}, 'Location', 'southoutside', 'Orientation', 'horizontal')

% save file
saveHQsvg(h, sprintf('%s/%s_%s', saveImgPath, plotVar, datestr(datetime, 'yymmddHHMMSS')))

%% visual check for normality between sessions within subjects
figure;
hold on;
tiledlayout('flow')
for subjectNum = unique(sessionSummary.subjectId)'
    selRows = sessionSummary(sessionSummary.subjectId == subjectNum & sessionSummary.daysAfterImplant < 0, :); 
    nexttile;
    qqplot(selRows.accuracy);
    axis square
    subtitle(num2str(subjectNum));
end

%% visual check for normality between sessions and subjects
subsetPreImplant = sessionSummary(sessionSummary.daysAfterImplant < 0, :); 
h = figure;
hold on;

subplot(2,3,1)
qqplot(subsetPreImplant.accuracy);
title('Accuracy')
axis square

subplot(2,3,2)
qqplot(subsetPreImplant.mean_falseAlarm);
title('False alarm rate')
axis square

subplot(2,3,3)
qqplot(subsetPreImplant.mean_confidenceFA);
title('Mean false alarm confidence')
axis square

subplot(2,3,4)
histogram(subsetPreImplant.accuracy);
xlabel('Accuracy (proportion)')

subplot(2,3,5)
histogram(subsetPreImplant.mean_falseAlarm);
xlabel('False alarm rate (proportion)')

subplot(2,3,6)
histogram(log(subsetPreImplant.mean_confidenceFA));
xlabel('False alarm confidence (s)')

saveHQsvg(h, sprintf('%s/%s_%s', saveImgPath, 'normality_preimplant', datestr(datetime, 'yymmddHHMMSS')))

%% within session trends


for sessionNum = unique(trialStartTimestamp.sessionId)'
sessionSubset = (joinedSubset.sessionId == sessionNum); 
plot(sessionSubset.st)
h = figure;
end