function varargout = gps_brain_draw(data, options)
% Draws a brain
%
% Author: A. Conrad Nied (conrad.logos@gmail.com)
%
% Changelog
% 2012-07-05 Originally created as GPS1.6(-)/plot_draw.m (earlier granger
%  _plot_draw.m)
% 2012-08-08 Last modified in GPS1.6 
% 2012-10-10 Generalized and converted GPS1.7/gps_brain_draw
% 2012-10-12 Added regions, centroids, labels, and vertices
% 2012-10-14 Modified centroid properties
% 2013-02-07 Added circles
% 2013-05-23 Added SL Aparc option
% 2013-05-30 Parcellation viewing options
% 2013-07-17 GPS1.8 Added ways to work with GPS: Plotting
%   Options sides fleshed out better
% 2013-08-12 Font customization
% 2013-08-13 Added output
% 2013-08-14 Preparing to handle negative overlay data, but not ready yet

% Future: Add other perspectives, regions, text, and free rotation,
% colorbar, axes when it isn't clear

%% Organize Options

if(~isfield(options, 'fig')); options.fig = figure(1); clf; end
if(~isfield(options, 'axes')); options.axes = gca; end

if(~isfield(options, 'surface')); options.surface = 'inf'; end
if(~isfield(options, 'curvature')); options.curvature = 'none'; end
if(islogical(options.curvature)); options.curvature = num2str(2 * options.curvature); end
if(isnumeric(options.curvature)); options.curvature = num2str(options.curvature); end
if(~isfield(options, 'parcellation')); options.parcellation = 'none'; end
if(islogical(options.parcellation)); options.parcellation = num2str(options.parcellation); end
if(isnumeric(options.parcellation)); options.parcellation = num2str(options.parcellation); end
if(~isfield(options, 'parcellation_text')); options.parcellation_text = 0; end
if(~isfield(options, 'parcellation_overlay')); options.parcellation_overlay = 'bg'; end
if(~isfield(options, 'parcellation_border')); options.parcellation_border = 0; end
if(~isfield(options, 'parcellation_spec')); options.parcellation_spec = {}; end
if(~isfield(options, 'parcellation_cmap')); options.parcellation_cmap = {}; end
if(~isfield(options, 'layout')); options.layout = 2; end
if(~isfield(options, 'shading')); options.shading = false; end
if(~isfield(options, 'background')); options.background = 'k'; end
if(~isfield(options, 'font')); options.font = 'Helvetica'; end

if(~isfield(options, 'overlays')); options.overlays = []; end
if(~isstruct(options.overlays) && ~isempty(options.overlays));
    options.overlays.name = 'act';
    options.overlays.percentiled = 'n';
    options.overlays.decimated = 0;
    options.overlays.coloring = 'Hot';
    options.overlays.negative = 0;
end

if(~isfield(options, 'regions')); options.regions = false; end
if(~isfield(options, 'regions_color')); options.regions_color = [0 .75 .75]; end
if(~isfield(options, 'centroids')); options.centroids = false; end
if(~isfield(options, 'centroids_color')); options.centroids_color = [0 1 .5]; end
if(~isfield(options, 'centroids_circles')); options.centroids_circles = false; end
if(~isfield(options, 'centroids_radius')); options.centroids_radius = 10; end
if(~isfield(options, 'centroids_bordercolor')); options.centroids_bordercolor = [0 0 0]; end
if(~isfield(options, 'vertices')); options.vertices = false; end
if(~isfield(options, 'vertices_color')); options.vertices_color = [0 1 0]; end
if(~isfield(options, 'labels')); options.labels = false; end
if(~isfield(options, 'labels_color')); options.labels_color = [1 1 1]; end
if(~isfield(options, 'labels_fontsize')); options.labels_fontsize = 12; end

if(~isfield(options, 'sides'))
    if(~isfield(options, 'hemi')); options.hemi = 'left'; end
    if(~isfield(options, 'view')); options.view = 'lat'; end
    
    options.sides = {};
    
    switch lower(options.hemi)
        case {'left', 'l', 'lh'}
            switch lower(options.view)
                case {'b', 'both', 'lat & med'}
                    options.sides = {'ll', 'lm'};
                case {'l', 'lat', 'lateral'}
                    options.sides = {'ll'};
                case {'m', 'med', 'medial'}
                    options.sides = {'lm'};
            end
        case {'right', 'r', 'rh'}
            switch lower(options.view)
                case {'b', 'both', 'lat & med'}
                    options.sides = {'rl', 'rm'};
                case {'l', 'lat', 'lateral'}
                    options.sides = {'rl'};
                case {'m', 'med', 'medial'}
                    options.sides = {'rm'};
            end
        case {'both', 'b', 'bh'}
            switch lower(options.view)
                case {'b', 'both', 'lat & med'}
                    options.sides = {'ll', 'lm', 'rl', 'rm'};
                case {'l', 'lat', 'lateral'}
                    options.sides = {'ll', 'rl'};
                case {'m', 'med', 'medial'}
                    options.sides = {'lm', 'rm'};
            end
        otherwise
            options.sides = {'ll'};
    end
end % If the sides have not been declared

%% Initialize Brain Viewer

% Set figure renderer (May want to change this)
set(options.fig, 'Renderer', 'OpenGL');
set(options.fig, 'Color', options.background);
set(options.axes, 'Color', options.background);

% Clear old display
cla(options.axes);
view(options.axes, 0, 90);
legend(options.axes, 'off')
hold(options.axes, 'on');

% Set the Brain surface
switch lower(options.surface)
    case {'inf', 'inflated', '1'}
        coords = data.infcoords;
    case {'pial', 'gray', 'gray matter', '2'}
        coords = data.pialcoords;
    case {'orig', 'original', 'white', 'white matter', '3'}
        coords = data.origcoords;
end % Switch on the surface

%% Configure Background

N_bg = 1;
CData_BG = ones(data.N, 3); % White

% Curvature
switch lower(options.curvature)
    case {'binary', 'bin', '2'}
        curv = data.curv;
        CData_curv = zeros(data.N, 1);
        CData_curv(curv>0) = 0; % Gyri
        CData_curv(curv<=0) = 1; % Sulci
        
        CData_BG = CData_BG + [CData_curv CData_curv CData_curv]; % 3 grey color values

        N_bg = N_bg + 1;
    case {'even', '1', 'true'}
%         CData_curv = zeros(data.N, 1);
        CData_curv = 1 - (data.curv - min(data.curv));
        CData_curv = CData_curv / max(abs(CData_curv));
        
        CData_BG = CData_BG + [CData_curv CData_curv CData_curv]; % 3 grey color values

        N_bg = N_bg + 1;
    otherwise % 0, none
        CData_BG = CData_BG * 1.8;
        
        N_bg = N_bg + 1;
end % Switch on the curvature

% Parcellation
switch lower(options.parcellation)
    case {'aparc', 'automated', 'fs', 'freesurfer', '1', 'desikan'}
        parcI = data.aparcI;
        Cmap = data.aparcCmap;
        parc_names = data.aparcShort;
    case {'sl', 'speech lab', 'slaparc17'}
        parcI = data.SLaparc17.I;
        Cmap = data.SLaparc17.Cmap;
        parc_names = data.SLaparc17.text;
    case 'none'
    otherwise
        if(~isempty(options.parcellation) && isfield(data, options.parcellation))
            parcI = data.(options.parcellation).I;
            parc_names = data.(options.parcellation).text;
            Cmap = data.(options.parcellation).Cmap;
        end
end % Switch on the parcellation

% Parcelation coloration
if(exist('Cmap', 'var'))
    % Remove unspecified parcellation areas
    if(~isempty(options.parcellation_spec));
        for i = length(parc_names):-1:2
            if(~sum(strcmp(options.parcellation_spec, parc_names{i})))
                parcI(parcI == i) = 1;
            end
        end
    end
    
    % Get custom color map
    if(~isempty(options.parcellation_cmap));
        for i = 1:size(Cmap, 1)
            if(i <= size(options.parcellation_cmap))
                Cmap(i, :) = options.parcellation_cmap(i, :);
            else
                Cmap(i, :) = options.parcellation_cmap(end, :);
            end
        end
    end
    
    CData_parc = Cmap(parcI,:);
