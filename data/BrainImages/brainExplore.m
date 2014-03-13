function brainExplore()
% Scripts that make images of the prototypical brain (MNI space)
%
% Author: A. Conrad Nied
%
% 2014-03-11

% Parameters
height = 150;
width = 200;

% Get the dataset
brain = load('brain_fsaverage.mat');

% Options
options.fig = 1;
options.background = [0 1 0];
% options.sides = {'ll'};
options.shading = '1';
options.shading = true;
options.surface = 'pial';
options.parcellation = 'aparc';
% options.parcellation_spec = {'LOC'};
options.parcellation_overlay = {'top'};
options.parcellation_cmap = [0 0 0; 0 200 200];

% Iterate over options
% sides = {'ll', 'lm', 'rl', 'rm'};
hemis = {'l', 'r'};
areas = brain.aparcShort;
% for i_side = 1:length(sides)
    % side = sides{i_side};
    % options.sides = {side};
for i_hemi = 1:length(hemis)
    hemi = hemis{i_hemi};

    for i_area = 1:length(areas)
        area = areas{i_area};
        options.parcellation_spec = {area};

        % Get the right side (medial or lateral)
        switch area
        case {'AG', 'Aud', 'cMFG', 'FPol', 'Insula', 'ITG', 'LOC', 'LOrb', 'MTG',...
            'ParsOper', 'ParsOrb', 'ParsTri', 'postCG', 'preCG', 'rMFG', 'SFG',...
            'SMG', 'SPC', 'STG', 'STS', 'TPol'}
            side = 'l';
        otherwise
            side = 'm';
        end
        options.sides = {[hemi side]};

        % A hack so that it still does medial areas
        if(i_area == 1)
            brain.aparcShort = cat(1, {' '}, areas);
            brain.aparcI = brain.aparcI + 1;
        elseif(i_area == 2)
            brain.aparcShort = areas;
            brain.aparcI = brain.aparcI - 1;
        end
        
        % Draw the Brain
        figure(options.fig);
        clf(options.fig);
        options.axes = gca;
        set(options.fig,  'Position', [100 100 width height]);
        set(options.axes, 'Units', 'Pixels');
        set(options.axes, 'Position', [  0   0 width height]);

        gps_brain_draw(brain, options)
        
        % filename = sprintf('%s-%s_%s.png', upper(hemi), area, side(2));
        filename = sprintf('%s-%s.png', upper(hemi), area);
        frame = getframe(options.fig);
        imwrite(frame.cdata, filename, 'png', 'Transparency', [0 1 0]);
    end
end

end % function