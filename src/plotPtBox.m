function h = plotPtBox(varargin, option)
arguments (Repeating)
    varargin;
end
arguments
    option.YLim = [];
    option.PairedOnly = false;
    option.Labels = [];
    option.Axis = [];
    option.DoTtests = false;
    option.PlotStats = false;
    option.BoxColour = 'k';
    option.PtColour = 'r';
    option.PtSize = 15;
    option.MultiFactor = [1 1];
    option.jitterStyle = 'rand';
    option.plotMean = false;
end

numGrp = length(varargin);
if numGrp == 1 && size(varargin{1}, 2) > 1
   	varargin = mat2cell(varargin{1}, size(varargin{1}, 1), ones(1, size(varargin{1}, 2)));
end
labels = arrayfun(@inputname, 1:numGrp, 'UniformOutput', 0);
dat = varargin;
if option.PairedOnly
    try
        nanSum = dat{1};
        for i = 2:numGrp
            nanSum = nanSum+dat{i};
        end
        mask = ~isnan(nanSum);
        dat = cellfun(@(z) z(mask), dat, 'UniformOutput', 0);
    catch
        warning('Cannot find pairs, plotting all points')
    end
end

maxN = max(cellfun(@numel, dat));

dat = reshape(cellfun(@(z) (reshape(z(~isnan(z)), [], 1)), dat, 'UniformOutput', 0), 1, []);
datIn = dat;
dat = cellfun(@(z) padZeros(z, NaN, maxN-length(z), 0), dat, 'UniformOutput', 0);

if isempty(option.Axis)
    h = figure('Position', [680,   690,   120+30*numGrp,   288]);
    ax = gca();
else
    ax = option.Axis;
    ff = ax.Parent;
    try    
        figure(ff);
    catch
        figure(ff.Parent);
    end
end
pltX = 1:size(dat, 2);
boxWidth = 0.5;
if sum(abs(option.MultiFactor - [1, 1])) ~=0
    pltX = pltX + 0.6*(option.MultiFactor(1)-1)./option.MultiFactor(2) - 0.5;
    boxWidth = 0.3./option.MultiFactor(2);
end
boxplot(ax, cell2mat(dat), 'Color', option.BoxColour, 'Width' , boxWidth, 'Positions', pltX);
% violinplot(cell2mat(dat))%, 'Color', option.BoxColour, 'Width' , boxWidth);
hold(ax, 'on');
scatter(ax, reshape(ones(maxN, numGrp).*pltX, [], 1), reshape(cell2mat(dat), [], 1), option.PtSize, 'filled','MarkerFaceColor', option.PtColour,'MarkerEdgeColor', option.PtColour,  'XJitter', option.jitterStyle, 'XJitterWidth', 0.1)

if option.plotMean
    scatter(ax, pltX, mean(cell2mat(dat), 1, 'omitnan'), option.PtSize, 'filled','MarkerFaceColor', option.PtColour,'MarkerEdgeColor', option.PtColour, 'Marker', '+')
end
ax1 = gca;
if ~isempty(option.Labels)
    labels = option.Labels;
end
ax1.XAxis.TickValues = 1:length(labels);
ax1.XAxis.TickLabels = labels;
xlim([0 numGrp+1])
if ~isempty(option.YLim)
    ylims = option.YLim;
else
    ylims = get(gca, 'YLim');
end
if option.PlotStats
    ylim([ylims(1) diff(ylims)./10+ylims(2)]);
else
    ylim(ylims)
end



if option.DoTtests || option.PlotStats
    curr_stat_base = ylims(2);
    inc_stat = diff(ylims)./100;
    
    for i = 1:length(datIn)
        for j = (i+1):length(datIn)
            if option.DoTtests
                fprintf('--- Statistical Test: %s vs %s ---\n', labels{i}, labels{j})
                [hyp, p, s] = do_statistical_comparison(datIn{i}, datIn{j});
            else
                [hyp, p, s] = do_statistical_comparison(datIn{i}, datIn{j}, 1);
            end
            if p < 0.05 && option.PlotStats
                curr_stat_base = curr_stat_base+inc_stat;
                line([i j], [curr_stat_base curr_stat_base], 'Color', 'k', 'LineWidth', 2)
            end
        end
    end
end


end