end

if(exist('CData_parc', 'var') && options.parcellation_border)
%     % Artificially inflate FPol
%     parc_vertices = parcI == 2;
%     parc_border = zeros(size(CData_parc, 1), 1);
%     for i_parc_vertex = find(parc_vertices)'
%         parc_border(distL2(coords(i_parc_vertex, :), coords) <= 4 & xor((1:data.N > data.N_L)', i_parc_vertex <= data.N_L)) = 1;
%     end
%     CData_parc(find(parc_border), 1) = 0; %#ok<*FNDSB>
%     CData_parc(find(parc_border), 2) = 0.9; %#ok<*FNDSB>
%     CData_parc(find(parc_border), 3) = 0.7; %#ok<*FNDSB>

    % Make a border
    parc_vertices = max(CData_parc, [], 2);
    parc_border = zeros(size(CData_parc, 1), 1);
    for i_parc_vertex = find(parc_vertices)'
        parc_border(distL2(coords(i_parc_vertex, :), coords) <= options.parcellation_border & xor((1:data.N > data.N_L)', i_parc_vertex <= data.N_L)) = 1;
    end
    CData_parc(find(parc_vertices), 1) = 0; %#ok<*FNDSB>
    CData_parc(find(parc_vertices), 2) = 0.9; %#ok<*FNDSB>
    CData_parc(find(parc_vertices), 3) = 0.7; %#ok<*FNDSB>
    CData_parc(find(~parc_vertices & parc_border), :) = 0.01; %#ok<FNDSB>
end

if(exist('CData_parc', 'var') && strcmp(options.parcellation_overlay, 'bg'))
    CData_BG = CData_BG + CData_parc;
    N_bg = N_bg + 1;
end

% Smooth out background map
CData_BG = CData_BG / N_bg;

%% Configure Foreground

N_FG = 0;
CData_FG = zeros(data.N, 3); % black

% For each overlay
for i_overlay = 1:length(options.overlays)
    overlay = options.overlays(i_overlay);
    
    overlay_data = data.(overlay.name).data;
    
    switch overlay.percentiled
        case 'p'
            percentiles = data.(overlay.name).p;
            if(length(percentiles) == 3)
                percentiles(4) = 100;
            end
            thresholds = prctile(overlay_data, percentiles);
        case 'v'
            thresholds = data.(overlay.name).v;
        otherwise
            percentiles = [25 50 75 100];
            thresholds = prctile(overlay_data, percentiles);
    end % Depending on the percentile
    
    if(overlay.decimated)
        newoverlay = zeros(data.N, 1);
        newoverlay(data.decIndices) = overlay_data;
        
        % Left Brain
        face = data.lface;
        tcoords = data.origcoords(1 : data.N_L, :);
        ldata = newoverlay(1 : data.N_L);
        ldata = gps_brain_smoothdata(ldata, face', tcoords');
        
        % Right Brain
        face = data.rface;
        tcoords = data.origcoords((data.N_L + 1) : end, :);
        rdata = newoverlay((data.N_L+1) : end);
        rdata = gps_brain_smoothdata(rdata, face', tcoords');
        
        % Synthesize
        overlay_data = [ldata; rdata];
        clear newoverlay face tcoords ldata rdata;
    end % If the overlay is decimated
    
    overlay_CData = gps_brain_colordata(overlay_data,...
        thresholds, overlay.coloring);
    figure(1)
    plot(overlay_CData)
    
    if(isfield(overlay, 'negative') && overlay.negative)
        overlay_CData = overlay_CData + ...
        gps_brain_colordata(-overlay_data,...
        thresholds, '2');
    figure(2)
    plot(overlay_CData)
    figure(3)
    plot(gps_brain_colordata(-overlay_data,...
        thresholds, '2'));
    end
    
    CData_FG = CData_FG + overlay_CData;
    N_FG = N_FG + 1;
end % For each overlay

if(exist('CData_parc', 'var') && strcmp(options.parcellation_overlay, 'fg'))
    CData_FG = CData_FG + CData_parc;
    N_FG = N_FG + 1;
end

% Synthesize and smooth FG data
if(N_FG ~= 0)
    CData_FG = CData_FG / N_FG;
end

%% Synthesize color data

CData = (CData_FG + CData_BG)/2;

if(exist('CData_parc', 'var') && strcmp(options.parcellation_overlay, 'top'))
    parc_top = find(max(CData_parc, [], 2));
    CData(parc_top, :) = CData_parc(parc_top, :);
end

%% Add Regions

if(options.regions);
    CData_reg = data.regions;
    
    [N_vertices, N_colors] = size(CData_reg);
    N_groups = max(CData_reg);
    
    % Align the dimensions
    if(N_vertices < N_colors && N_colors ~= 3)
        CData_reg = CData_reg';
        [N_vertices, ~] = size(CData_reg);
    end
    
    % Decimated?
    if(N_vertices < data.N)
        CData_regall = zeros(data.N, 1);
        
        % Draw the regions for each group (could take a long time with alot
        % of groups)
        for i_group = 1:N_groups
            CData_group = zeros(data.N, 1);
            CData_group(data.decIndices) = .05;
            CData_group(data.decIndices(CData_reg == i_group)) = 1;
            
            % Smooth
            % Left Side
            CData_group(1:data.N_L) = rois_metrics_smooth(...
                CData_group(1:data.N_L),...
                data.lface',...
                data.pialcoords(1:data.N_L, :)');
            
            % Right Side
            CData_group(data.N_L + 1:end) = rois_metrics_smooth(...
                CData_group(data.N_L + 1:end),...
                data.rface',...
                data.pialcoords(data.N_L + 1:end, :)');
            
            CData_regall(CData_group > 0.15) = -1;
            CData_regall(CData_group > 0.6) = i_group;
        end % for each grouped
        
        CData_reg = CData_regall;
        clear CData_regall CData_group;
    end % If the regions are decimated
    
    % Affect the CData based on regioned CData
    
    % Blacken borders
    CData(CData_reg == -1, 1) = 0; % Red
    CData(CData_reg == -1, 2) = 0; % Green
    CData(CData_reg == -1, 3) = 0; % Blue
    
    % Color for each region
    for i_group = 1:N_groups
        CData(CData_reg == i_group, 1) = options.regions_color(i_group, 1); % Red
        CData(CData_reg == i_group, 2) = options.regions_color(i_group, 2); % Green
        CData(CData_reg == i_group, 3) = options.regions_color(i_group, 3); % Blue
    end
    
    clear CData_reg;
end % if showing ROIs

% Even the color scales in case they are not
CData = min(CData, 1);
CData = max(CData, 0);

%% Draw the brains!

show.ll = sum(strcmp(options.sides, 'll'));
show.rl = sum(strcmp(options.sides, 'rl'));
show.lm = sum(strcmp(options.sides, 'lm'));
show.rm = sum(strcmp(options.sides, 'rm'));

% Left Lateral
if(show.ll)
    ll_coords = coords(1 : data.N_L, :);
    ll_coords(:, 1) = -ll_coords(:, 1);
    switch options.layout
        case 1
            ll_coords(:, 2) = -ll_coords(:, 2) + min(ll_coords(:, 2)) - 5;
            ll_coords(:, 3) = ll_coords(:, 3) - max(ll_coords(:, 3)) - 5;
        case 2
            ll_coords(:, 2) = -ll_coords(:, 2) + min(ll_coords(:, 2)) - 5;
            ll_coords(:, 3) = ll_coords(:, 3) - min(ll_coords(:, 3)) + 5;
        case 3
            ll_coords(:, 2) = -ll_coords(:, 2) + min(ll_coords(:, 2)) - 5;
            ll_coords(:, 3) = ll_coords(:, 3) - min(ll_coords(:, 3)) + 5;
    end
    ll_CData = CData(1 : data.N_L, :);
    
    patch('Parent', options.axes,...
        'Faces', data.lface,...
        'Vertices', ll_coords,...
        'FaceVertexCData', ll_CData,...
        'MarkerEdgeColor', 'none',...
        'EdgeColor', 'none',...
        'FaceColor', 'interp',...
        'FaceLighting', 'flat',...
        'SpecularStrength', 0.0, 'AmbientStrength', 0.4,...
        'DiffuseStrength', 0.8, 'SpecularExponent', 10.0);
else
    ll_coords = [0 0 0];
end

% Right Lateral
if(show.rl)
    rl_coords = coords(data.N_L + 1 : end, :);
    switch options.layout
        case 1
            rl_coords(:, 2) = rl_coords(:, 2) - max(rl_coords(:, 2)) - 5;
            rl_coords(:, 3) = rl_coords(:, 3) - min(rl_coords(:, 3)) + 5;
        case 2
            rl_coords(:, 2) = rl_coords(:, 2) - min(rl_coords(:, 2)) + 5;
            rl_coords(:, 3) = rl_coords(:, 3) - min(rl_coords(:, 3)) + 5;
        case 3
            rl_coords(:, 2) = rl_coords(:, 2) - min(rl_coords(:, 2)) + 5;
            rl_coords(:, 3) = rl_coords(:, 3) - min(rl_coords(:, 3)) + 5;
    end
    rl_CData = CData(data.N_L + 1:end, :);
    
    patch('Parent', options.axes,...
        'Faces', data.rface,...
        'Vertices', rl_coords,...
        'FaceVertexCData', rl_CData,...
        'MarkerEdgeColor', 'none',...
        'EdgeColor', 'none',...
        'FaceColor', 'interp',...
        'FaceLighting', 'flat',...
        'SpecularStrength', 0.0, 'AmbientStrength', 0.4,...
        'DiffuseStrength', 0.8, 'SpecularExponent', 10.0);
else
    rl_coords = [0 0 0];
end

% Left Medial
if(show.lm)
    lm_coords = coords(1 : data.N_L, :);
    switch options.layout
        case 1
            lm_coords(:, 2) = lm_coords(:, 2) - min(lm_coords(:, 2)) + 5;
            lm_coords(:, 3) = lm_coords(:, 3) - max(lm_coords(:, 3)) - 5;
        case 2
            lm_coords(:, 2) = lm_coords(:, 2) - max(lm_coords(:, 2)) - 5;
            lm_coords(:, 3) = lm_coords(:, 3) - max(lm_coords(:, 3)) - 5;
        case 3
            lm_coords(:, 2) = lm_coords(:, 2) - max(lm_coords(:, 2)) + min(ll_coords(:, 2)) - 10;
            lm_coords(:, 3) = lm_coords(:, 3) - min(lm_coords(:, 3)) + 5;
    end
    lm_CData = CData(1 : data.N_L, :);
    
    patch('Parent', options.axes,...
        'Faces', data.lface,...
        'Vertices', lm_coords,...
        'FaceVertexCData', lm_CData,...
        'MarkerEdgeColor', 'none',...
        'EdgeColor', 'none',...
        'FaceColor', 'interp',...
        'FaceLighting', 'flat',...
        'SpecularStrength', 0.0, 'AmbientStrength', 0.4,...
        'DiffuseStrength', 0.8, 'SpecularExponent', 10.0);
else
    lm_coords = [0 0 0];
end

% Right Medial
if(show.rm)
    rm_coords = coords(data.N_L + 1 : end, :);
    rm_coords(:, 1) = -rm_coords(:, 1);
    switch options.layout
        case 1
            rm_coords(:, 2) = -rm_coords(:, 2) + max(rm_coords(:, 2)) + 5;
            rm_coords(:, 3) = rm_coords(:, 3) - min(rm_coords(:, 3)) + 5;
        case 2
            rm_coords(:, 2) = -rm_coords(:, 2) + max(rm_coords(:, 2)) + 5;
            rm_coords(:, 3) = rm_coords(:, 3) - max(rm_coords(:, 3)) - 5;
        case 3
            rm_coords(:, 2) = -rm_coords(:, 2) + max(rm_coords(:, 2)) + max(rl_coords(:, 2)) + 10;
            rm_coords(:, 3) = rm_coords(:, 3) - min(rm_coords(:, 3)) + 5;
    end
    rm_CData = CData(data.N_L + 1 : end, :);
    
    patch('Parent', options.axes,...
        'Faces', data.rface,...
        'Vertices', rm_coords,...
        'FaceVertexCData', rm_CData,...
        'MarkerEdgeColor', 'none',...
        'EdgeColor', 'none',...
        'FaceColor', 'interp',...
        'FaceLighting', 'flat',...
        'SpecularStrength', 0.0, 'AmbientStrength', 0.4,...
        'DiffuseStrength', 0.8, 'SpecularExponent', 10.0);
else
    rm_coords = [0 0 0];
end

%% Set View, Lighting and Axis Limits

% Set View
view(options.axes, 90, 0)

% Set Lighting
if(options.shading)
    [az, el] = view(options.axes);
    [lightx, lighty, lightz] = sph2cart(az * pi / 180, el * pi / 180, 100);
    light('Parent', options.axes,...
        'Position', [lighty -lightx lightz],...
        'Style', 'infinite');
end

% Set Axis Limits
axis(options.axes, 'equal','tight');
xlim(options.axes, [-80 80]);
ylim(options.axes, [min([lm_coords(:, 2); rm_coords(:, 2); rl_coords(:, 2); ll_coords(:, 2)]) - 10 ...
    max([lm_coords(:, 2); rm_coords(:, 2); rl_coords(:, 2); ll_coords(:, 2)]) + 10]);
zlim(options.axes, [min([lm_coords(:, 3); rm_coords(:, 3); rl_coords(:, 3); ll_coords(:, 3)]) - 10 ...
    max([lm_coords(:, 3); rm_coords(:, 3); rl_coords(:, 3); ll_coords(:, 3)]) + 10]);
axis(options.axes, 'off');

%% Points and Labels

% Centroids
if(options.centroids)
    % Inputs
    points = data.points;
    N_points = length(points);
    
    % Get information, if they are single vectors -> expand
    colors = options.centroids_color;
    if(size(colors, 1) == 1);
        colors = repmat(colors, N_points, 1);
    end
    vertices_colors = options.vertices_color;
    if(size(vertices_colors, 1) == 1);
        vertices_colors = repmat(vertices_colors, N_points, 1);
    end
    labelcolors = options.labels_color;
    if(size(labelcolors, 1) == 1);
        labelcolors = repmat(labelcolors, N_points, 1);
    end
    radii = options.centroids_radius;
    if(size(radii, 1) == 1);
        radii = repmat(radii, N_points, 1);
    end
    bcolors = options.centroids_bordercolor;
    if(size(bcolors, 1) == 1);
        bcolors = repmat(bcolors, N_points, 1);
    end

    % For each point
    for i_point = 1:N_points
        point = points(i_point);
        if(~isfield(point, 'index'))
            point.index = point.centroid;
        end
        
        % Additional vertices (for mesh regions)
        if(options.vertices)
            for i_vertex = 1:length(point.vertices)
                hemiside = lower(sprintf('%s%s', point.hemi, point.side));
                switch sprintf('%s%d', hemiside, show.(hemiside))
                    case {'ll1', 'll0', 'lm0'}
                        coord = ll_coords(point.vertices(i_vertex), :);
                    case {'rl1', 'rl0', 'rm0'}
                        coord = rl_coords(point.vertices(i_vertex) - data.N_L, :);
                    case 'lm1'
                        coord = lm_coords(point.vertices(i_vertex), :);
                    case 'rm1'
                        coord = rm_coords(point.vertices(i_vertex) - data.N_L, :);
                end
                
                % Draw the points
                plot3(options.axes,...
                    49, coord(2), coord(3),...
                    '+',...
                    'MarkerSize', 10,...
                    'Color', vertices_colors(i_point, :))
                plot3(options.axes,...
                    49, coord(2), coord(3),...
                    'o',...
                    'MarkerSize', 10,...
                    'Color', vertices_colors(i_point, :))
            end % for each vertices
        end % if drawing vertices
        
        % Find the coordinates of the point
        hemiside = lower(sprintf('%s%s', point.hemi, point.side));
        switch sprintf('%s%d', hemiside, show.(hemiside))
            case {'ll1', 'll0', 'lm0'}
                coord = ll_coords(point.index, :);
            case {'rl1', 'rl0', 'rm0'}
                coord = rl_coords(point.index - data.N_L, :);
            case 'lm1'
                coord = lm_coords(point.index, :);
            case 'rm1'
                coord = rm_coords(point.index - data.N_L, :);
        end
        
        % Draw the points
        if(options.centroids_circles)
            [y1, z1, x1] = cylinder(radii(i_point), 100);
            fill3(x1(1, :) + 49,...
                y1(1, :) + coord(2),...
                z1(1, :) + coord(3),...
                colors(i_point, :),...
                'FaceLighting', 'none',...
                'EdgeColor', bcolors(i_point, :),...
                'Parent', options.axes);
        else
            plot3(options.axes,...
                49, coord(2), coord(3),...
                '+',...
                'MarkerSize', radii(i_point),...
                'Color', colors(i_point, :))
            plot3(options.axes,...
                49, coord(2), coord(3),...
                'o',...
                'MarkerSize', radii(i_point),...
                'Color', colors(i_point, :))
        end
        
        if(options.labels == 1)
            text(50, coord(2), coord(3),...
                sprintf('%s_{%d}', point.area, point.num),...
                'Parent', options.axes,...
                'HorizontalAlignment', 'center',...
                'Color', labelcolors(i_point, :),...
                'VerticalAlignment', 'middle',...
                'FontWeight', 'bold',...
                'FontSize', options.labels_fontsize,...
                'FontName', options.font);
        elseif(options.labels == 2)
            text(50, coord(2), coord(3),...
                options.labeltext{i_point},...
                'Parent', options.axes,...
                'HorizontalAlignment', 'center',...
                'Color', labelcolors(i_point, :),...
                'VerticalAlignment', 'middle',...
                'FontWeight', 'bold',...
                'FontSize', options.labels_fontsize,...
                'FontName', options.font);
        end % If showing text
    end % for each point
end % If showing centroids

%% Parcellation Text

if(options.parcellation_text && exist('parcI', 'var'))
    parc_extant = unique(parcI);
    N_parc_regions = length(parc_extant);
    parc_centroid_lh = zeros(N_parc_regions, 3);
    parc_centroid_rh = zeros(N_parc_regions, 3);
    
    for i_region = 1:N_parc_regions
        parc_centroid_lh(i_region, :) = mean(coords(find(parcI(1:data.N_L) == parc_extant(i_region)), :)); %#ok<FNDSB>
        parc_centroid_rh(i_region, :) = mean(coords(find(parcI(data.N_L + 1:end) == parc_extant(i_region)), :)); %#ok<FNDSB>
    end
    
    for i_region = 1:N_parc_regions
        region = parc_extant(i_region);
        region_name = parc_names{region};
        
        if(~isempty(region_name))
            % Format area name
            area_name = region_name;
            i_hyphen = find(area_name ==  '-');
            if(~isempty(i_hyphen)); area_name = area_name(i_hyphen + 1:end); end
            i_underscore = find(area_name ==  '_');
            if(~isempty(i_underscore)); area_name = area_name(1: i_underscore - 1); end
            
            switch area_name
                case {'PCN', 'LG', 'TOF', 'pTF', 'pCG', 'SMA', 'preSMA',...
                        'SCC', 'aCC', 'pPH', 'None', 'FMC', 'aTF', 'aPH',...
                        'aCG', 'midCG',... Now for Desikan:
                        'ParaC', 'preCun', 'Cun', 'Calc', 'ParaHip', 'Fusi',...
                        'Medial', 'Ent', 'Isth', 'pCing', 'caCing',...
                        'raCing', 'MOrb', 'CC'}
                    side = 'm';
                case {'FP', 'SFg', 'aMFg', 'pMFg', 'adPMC', 'mdPMC',...
                        'pdPMC', 'dMC', 'dSC', 'SPL', 'AG', 'OC', 'MTO',...
                        'ITO', 'pITg', 'aITg', 'aINS', 'pINS', 'pSTg',...
                        'aSTg', 'asSTs', 'pdSTs', 'avSTs', 'pvSTs', 'pMTg',...
                        'aMTg', 'TP', 'vPMC', 'vMC', 'vSC', 'aSMg', 'pSMg',...
                        'adSTs', 'H', 'PP', 'midPMC', 'midMC', 'pIFs',...
                        'aIFs', 'dIFt', 'vIFt', 'FOC', 'PT', 'PO', 'pCO',...
                        'aCO', 'vIFo', 'dIFo', 'aFO', 'pFO',... Desikan:
                        'LOC', 'ITG', 'MTG', 'STG', 'TPol', 'Aud', 'Insula',...
                        'LOrb', 'ParsOrb', 'ParsTri', 'ParsOper', 'FPol',...
                        'rMFG', 'SFG', 'cMFG', 'preCG', 'postCG', 'SMG',...
                        'SPC', 'STS'}
                    side = 'l';
                otherwise
                    side = 'm';
            end % Find out whether a region is on the left or right
            
            hemis = {'l', 'r'};
            if(strcmp(region_name(1:2), 'L-'))
                hemis = {'l'};
            elseif(strcmp(region_name(1:2), 'R-'))
                hemis = {'r'};
            end
            
            for i_hemi = 1:length(hemis)
                hemi = hemis{i_hemi};
                hemiside = [hemi side];
                
                switch sprintf('%s%d', hemiside, show.(hemiside))
                    case {'ll1', 'll0', 'lm0'}
                        coord = mean(ll_coords(parcI(1:data.N_L) == region, :), 1);
                    case {'rl1', 'rl0', 'rm0'}
                        coord = mean(rl_coords(parcI(data.N_L + 1:end) == region, :), 1);
                    case 'lm1'
                        coord = mean(lm_coords(parcI(1:data.N_L) == region, :), 1);
                    case 'rm1'
                        coord = mean(rm_coords(parcI(data.N_L + 1:end) == region, :), 1);
                end
                
                text(49, coord(2), coord(3),...
                    region_name,...
                    'Parent', options.axes,...
                    'HorizontalAlignment', 'center',...
                    'Color', 'w',...
                    'VerticalAlignment', 'middle',...
                    'FontWeight', 'bold',...
                    'FontSize', options.labels_fontsize,...
                    'FontName', options.font);
%                 i_overall = i_overall + 1;
%                 xyz(i_overall, :) = [49, coord(2), coord(3)];
%                 txt{i_overall} = region_name;
            end % for each hemisphere
        end % for each region
    end
    
%     gps_textfit(xyz(:, 1), xyz(:, 2), xyz(:, 3),...
%         txt,...
%         'Parent', options.axes,...
%         'HorizontalAlignment', 'center',...
%         'Color', 'w',...
%         'VerticalAlignment', 'middle',...
%         'FontWeight', 'bold',...
%         'FontSize', options.labels_fontsize);
        
end % If we are showing text for the parcellation

%% Save the data if there is a varargout

if(nargout == 1)
    %     variables = whos;
    %
    %     for i_var = 1:length(variables)
    %         savefunc = sprintf('savedata.%1$s = %1$s;', variables(i_var).name);
    %         eval(savefunc);
    %     end
    savedata.ll_coords = ll_coords;
    savedata.rl_coords = rl_coords;
    savedata.lm_coords = lm_coords;
    savedata.rm_coords = rm_coords;
    
    varargout{1} = savedata;
end

    %% Add Colorbar if we are using activation
%     
%     if(get(GPSP_vars.act_show, 'Value') && get(GPSP_vars.act_colorbar, 'Value'))
%         ylimits = ylim(GPSP_vars.display_brainaxes);
%         zlimits = zlim(GPSP_vars.display_brainaxes);
%         
%         % Get value breaks
%         v0 = 0;%min(act.data);
%         v1 = str2double(get(GPSP_vars.act_v1, 'String'));
%         v2 = str2double(get(GPSP_vars.act_v2, 'String'));
%         v3 = str2double(get(GPSP_vars.act_v3, 'String'));
%         v4s = v3 + (v3 - v0) / 10; % supplemental v4
%         v4 = max(act.data);
%         v4sd = (v4s - v3) / (v4 - v3); % supplemental v4 differential
%         
%         vertices = [v0 v1 v2 v3 v4s];
%         vertices = vertices / (v4s - v0) - v0;
%         vertices = vertices * (ylimits(2) - ylimits(1) - 20) + ylimits(1) + 10;
%         FV.vertices = [zeros(1, 10);
%                     vertices, fliplr(vertices);
%                     ones(1, 5) * zlimits(1), ones(1, 5) * zlimits(1) - 20]';
%         FV.facevertexcdata = [0 0 0; 0 0 0; 1 0 0; 1 1 0; 1 1 v4sd;
%                               1 1 v4sd; 1 1 0; 1 0 0; 0 0 0; 0 0 0]*0.7 + 0.3;
%         FV.faces = [1 2 9 10; 2 3 8 9; 3 4 7 8; 4 5 6 7];
%         
%         % Label landmarks
%         text(0, vertices(1), zlimits(1) - 30, '0.00e-11',...
%             'HorizontalAlignment', 'left',...
%             'Color', repmat(get(GPSP_vars.display_bg, 'Value') == 4, 1, 3),...
%             'Parent', GPSP_vars.display_brainaxes);
%         text(0, vertices(2), zlimits(1) - 30, sprintf('%1.2e', v1),...
%             'HorizontalAlignment', 'center',...
%             'Color', repmat(get(GPSP_vars.display_bg, 'Value') == 4, 1, 3),...
%             'Parent', GPSP_vars.display_brainaxes);
%         text(0, vertices(3), zlimits(1) - 30, sprintf('%1.2e', v2),...
%             'HorizontalAlignment', 'center',...
%             'Color', repmat(get(GPSP_vars.display_bg, 'Value') == 4, 1, 3),...
%             'Parent', GPSP_vars.display_brainaxes);
%         text(0, vertices(4), zlimits(1) - 30, sprintf('%1.2e', v3),...
%             'HorizontalAlignment', 'center',...
%             'Color', repmat(get(GPSP_vars.display_bg, 'Value') == 4, 1, 3),...
%             'Parent', GPSP_vars.display_brainaxes);
%         text(0, vertices(5), zlimits(1) - 30, '...',...
%             'HorizontalAlignment', 'right',...
%             'Color', repmat(get(GPSP_vars.display_bg, 'Value') == 4, 1, 3),...
%             'Parent', GPSP_vars.display_brainaxes);
%                           
%         patch(FV,...
%             'FaceColor', 'interp',...
%             'EdgeColor', repmat(get(GPSP_vars.display_bg, 'Value') == 4, 1, 3),...
%             'Parent', GPSP_vars.display_brainaxes,...
%             'LineStyle', '-',...
%             'FaceLighting', 'none');
%         
%         zlimits(1) = zlimits(1) - 40;
%         zlim(GPSP_vars.display_brainaxes, zlimits);
%         clear act;
%     end
    
    
% 
% 
% %% Get Granger Data
% granger = plot_get('granger');
% rois = plot_get('rois');
% 
% % End early if empty
% if(isempty(granger))
%     guidata(hObject, GPSP_vars);
%     return
% end
% 
% tstart = GPSP_vars.frame(1);
% tstop = GPSP_vars.frame(2);
% stgloc = GPSP_vars.stgloc;
% threshold = str2double(get(GPSP_vars.cause_threshold, 'String'));
% scale = str2double(get(GPSP_vars.cause_scale, 'String'));
% 
% % granger_values = granger.results(:,:,tstart:tstop);
% 
% 
% if(get(GPSP_vars.cause_signif, 'Value'))
%     alpha_values = granger.alpha_values;
% else
%     threshold = str2double(get(GPSP_vars.cause_threshold, 'String'));
%     alpha_values = ones(size(granger.results)) * threshold;
% end
% 
% granger_values = granger.results - alpha_values;
% granger_values(granger_values < 0) = 0;
% granger_values = granger_values(:,:,tstart:tstop);
% granger_values = mean(granger_values, 3);
% % granger_values = mean(granger_values, 3) - 0.005;
% % granger_values(granger_values < 0) = 0;
% 
% % if(~get(GPSP_vars.cause_zegnero, 'Value'))
% %     granger_values(granger_values < 0) = 0;
% % end
% % if(~get(GPSP_vars.cause_meanafterthresh, 'Value'))
% %     granger_values = mean(granger_values, 3);
% % %     mean_weights = gaussian((1:size(granger_values, 3)) - (size(granger_values, 3)/2), 0, size(granger_values, 3)/2)';
% % %     mean_weightsM = permute(repmat(mean_weights, [1 size(granger_values, 1) size(granger_values, 2)]), [2 3 1]);
% % %     granger_values = sum(granger_values .* mean_weightsM, 3) / sum(mean_weights);
% % end
% N_ROIs = size(granger_values, 1);
% % 
% % % Replace bad values with 0
% % granger_values(isnan(granger_values)) = 0;
% % granger_values(isinf(granger_values)) = 0;
% % granger_values(granger_values < threshold) = 0;
% % 
% % if(get(GPSP_vars.cause_meanafterthresh, 'Value'))
% %     granger_values = mean(granger_values, 3);
% % %     mean_weights = gaussian((1:size(granger_values, 3)) - (size(granger_values, 3)/2), 0, size(granger_values, 3)/2)';
% % %     mean_weightsM = permute(repmat(mean_weights, [1 size(granger_values, 1) size(granger_values, 2)]), [2 3 1]);
% % %     granger_values = sum(granger_values .* mean_weightsM, 3) / sum(mean_weights);
% % %     granger_values(granger_values < threshold) = 0;
% % end
% 
% % Get cumulative granger_values
% 
% if(get(GPSP_vars.node_cum, 'Value'))
%     granger_values_cum = zeros(size(granger_values));
%     N_frames = length(GPSP_vars.frames);
%     
%     for i_frame = 1:N_frames
%         frame = GPSP_vars.frames(i_frame,:);
%         
%         gvs = granger.results(:, :, frame(1):frame(2));
% 
%         if(~get(GPSP_vars.cause_zegnero, 'Value'))
%             gvs(gvs < 0) = 0;
%         end
%         if(~get(GPSP_vars.cause_meanafterthresh, 'Value'))
%             gvs = mean(gvs, 3);
%         end
% 
%         % Replace bad values with 0
%         gvs(isnan(gvs)) = 0;
%         gvs(isinf(gvs)) = 0;
%         gvs(gvs < threshold) = 0;
% 
%         if(get(GPSP_vars.cause_meanafterthresh, 'Value'))
%             gvs = mean(gvs, 3);
%         end
%         
%         granger_values_cum = granger_values_cum + gvs / N_frames;
%     end % for each time frame
%     
%     % Right now overrides the granger values
%     granger_values = granger_values_cum;
% end % if we are doing the cumulative measure
% 
% % Highlight only focused areas
% granger_values(~GPSP_vars.foci) = 0;
% granger_values(~GPSP_vars.foci) = 0;
% % hemidiff = double([rois.hemi] == 'L');
% % hemidiff = hemidiff' * hemidiff;
% % granger_values(find(~hemidiff)) = 0;
% 
% % granger_values_count = granger_values > 0;
% 
% %% Setup Coloring and Borders
% 
% switch get(GPSP_vars.cause_color, 'Value')
%     case 1 % Green/Red Solid
%         color_recip = 0;
%         color_direc = 2.5;
%         color_snk = 5;
%         color_src = 0;
%         
%         cmap_line = 0:0.005:1;
%         cmap_line = sqrt(cmap_line);
%         cmap = [flipud(cmap_line') cmap_line' zeros(length(cmap_line), 1)];
%         cmap2 = [zeros(length(cmap_line), 1) flipud(cmap_line') cmap_line'];
%         cmap = [cmap; cmap2];
%         colormap(GPSP_vars.display_brainaxes, cmap);
%     case 2 % Green Blue Gradient
%         color_snk = 0;
%         color_src = 5;
% %         color_recip = (color_snk + color_src) / 2;
%         color_direc = [color_snk color_src];
%         color_recip = color_direc;
%         
%         cmap_line = 0.1:0.005:.9;
%         cmap_line = sqrt(cmap_line);
%         cmap = [zeros(length(cmap_line), 1) cmap_line' flipud(cmap_line')];
%         colormap(GPSP_vars.display_brainaxes, cmap);
%     case 3 % Green Blue Gradient
%         color_snk = 0;
%         color_src = 5;
%         color_direc = [color_snk color_src];
%         color_recip = color_direc;
%         
% %         cmap_line = 0.1:0.05:.9;
% %         cmap_line = sqrt(cmap_line);
% %         cmap = [zeros(length(cmap_line), 1) cmap_lineG' flipud(cmap_line')];
%         cmap = [0 1 .5; 1 1 1; 1 1 1; 1 1 1; 1 1 1; 0 .5 1];
%         cmap = [0 .5 1; cmap; cmap; cmap; cmap; cmap; cmap; cmap; cmap; cmap; cmap; 0 1 .5];
% %         cmap = [cmap; cmap; cmap; cmap; cmap; cmap];
%         colormap(GPSP_vars.display_brainaxes, cmap);
% end
% 
% caxis(GPSP_vars.display_brainaxes, [0 5]);
% 
% if(get(GPSP_vars.cause_borders, 'Value'))
%     border = '-';
% else
%     border = 'none';
% end
% 
% %% Plot Nodes and Source/Sink Strength
% 
% % hold(GPSP_vars.display_brainaxes, 'on');
% 
% if(~flag_brain) % Circle
%     
%     angle = (2 * pi) / N_ROIs;
% 
%     % Build the coordinates for each node based on a polar graph
%     x_nodes = zeros(N_ROIs, 1);
%     y_nodes = zeros(N_ROIs, 1);
%     z_nodes = zeros(N_ROIs, 1);
%     for i_node = 1:N_ROIs
%         x_nodes(i_node) = cos(angle * (i_node - stgloc) + pi/2);
%         y_nodes(i_node) = sin(angle * (i_node - stgloc) + pi/2);
%     end
% 
%     % If Showing Source/Sink strength or just dots
%     if(get(GPSP_vars.node_source, 'Value') || get(GPSP_vars.node_sink, 'Value'))
%         % Compute Strength
% %         if(get(GPSP_vars.node_cum, 'Value'))
% %             val_src = sum(granger_values_cum) * scale * 0.01;
% %             val_snk = sum(granger_values_cum, 2) * scale * 0.01;
% %         else
% %             val_src = sum(granger_values) * scale * 0.01;
% %             val_snk = sum(granger_values, 2) * scale * 0.01;
% %         end
%         nodescale = str2double(get(GPSP_vars.node_scale, 'String'));
%         
%         if(get(GPSP_vars.node_sum, 'Value')) % Summing
%             val_src = sum(granger_values) * 0.01;
%             val_snk = sum(granger_values, 2) * 0.01;
%         else % Counting
%             val_src = sum(granger_values > 0) * 0.002;
%             val_snk = sum(granger_values > 0, 2) * 0.002;
%         end % If Counting or summing
%         
%         if(~get(GPSP_vars.node_source, 'Value')); val_src(:) = 0; end
%         if(~get(GPSP_vars.node_sink, 'Value')); val_snk(:) = 0; end
%         
%         % Relative
%         if(get(GPSP_vars.node_rel, 'Value'))
%             max_move = max([val_src val_snk']);
%             val_src = val_src / max_move * 0.005;
%             val_snk = val_snk / max_move * 0.005;
%         end
%         
%         val_src = val_src * nodescale;
%         val_snk = val_snk * nodescale;
%         
%         for i_ROI = 1:N_ROIs
%             
%             % Which is more, sourcing or sinking?
%             if(val_src(i_ROI) > val_snk(i_ROI))
%                 [x, y, ~] = cylinder(val_src(i_ROI), 100);
%                 fill(x(1, :) + x_nodes(i_ROI),...
%                     y(1, :) + y_nodes(i_ROI),...
%                     color_src,...
%                     'FaceLighting', 'none',...
%                     'Parent', GPSP_vars.display_brainaxes)
%                 [x, y, ~] = cylinder(val_snk(i_ROI), 100);
%                 fill(x(1, :) + x_nodes(i_ROI),...
%                     y(1, :) + y_nodes(i_ROI),...
%                     color_snk,...
%                     'FaceLighting', 'none',...
%                     'Parent', GPSP_vars.display_brainaxes)
%             else % Sinking
%                 [x, y, ~] = cylinder(val_snk(i_ROI), 100);
%                 fill(x(1, :) + x_nodes(i_ROI),...
%                     y(1, :) + y_nodes(i_ROI),...
%                     color_snk,...
%                     'FaceLighting', 'none',...
%                     'Parent', GPSP_vars.display_brainaxes)
%                 [x, y, ~] = cylinder(val_src(i_ROI), 100);
%                 fill(x(1, :) + x_nodes(i_ROI),...
%                     y(1, :) + y_nodes(i_ROI),...
%                     color_src,...
%                     'FaceLighting', 'none',...
%                     'Parent', GPSP_vars.display_brainaxes)
%             end % Which one is higher
%         end % for each ROI
%     else % Normal dots
%         % Plot each node
%         for i_node = 1:N_ROIs
%             h = plot(GPSP_vars.display_brainaxes,...
%                 x_nodes(i_node), y_nodes(i_node), '.');
%             set(h, 'Color', repmat(get(GPSP_vars.display_bg, 'Value')==4, 3, 1));
%             set(h, 'MarkerSize', 8);
%             hold(GPSP_vars.display_brainaxes, 'on');
%         end
%     end % If showing strength or doing normal dots
% 
% else % Brain
%     
%     x_nodes = zeros(N_ROIs, 1);
%     y_nodes = zeros(N_ROIs, 1);
%     z_nodes = zeros(N_ROIs, 1);
%     
% %     x_peri = maxFront:(maxOccit - maxFront)/(N_peri + 1):maxOccit;
%     
%     % For each ROI, determine if it is seeable or on the periphery
%     peripheral = zeros(N_ROIs, 1);
%     
%     for i_ROI = 1:N_ROIs
%         roi = rois(i_ROI);
%         x_nodes(i_ROI) = 80;
%         
%         switch [roi.hemi roi.side]
%             case 'LL'
%                 peripheral(i_ROI) = ~showside(1);
%                 
%                 if(~peripheral(i_ROI))
%                     y_nodes(i_ROI) = mean(ll_coords(roi.centroid, 2));
%                     z_nodes(i_ROI) = mean(ll_coords(roi.centroid, 3));
%                 end
%             case 'RL'
%                 peripheral(i_ROI) = ~showside(2);
%                 
%                 if(~peripheral(i_ROI))
%                     y_nodes(i_ROI) = mean(rl_coords(roi.centroid - brain.N_L, 2));
%                     z_nodes(i_ROI) = mean(rl_coords(roi.centroid - brain.N_L, 3));
%                 end
%             case 'LM'
%                 peripheral(i_ROI) = ~showside(3);
%                 
%                 if(~peripheral(i_ROI))
%                     y_nodes(i_ROI) = mean(lm_coords(roi.centroid, 2));
%                     z_nodes(i_ROI) = mean(lm_coords(roi.centroid, 3));
%                 end
%             case 'RM'
%                 peripheral(i_ROI) = ~showside(4);
%                 
%                 if(~peripheral(i_ROI))
%                     y_nodes(i_ROI) = mean(rm_coords(roi.centroid - brain.N_L, 2));
%                     z_nodes(i_ROI) = mean(rm_coords(roi.centroid - brain.N_L, 3));
%                 end
%         end
%         
%         if(peripheral(i_ROI))
%             x_nodes(i_ROI) = 80;
%             y_nodes(i_ROI) = 0;
%             z_nodes(i_ROI) = 0;
%         end
%     end
%     
%     % If Showing Source/Sink strength or just dots
%     if(get(GPSP_vars.node_source, 'Value') || get(GPSP_vars.node_sink, 'Value'))
% %         % Compute Strength
% %         if(get(GPSP_vars.node_cum, 'Value'))
% %             val_src = sum(granger_values_cum) * scale;
% %             val_snk = sum(granger_values_cum, 2) * scale;
% %         else
% %             val_src = sum(granger_values) * scale;
% %             val_snk = sum(granger_values, 2) * scale;
% %         end
%         
%         nodescale = str2double(get(GPSP_vars.node_scale, 'String'));
%         
%         if(get(GPSP_vars.node_sum, 'Value')) % Summing
%             val_src = sum(granger_values);
%             val_snk = sum(granger_values, 2);
%         else % Counting
%             val_src = sum(granger_values > 0) * 0.2;
%             val_snk = sum(granger_values > 0, 2) * 0.2;
%         end % If Counting or summing
%         
%         % Omit focused ROI if focus special
%         if(get(GPSP_vars.node_focusspec, 'Value'))
%             ROIfocus = get(GPSP_vars.focus_list, 'Value');
%             ROIfocusstr = get(GPSP_vars.focus_list, 'String');
%             for i = ROIfocus; fprintf('%s Outgoing: %d, Incoming: %d\n', ROIfocusstr{i}, val_src(i), val_snk(i)); end
%             val_src(ROIfocus) = 0;
%             val_snk(ROIfocus) = 0;
%         end
%         
%         if(~get(GPSP_vars.node_source, 'Value')); val_src(:) = 0; end
%         if(~get(GPSP_vars.node_sink, 'Value')); val_snk(:) = 0; end
%         
%         % Relative
%         if(get(GPSP_vars.node_rel, 'Value'))
%             max_move = max([val_src val_snk']);
%             val_src = val_src / max_move;
%             val_snk = val_snk / max_move;
%         end
% 
%         % Scale
%         val_src = val_src * nodescale;
%         val_snk = val_snk * nodescale;
%         val_src = power(val_src, 0.5); % Scale so the area doesn't get massive
%         val_snk = power(val_snk, 0.5);
%         
%         for i_ROI = 1:N_ROIs
%             
%             % No peripheral nodes
%             if(~peripheral(i_ROI))
%                 alwayspartition = 0;
% %                 partition_factor = 1/2;
% 
%                 if(alwayspartition || val_snk(i_ROI) > 0)
%                     [y1 z1 x1] = cylinder(val_src(i_ROI), 100);
% %                         [y1 z1 x1] = cylinder(val_src(i_ROI) / power(partition_factor, 0.5), 100);
%                     c1 = color_src;
%                     x1 = x1(:, 25:77); y1 = y1(:, 25:77); z1 = z1(:, 25:77);
%                 else
%                     [y1 z1 x1] = cylinder(val_src(i_ROI), 100);
%                     c1 = color_src;
%                 end
% 
%                 if(alwayspartition || val_src(i_ROI) > 0)
%                     [y2 z2 x2] = cylinder(val_snk(i_ROI), 100);
% %                         [y2 z2 x2] = cylinder(val_snk(i_ROI) / power(1 - partition_factor, 0.5), 100);
%                     c2 = color_snk;
%                     x2 = x2(:, [77:100 1:25]); y2 = y2(:, [77:100 1:25]); z2 = z2(:, [77:100 1:25]);
%                 else
%                     [y2 z2 x2] = cylinder(val_snk(i_ROI), 100);
%                     c2 = color_snk;
%                 end
%                 
%                 % Draw the circles
%                 h = fill3(x1(1, :) + x_nodes(i_ROI),...
%                     y1(1, :) + y_nodes(i_ROI),...
%                     z1(1, :) + z_nodes(i_ROI),...
%                     c1,...
%                     'FaceLighting', 'none',...
%                     'Parent', GPSP_vars.display_brainaxes);
%                 set(h, 'LineStyle', border)
%                 h = fill3(x2(1, :) + x_nodes(i_ROI),...
%                     y2(1, :) + y_nodes(i_ROI),...
%                     z2(1, :) + z_nodes(i_ROI),...
%                     c2,...
%                     'FaceLighting', 'none',...
%                     'Parent', GPSP_vars.display_brainaxes);
%                 set(h, 'LineStyle', border)
%             end % no peripheral nodes
%         end % for each ROI
%         
%     end % If showing strength
% end
% 
% %% Plot Reciprocal Edges
% 
% if(get(GPSP_vars.cause_show, 'Value'))
%     % Find set of all ROIs pointing to eachother
%     reciprocal_granger = granger_values .* granger_values';
%     [i_snks, i_srcs] = find(reciprocal_granger); % Sources and Sinks
%     edges_recip = [i_snks i_srcs];
% 
%     for i_pair = 1:length(i_snks)
%         
%         % Coordinates
%         x_src = x_nodes(i_srcs(i_pair));
%         y_src = y_nodes(i_srcs(i_pair));
%         x_snk = x_nodes(i_snks(i_pair));
%         y_snk = y_nodes(i_snks(i_pair));
%         z_src = z_nodes(i_srcs(i_pair));
%         z_snk = z_nodes(i_snks(i_pair));
%         
%         x_mid = (x_src + x_snk) / 2;
%         y_mid = (y_src + y_snk) / 2;
%         z_mid = (z_src + z_snk) / 2;
%         
%         value = granger_values(i_snks(i_pair), i_srcs(i_pair)) .* scale;
%         value2 = granger_values(i_srcs(i_pair), i_snks(i_pair)) .* scale;
%         
%         if(~flag_brain)
%             width = [value value2] / 100;
%             width_tri = width + 0.15;
%         else
%             width = [value value2];
%             width_tri = width + 5;
%         end
% 
%         if(i_srcs(i_pair) < i_snks(i_pair))
%             plot_arrow([x_src y_src z_src], [x_snk y_snk z_snk],...
%                 'Width', width,...
%                 'Triangle Width', width_tri,...
%                 'Color', color_recip,...
%                 'Reciprocal', true,...
%                 'Border', border,...
%                 'Style', get(GPSP_vars.cause_style, 'Value'),...
%                 'Surface', flag_brain,...
%                 'Parent', GPSP_vars.display_brainaxes);
% 
%             if(get(GPSP_vars.cause_weights, 'Value'))
%                 text(x_mid, y_mid, z_mid,...
%                     sprintf('%.2f&%.2f', value, value2),...
%                     'HorizontalAlignment', 'center',...
%                     'Color', repmat(get(GPSP_vars.display_bg, 'Value')==4, 3, 1),...
%                     'FontWeight', 'bold',...
%                     'FontSize', 14,...
%                     'Parent', GPSP_vars.display_brainaxes);
%             end
%         end
%     end % for each pair of activity
% 
%     %% Plot Directed Edges
% 
%     % Find set of vertices
%     [i_snks, i_srcs] = find(granger_values);
%     edges_drctd = [i_snks i_srcs];
%     edges_drctd = setdiff(edges_drctd, edges_recip, 'rows');
%     i_snks = edges_drctd(:, 1);
%     i_srcs = edges_drctd(:, 2);
% 
%     for i_pair = 1:length(i_snks)
%         % Coordinates
%         x_src = x_nodes(i_srcs(i_pair));
%         y_src = y_nodes(i_srcs(i_pair));
%         x_snk = x_nodes(i_snks(i_pair));
%         y_snk = y_nodes(i_snks(i_pair));
%         z_src = z_nodes(i_srcs(i_pair));
%         z_snk = z_nodes(i_snks(i_pair));
%         x_mid = (x_src + x_snk) / 2;
%         y_mid = (y_src + y_snk) / 2;
%         z_mid = (z_src + z_snk) / 2;
% 
%         value = granger_values(i_snks(i_pair), i_srcs(i_pair)) .* scale;
%         if(~flag_brain)
%             width = value / 100;
%             width_tri = width + 0.1;
%         else
%             width = value;
%             width_tri = width + 5;
%         end
% 
%         plot_arrow([x_src y_src z_src], [x_snk y_snk z_snk],...
%             'Width', width,...
%             'Triangle Width', width_tri,...
%             'Color', color_direc,...
%             'Reciprocal', false,...
%             'Border', border,...
%             'Style', get(GPSP_vars.cause_style, 'Value'),...
%             'Surface', flag_brain,...
%             'Parent', GPSP_vars.display_brainaxes);
% 
%         if(get(GPSP_vars.cause_weights, 'Value'))
%             text(x_mid, y_mid, z_mid,...
%                 sprintf('%.2f', value),...
%                 'HorizontalAlignment', 'center',...
%                 'Color', repmat(get(GPSP_vars.display_bg, 'Value')==4, 3, 1),...
%                 'FontWeight', 'bold',...
%                 'FontSize', 14,...
%                 'Parent', GPSP_vars.display_brainaxes);
%         end
%     end % For each pair
% 
% end % if showing arrows
% 
% %% Format Axis
% 
% if(~flag_brain) % Circle
% 
%     set(GPSP_vars.display_brainaxes, 'Box', 'off');
%     axis(GPSP_vars.display_brainaxes, 'square');
%     axis(GPSP_vars.display_brainaxes, 'off');
% 
%     xlim(GPSP_vars.display_brainaxes, [-1.4 1.4]);
%     ylim(GPSP_vars.display_brainaxes, [-1.4 1.4]);
% %     zlim(GPSP_vars.display_brainaxes, [-1 1]);
% %     view(GPSP_vars.display_brainaxes, 0, 0)
% 
%     % Write Timestamp
%     if(get(GPSP_vars.frames_timestamp, 'Value') || isfield(GPSP_vars, 'customstamp'))
%         if(get(GPSP_vars.node_cum, 'Value'))
%             stamp = 'Cumulative';
%         elseif(isfield(GPSP_vars, 'customstamp'))
%             stamp = GPSP_vars.customstamp;
%         else
%             switch get(GPSP_vars.frames_timestamp_style, 'Value')
%                 case 1 % Start and Stop
%                     stamp = sprintf('%03d to %d ms', tstart, tstop);
%                 case 2 % Start
%                     stamp = sprintf('%03d ms', tstart);
%                 case 3 % Center
%                     stamp = sprintf('%03g ms', (tstart + tstop) / 2);
%             end % which timestamp
%         end % cumulative or not?
% 
%         h = text(-1.3, -1.2,...
%             stamp,...
%             'Color', repmat(get(GPSP_vars.display_bg, 'Value')==4, 3, 1),...
%             'Parent', GPSP_vars.display_brainaxes);
%         set(h, 'FontSize', 14);
%     end
% else
%     % Write Timestamp
%     if(get(GPSP_vars.frames_timestamp, 'Value') || isfield(GPSP_vars, 'customstamp'))
%         if(get(GPSP_vars.node_cum, 'Value'))
%             stamp = 'Cumulative';
%         elseif(isfield(GPSP_vars, 'customstamp'))
%             stamp = GPSP_vars.customstamp;
%         else
%             switch get(GPSP_vars.frames_timestamp_style, 'Value')
%                 case 1 % Start and Stop
%                     stamp = sprintf('%03d to %d ms', tstart, tstop);
%                 case 2 % Start
%                     stamp = sprintf('%03d ms', tstart);
%                 case 3 % Center
%                     stamp = sprintf('%03g ms', (tstart + tstop) / 2);
%             end % which timestamp
%         end % cumulative or not?
%         
%         position = [xlim(GPSP_vars.display_brainaxes) ylim(GPSP_vars.display_brainaxes) zlim(GPSP_vars.display_brainaxes)];
%         if(get(GPSP_vars.act_show, 'Value')); position(5) = position(5) + 40; end
%         h = text(position(2), position(3)+10, position(5)+10,...
%             stamp,...
%             'HorizontalAlignment', 'left',...
%             'VerticalAlignment', 'bottom',...
%             'Color', repmat(get(GPSP_vars.display_bg, 'Value')==4, 3, 1),...
%             'Parent', GPSP_vars.display_brainaxes);
%         set(h, 'FontSize', 14);
%     end
% end % which surface
%     
% %% Label Nodes
% 
% if(get(GPSP_vars.rois_labels, 'Value'))
%     labels = {rois.name};
%     fontsize = str2double(get(GPSP_vars.rois_labels_size, 'String'));
%     fontcolors = [1 1 1; 0.712 0.712 0.712; .5 .5 .5; 0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1];
%     fontcolor = get(GPSP_vars.rois_labels_color, 'Value');
%     fontcolor = fontcolors(fontcolor, :);
%     
%     for i_ROI = 1:N_ROIs
%         if(isempty(labels))
%             nodename = num2str(i_ROI);
%         else
%             nodename = labels{i_ROI};
%         end
% 
%         if(~flag_brain) % Circle
%             text(x_nodes(i_ROI) * 1.2,...
%                 y_nodes(i_ROI) * 1.2,...
%                 nodename,...
%                 'FontSize', fontsize,...
%                 'Color', fontcolor,...
%                 'VerticalAlignment', 'middle',...
%                 'HorizontalAlignment', 'center',...
%                 'Parent', GPSP_vars.display_brainaxes);
% 
% %                 set(h, 'Color', repmat(get(GPSP_vars.display_bg, 'Value') == 4, 3, 1));
%         else % Brain (3D)
% %             if(sum(granger_values(i_ROI, :)) > 0 || sum(granger_values(:, i_ROI)) > 0)
%                 text(x_nodes(i_ROI)* 1.2,...
%                     y_nodes(i_ROI),...
%                     z_nodes(i_ROI),...
%                     nodename,...
%                     'FontSize', fontsize,...
%                     'Color', fontcolor,...
%                     'VerticalAlignment', 'middle',...
%                     'HorizontalAlignment', 'center',...
%                     'FontWeight', 'bold',...
%                     'Parent', GPSP_vars.display_brainaxes);
% 
% %                 set(h, 'Color', repmat(get(GPSP_vars.display_bg, 'Value')==4, 3, 1));
% %         end % If there is causation with this ROI
%         end % Which surface are we plotting on?
%     end % For each ROI
% end % If we are displaying labels
% 
% %% Save Snapshot
% 
% % frame = getframe(GPSP_vars.display_brainaxes);
% % 
% % if(~exist(GPSP_vars.imagefolder, 'dir'))
% %     mkdir(GPSP_vars.imagefolder);
% % end
% % imfile = sprintf('%s/%s_%s_grangers_%dto%d.png',...
% %     GPSP_vars.imagefolder, GPSP_vars.study, GPSP_vars.condition,...
% %     tstart, tstop);
% % imwrite(frame.cdata, imfile, 'png');
% 
% %% Update the GUI
% guidata(hObject, GPSP_vars);
% 
% %% Plot Wave?
% 
% plot_wave(GPSP_vars);

end % function