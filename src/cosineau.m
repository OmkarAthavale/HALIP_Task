function normalizedData=Cosineau(data,groupVar,dataVar)
% this helper fucntion is workaround for dysfunctional matlab routing
% grouptransform. It removes variance in a variable that stems from another
% variable. It uses the Cosineau method for this (Cosineau, 1995)
% see here for a motivation and nice illustration 
% http://www.cogsci.nl/blog/tutorials/156-an-easy-way-to-create-graphs-with-within-subject-error-bars
%
% KS, Cold Spring Harbor, Jun 2020, schmack@cshl.edu
% 
% inputs
% data  - table with at least two variable (groupVar and data Var)
% groupVar - string with variable name for which variance should be removed
% dataVar - string with variable name from which variance should be removed
%
% outputs 
% normalizedData - table with one extra Variable named
%                   cosineau_dataVar_by_groupVar

meanData=grpstats(data,groupVar,'nanmean','dataVars',dataVar);
meanData.Properties.VariableNames=strrep(meanData.Properties.VariableNames,'nanmean_','');
grandMean=nanmean(meanData{:,dataVar});
normalizedVar=nan(height(data),1);
for r=1:height(meanData)
   idx=data{:,groupVar}==meanData{r,groupVar};
   normalizedVar(idx)=data{idx,dataVar}-meanData{r,dataVar}+grandMean;
end
normalizedData=[data,table(normalizedVar,'VariableNames',{strcat('cosineau_',dataVar,'_by_',groupVar)})];
