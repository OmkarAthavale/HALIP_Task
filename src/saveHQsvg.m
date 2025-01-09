function saveHQsvg(h, name, noPainters)
%%%
%FUNCTION saveHQsvg
% Saves an svg of a figure window with a transparent background. 
%--- INPUTS ---
% h: object; figure handle object
% name: character array or string; filename (and path relative to working directory)
%-noPainters: logical [false]; true to section figure window into fixed panels
%--- OUTPUTS ---
% NONE. Save
% Omkar N. Athavale, January 2025
% Last Modified: 10 Oct 2023
%%%

if nargin < 3
    noPainters = false
end

origColor = get(h, 'color');
origHardCopy = get(h,'InvertHardcopy');
origPaperPositionMode = get(h, 'PaperPositionMode');
origRenderer = get(h, 'Renderer');

set(h, 'color', 'white')
set(h, 'InvertHardcopy', 'off')
set(h, 'PaperPositionMode', 'auto')
if ~noPainters
    set(h, 'Renderer', 'painter')
end
saveas(h, name, 'svg')


set(h, 'color', origColor);
set(h,'InvertHardcopy', origHardCopy);
set(h, 'PaperPositionMode', origPaperPositionMode);
set(h, 'Renderer', origRenderer);
end