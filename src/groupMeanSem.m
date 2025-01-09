function [sumTable,resTable,strings,stats]=groupMeanSem(data,betweenFac,withinFac,dataVars,minPoints,varargin)
% this helper function computes data means and sems across one or several
% within-factors (e.g. experimental manipulation), corrects for
% between-factor variance (e.g. session, subject) and for and computes
% statistics (repeated-measures ANOVA: main effect and post-hoc
% comparisons)
%
% KS, January 2021, Cold Spring Harbor, schmack@cshl.edu
%
% inputs
% data      - table with variables containing variables coding between factor (e.g. subject),
%             within factor (e.g. ketamine/vehicle), as well as data
%             variables (e.g. false alarm confidence)
% betweenFac - cell with string denoting the name of the between factor
% withinFac  - cell with string(s) denoting the name(s) of the within
%              factor(s)
% dataVar    - cell with string(s) denotin the name(s) of the data
%              variables
% varargin   - see below for options
% 
% outputs
% sumTable   - table with group means and sem (corrected for between factor
%              variance)
% resTable   - table with single data points used for group mean (both
%              uncorrected and corrected for between factor variance), also
%              includes p-values for post-hoc comparisons between levels of
%              within factors
% strings    - string with F-value and p-value for main effect of within
%              factors

%% parse inputs
p=inputParser;
p.addRequired('data',@istable);
p.addRequired('betweenFac',@iscell);
p.addRequired('withinFac',@iscell);
p.addRequired('dataVars',@iscell);
p.addRequired('minPoints',@isscalar);
p.addParameter('withinLevels',[]);%which levels will be considered for correcting to group mean
p.addParameter('statistics',true);%whether or not ANOVA is computed (saves time if false)

p.parse(data,betweenFac,withinFac,dataVars,minPoints,varargin{:})
if isempty(p.Results.withinLevels)
    withinLevels=unique(data{:,withinFac});
else
    withinLevels=p.Results.withinLevels;
end

%% calculates group mean and sem removing between subject variance from Cosineau
resTable=grpstats(data,[withinFac,betweenFac],{'nanmean'},'DataVars',dataVars);
excludeLines=unique(resTable{resTable.GroupCount<minPoints,betweenFac});
resTable(ismember(resTable{:,betweenFac},excludeLines),:)=[];

% calculate grand mean for correction
if length(withinFac)<2
    errorIdx=ismember(resTable{:,withinFac},withinLevels);
    errorTable=grpstats(resTable(errorIdx,:),betweenFac,{'nanmean'},'DataVars',strcat('nanmean_',dataVars));
    grandnanmean=nanmean(errorTable{:,strcat('nanmean_nanmean_',dataVars)},1);
else
    errorTable=grpstats(resTable,betweenFac,{'nanmean'},'DataVars',strcat('nanmean_',dataVars));
    grandnanmean= nanmean(errorTable{:,strcat('nanmean_nanmean_',dataVars)},1);
end

% set up table for post hoc comparisons ANOVA
if p.Results.statistics
    levels=unique(resTable{:,withinFac});
    multcompareTable=table(levels,'VariableNames',[withinFac]);%2.1f);
end

for vars=1:length(dataVars) %% loop over data variables
    % remove subject nanmean and add grand nanmean (Cosineau 2005), add
    % corrected data to resTable
    correctedVar=nan(height(resTable),1);
    for s=1:height(errorTable)        
        resIdx=ismember(resTable{:,betweenFac{1}},errorTable{:,betweenFac}(s));
        correctedVar(resIdx,1)=resTable{resIdx,strcat('nanmean_',dataVars{vars})}-errorTable{s,strcat('nanmean_nanmean_',dataVars{vars})}+grandnanmean(vars);%Cosineau
    end
    resTable=[resTable,table(correctedVar,'VariableNames',strcat('corrected_nanmean_',dataVars(vars)))];

    %%run repeated measures ANOVA
    if p.Results.statistics
        % set up data table in the format required by matlab
        dataTable=table;
        for l=1:length(levels)
            level=levels(l);
            joinTable=resTable(resTable{:,withinFac}==level,['nanmean_' dataVars{vars}]);
            dataTable=[dataTable,joinTable];
            dataTable.Properties.RowNames={};
            dataTable.Properties.VariableNames{end}=sprintf('m%02.0f',l);
        end
        % set up factor table in the formart required by matlab
        factorTable=table(categorical(levels),'VariableNames',withinFac);%make levels categorical for ANOVA p-values, otherwise a regression is calculated
        
        % perform repeated measures Anova
            rm=fitrm(dataTable,sprintf('m%02.0f-m%02.0f~1',1,length(levels)),'WithinDesign',factorTable);
            ranovatblb=ranova(rm,'WithinModel',withinFac{1});
            
            % print main effect into strings
            if ranovatblb.pValue(3)>=0.001
                strings{vars,1}=sprintf('  F(%d,%d)=%2.1f, p=%2.3f%s',ranovatblb.DF(3),ranovatblb.DF(4),ranovatblb.F(3),ranovatblb.pValue(3));
            else
                strings{vars,1}=sprintf('  F(%d,%d)=%2.1f, p<0.001%s',ranovatblb.DF(3),ranovatblb.DF(4),ranovatblb.F(3));
            end
            
            % calculate pairwise comparisons 
            mtab=multcompare(rm,withinFac);
            
            % print results in table
            varnames={strcat(withinFac{1},'_1'),strcat(withinFac{1},'_2')};
            catnames = categories(mtab{:,varnames});
            values= mtab{:,varnames};
            cols=cell2table(num2cell(str2double(catnames(values))),'VariableNames',varnames);
            mtab(:,varnames)=[];
            mtab=[cols,mtab];
            for l=1:length(levels)
                levelVarName{l}=sprintf('%s_pairwise_pval_%2.1f',dataVars{vars},levels(l));
            end
            multcompareTable=[multcompareTable,cell2table(num2cell(nan(l,l)),'VariableNames',levelVarName)];%2.1f);
            for m=1:height(mtab)
                rowIdx=multcompareTable{:,withinFac{1}}==mtab{m,{strcat(withinFac{1},'_1')}};
                varName=sprintf('%s_pairwise_pval_%2.1f',dataVars{vars},mtab{m,{strcat(withinFac{1},'_2')}});
                multcompareTable{rowIdx,varName}=mtab.pValue(m);
            end
            
    else
        strings={''};
    end
end
%% assemble and format output
sumTable=grpstats(resTable,withinFac,{'sem','nanmean'},'DataVars',[strcat('nanmean_',dataVars),strcat('corrected_nanmean_',dataVars)]);
sumTable.Properties.VariableNames=strrep(sumTable.Properties.VariableNames,'_corrected_nanmean_','_');
sumTable.Properties.VariableNames=strrep(sumTable.Properties.VariableNames,'_nanmean_','_raw_');
sumTable.Properties.VariableNames=strrep(sumTable.Properties.VariableNames,'nanmean','mean');
if p.Results.statistics
    sumTable=join(sumTable,multcompareTable);
end