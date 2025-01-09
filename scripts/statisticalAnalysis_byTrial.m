% statisticalAnalysis_byTrial.m
% Exploratory analysis of antibody A/B HALIP tasks
% False alarm rate, investment time, and accuracy
%
% Omkar N. Athavale; January 2025
% Updated: 5 Jan 2025

addpath('../src');
saveImgPath = '../results';

%% Prepare data
load('../data/dataImplanted_detectionConfidence_20230516')

% Prepare metrics
trialData = trialTab(:, {'trialId','sessionId','trialNumber', 'embedSignal', 'confidence','outcome','falseAlarm'});
trialData = join(trialData, sessionTab, 'Keys', 'sessionId', 'RightVariables', {'sessionId','subjectId', 'daysAfterImplant','beforeAfter','antibodyId','antiBConc'});
trialData.antibodyId = double(cellfun(@(x) x == 'B', trialData.antibodyId));
trialData.confidenceFalseAlarm = nan(height(trialData), 1);
trialData.confidenceFalseAlarm(trialData.falseAlarm==1) = trialData.confidence(trialData.falseAlarm==1);

% masks to filter out unwanted rows
maskTrials_initial20 = trialData.trialNumber > 20;
maskTrials_noSignal = trialData.embedSignal==0;
maskTrials_postImplant = trialData.daysAfterImplant > 0;
maskTrials_antibodyB = trialData.antibodyId;
maskTrials_antibody005 = trialData.antiBConc == 0.05;

% test template
runTests = @(m, t, r) groupMeanSem(trialData(m, :),{'subjectId'}, {t}, {r} ,0);

%%
% Select variables and tests
responseVar = 'outcome';
testSets = {{'beforeAfter', 'beforeAfter', 'antibodyId', 'beforeAfter', 'beforeAfter', 'antibodyId'},
    [false, false, false, true, true, true]};


% begin tests
assert(length(testSets{1})==length(testSets{2}), 'testSets must be paired');

% figure setup
h = figure('Name', responseVar);
set(h, 'units', 'centimeters', 'position', [3 3 14 6]);
for i = 1:6
    ax(i) = subplot(2, 3, i);
    xlim([-0.5 1.5])
    
    if strcmp(responseVar, 'confidenceFalseAlarm')
        ylim([0 5])
        ylabel('Time (s)')
    else
        ylim([0 1])
        yticks(0:0.25:1)
        yticklabels(0:25:100)
        ylabel('Rate (%)')
    end
    hold on;
end

for currTest = 1:length(testSets{1})
    selectTest = testSets{1}{currTest};
    selectConc = testSets{2}(currTest);
    
    % mask_combinations
    masks{1} = maskTrials_initial20&~maskTrials_antibodyB;
    masks{2} = maskTrials_initial20&maskTrials_antibodyB;
    masks{3} = maskTrials_initial20&maskTrials_postImplant;
    
    if selectConc
        masks = cellfun(@(mm) (mm&maskTrials_antibody005), masks, 'UniformOutput', 0);
        nSubjects = 3;
    else
        nSubjects = 6;
    end
    
    [s, r, t] = runTests(masks{rem(currTest-1, 3)+1}, selectTest, responseVar);
    scatter(ax(currTest), eval(sprintf('s.%s', selectTest)), eval(sprintf('s.mean_%s', responseVar)), ...
        40, 'r', 'filled', 'Marker', 'square')
    plot(ax(currTest), [0 1], reshape(eval(sprintf("r.nanmean_%s'", responseVar)), nSubjects, [])', 'k')
    if eval(sprintf('s{2, "%s_pairwise_pval_0.0"}', responseVar)) < 0.05
        t{1} = [t{1},'*'];
    end
    subtitle(ax(currTest),t);%sprintf('%s A: p = %.4f', 
    xticks(ax(currTest),[0 1])
    if strcmp(selectTest, 'beforeAfter')
        xticklabels(ax(currTest), {'Before', 'After'})
    else
        xticklabels(ax(currTest), {'A', 'B'})
    end
    
end

saveHQsvg(h, sprintf('%s/%s_%s', saveImgPath, responseVar, datestr(datetime, 'yymmddHHMMSS')))
%%
assert(0)

[sumTable,resTable,strings]=groupMeanSem(trialData(maskA, :),{'subjectId'},{'beforeAfter'},{'falseAlarm', 'confidenceFalseAlarm', 'outcome'},0);
fprintf('%s\n', strcat(strings{:}))
[sumTable,resTable,strings]=groupMeanSem(trialData(maskTrials_initial20&maskTrials_antibodyB, :),{'subjectId'},{'beforeAfter'},{'falseAlarm', 'confidenceFalseAlarm', 'outcome'},0);
fprintf('%s\n', strcat(strings{:}))
[sumTable,resTable,strings]=groupMeanSem(trialData(maskTrials_initial20&maskTrials_postImplant, :),{'subjectId'},{'antibodyId', 'beforeAfter'},{'falseAlarm', 'confidenceFalseAlarm', 'outcome'},0);
fprintf('%s\n', strcat(strings{:}))


[sumTable,resTable,strings]=groupMeanSem(trialData(maskTrials_initial20&maskTrials_postImplant&maskTrials_antibody005, :),{'subjectId'},{'antibodyId'},{'falseAlarm', 'confidenceFalseAlarm', 'outcome'},0);
fprintf('%s\n', strcat(strings{:}))
[sumTable,resTable,strings]=groupMeanSem(trialData(maskTrials_initial20&~maskTrials_antibodyB&maskTrials_antibody005, :),{'subjectId'},{'beforeAfter'},{'falseAlarm', 'confidenceFalseAlarm', 'outcome'},0);
fprintf('%s\n', strcat(strings{:}))
[sumTable,resTable,strings]=groupMeanSem(trialData(maskTrials_initial20&maskTrials_antibodyB&maskTrials_antibody005, :),{'subjectId'},{'beforeAfter'},{'falseAlarm', 'confidenceFalseAlarm', 'outcome'},0);
fprintf('%s\n', strcat(strings{:}))


figure;
before = groupsummary(trialData(maskTrials_initial20&~maskTrials_antibody005&~maskTrials_postImplant, :), 'subjectId', {'mean', 'std'}, 'outcome');
after = groupsummary(trialData(maskTrials_initial20&~maskTrials_antibody005&maskTrials_postImplant, :), 'subjectId', {'mean', 'std'}, 'outcome');

errorbar(zeros(height(before), 1)+rand(height(before), 1), before{:, 'mean_outcome'}, before{:, 'std_outcome'}, 'Marker', 'o', 'LineStyle', 'none')
hold on
errorbar(ones(height(after), 1)+rand(height(after), 1), after{:, 'mean_outcome'}, after{:, 'std_outcome'}, 'Marker', 'o', 'LineStyle', 'none')

x = trialData{maskTrials_initial20&~maskTrials_antibody005, 'beforeAfter'}
y = trialData{maskTrials_initial20&~maskTrials_antibody005, 'confidenceFalseAlarm'}
boxplot(y, x)

