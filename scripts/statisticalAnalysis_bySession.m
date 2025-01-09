% statisticalAnalysis_bySession.m
% Exploratory analysis of antibody A/B HALIP tasks
% False alarm rate, investment time, and accuracy
%
% Omkar N. Athavale; January 2025
% Updated: 8 Jan 2025

addpath('../src');
saveImgPath = '../results';

%% Prepare data
load('../data/dataImplanted_detectionConfidence_20230516')

% Prepare metrics
trialData = trialTab(:, {'trialId','sessionId','trialNumber', 'embedSignal', 'confidence','outcome','falseAlarm'});
trialData = join(trialData, sessionTab, 'Keys', 'sessionId', 'RightVariables', {'subjectId', 'daysAfterImplant','beforeAfter','antibodyId','antiBConc'});
trialData.antibodyId = double(cellfun(@(x) x == 'B', trialData.antibodyId));
trialData.confidenceFalseAlarm = nan(height(trialData), 1);
trialData.confidenceFalseAlarm(trialData.falseAlarm==1) = trialData.confidence(trialData.falseAlarm==1);

% masks to filter out unwanted rows
maskTrials_initial20 = trialData.trialNumber > 20;
maskTrials_noSignal = trialData.embedSignal==0;
maskTrials_postImplant = trialData.daysAfterImplant > 0;
maskTrials_antibodyB = trialData.antibodyId;
maskTrials_antibody005 = trialData.antiBConc == 0.05;

%% summarise by session
% set up test conditions
masks{1} = maskTrials_initial20&~maskTrials_antibodyB;  % A
masks{2} = maskTrials_initial20&maskTrials_antibodyB;   % B
masks{3} = maskTrials_initial20&maskTrials_postImplant; % A vs B
testFormulae = {'response~beforeAfter+(1|subjectId)', 'response~beforeAfter+(1|subjectId)', 'response~antibodyId+(1|subjectId)'};
responseVariables = {'falseAlarm', 'outcome', 'confidenceFalseAlarm'};

% initialise results matrices - note that the figure is the transpose of
% these matrices
fstats = [];
pvaluesModelParams = [];
r2 = [];
pairwise = [];
pvaluesPairwise = [];

% figure setup
h = figure('Name', ['T-B: ', strjoin(responseVariables, '-')]); % data
set(h, 'units', 'centimeters', 'position', [3 3 14 14]);
tiledlayout(3,3)

h2 = figure('Name', ['T-B: ', strjoin(responseVariables, '-')]); % residuals
set(h2, 'units', 'centimeters', 'position', [3 3 14 14]);
tiledlayout(3,3)

%iterate through formulae and response variables
for responseVarNum = 1:length(responseVariables)
    for questionNum = 1:length(masks)
        
        % summarise by session for valid data
        sessionSumm = groupsummary(trialData(masks{questionNum}, :), 'sessionId', 'mean', responseVariables{responseVarNum});
        sessionSumm.Properties.VariableNames{end} = 'response';
        sessionData = innerjoin(sessionTab(:, {'sessionId','subjectId','sessionIdSubject', 'daysAfterImplant','beforeAfter','accuracy','gender','antibodyId','antiBConc'}), sessionSumm, 'Keys', 'sessionId');
        
        % fit a general linear mixed effects model
        fittedModel = fitglme(sessionData, testFormulae{questionNum});
        
        % save model results to matrices and model object
        modelObjects{responseVarNum, questionNum} = fittedModel;
        fstats(:, questionNum, responseVarNum) = fittedModel.anova.FStat;
        pvaluesModelParams(:, questionNum, responseVarNum) = fittedModel.anova.pValue;
        r2(responseVarNum, questionNum) = fittedModel.Rsquared.Ordinary;
        
        % perform pairwise t-tests
        [~,pairwise(responseVarNum, questionNum)]=ttest2(sessionData{sessionData.beforeAfter==0, 'response'}, sessionData{sessionData.beforeAfter==1, 'response'});
        if isnan(pairwise(responseVarNum, questionNum))
            try
                [~,pairwise(responseVarNum, questionNum)] =ttest2(sessionData{strcmp(sessionData.antibodyId,'A'), 'response'}, sessionData{strcmp(sessionData.antibodyId,'B'), 'response'});
            catch
                [~,pairwise(responseVarNum, questionNum)] = NaN;
            end
            factorVar = 'antibodyId';
        else
            factorVar = 'beforeAfter';
        end
        
        % plot data and ttest results
        figure(h);
        nexttile;
        scatter(categorical(fittedModel.Variables{:, factorVar}), fittedModel.Variables.response, ...
            10, fittedModel.Variables.subjectId, 'filled', 'Marker', 'o', 'XJitter', 'density', 'XJitterWidth', 0.5);
        
        if pairwise(responseVarNum, questionNum) < 0.05/9 % Bonferroni correction
            sig = '*';
        else
            sig = '';
        end
        
        subtitle(sprintf('R^2 = %.2f; p = %.4f %s', r2(responseVarNum, questionNum), pairwise(responseVarNum, questionNum), sig));
        
        if strcmp(responseVariables{responseVarNum}, 'confidenceFalseAlarm')
            ylim([0 6])
            ylabel('Time (s)')
        else
            ylim([0 1])
            yticks(0:0.25:1)
            yticklabels(0:25:100)
            ylabel('Rate (%)')
        end
        if strcmp(factorVar, 'beforeAfter')
            xticklabels({'Before', 'After'})
        end
        
        % plot qqplots for residuals to assess model quality
        figure(h2);
        nexttile;

        qqplot(residuals(fittedModel),  )
        subtitle(sprintf('R^2 = %.2f', r2(responseVarNum, questionNum)));
                
    end
end