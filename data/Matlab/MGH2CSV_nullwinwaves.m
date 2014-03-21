function MGH2CSV()
% Reads MGH granger causality over neural indices models
%
% Author: Alexander Conrad Nied (anied@cs.washington.edu)
%
% 2014-03-19

condition = 'words';

%% Load Vertices

% Load Label, X, Y and Z
filename = sprintf('mni_coordinates_%s.csv', condition);
V = csv2struct(filename);
N = length(V);

% Add useful features
for i = 1:N
    label = V(i).label;
    hemisphere = label(1);
    underscore = find(label == '_');
    area = label(3 : underscore - 1);
%     ID = label(underscore + 1 : end);
    switch area
        case {'AG', 'ITG', 'LOC', 'MTG', 'ParsTri', 'SFG', 'SMG', 'SPC', 'STG', 'STS', 'postCG', 'preCG'}
            side = 'L';
        case {'Fusi', 'ParaHip'}
            side = 'M';
    end
    
    V(i).area = area;
    V(i).plot = [hemisphere side];
end % for all vertices

%% Manage Edge Datasets

subconditions = {'HD', 'HF', 'LD', 'LF'};
file = load('PTC3_words_data.mat');
condition = 'wordsnull';

for c = 1:length(subconditions) % for all subconditions
    subcondition = subconditions{c};

    % Load the Data
    description = sprintf('PTC3_%s_%s', condition, subcondition);
    edge_matrix = squeeze(file.results_null(c, :, :, :));
    M = N * N; % Number of edges
    T = size(edge_matrix, 3);
    times = file.file.sample_times;

    % Run clustering
    edge_matrix = edge_matrix > 0;
    edge_sums = sum(edge_matrix, 3);
%     edge_sums = zeros(N);
%     edge_sums([4, 7, 11], [4, 7, 11]) = 200;
%     edge_sums([1 30 31 32 33 40], [1 30 31 32 33 40]) = 300;
%     edge_sums([2 3 6 8 20:23], [2 3 6 8 20:23]) = 150;
%     edge_sums = edge_sums - edge_sums';
    hierarchy = linkage(edge_sums);
    clust10 = cluster(hierarchy, 'maxclust', 10);
    h = figure(6);
    [~, ~, outperm] = dendrogram(hierarchy, N);
    frame = getframe(h);
    filename = sprintf('%s_vertices_clust10_dendrogram.png', description);
    imwrite(frame.cdata, filename, 'png');

    % Form edges structure
    for i = 1:N % For all sources
        for j = 1:N % For all sinks
            e = (i - 1) * N + j;
            E(e).src = i;
            E(e).snk = j;
            E(e).src_label = V(i).label;
            E(e).snk_label = V(j).label;
            E(e).value = edge_sums(i, j);
            for t = 1:T % for all time samples
                E(e).(sprintf('t%03d', times(t)*1000)) = edge_matrix(i, j, t);
            end % for all time
        end  % for all sinks
    end % for all sources

    %% Produce Figures

    edge_display = edge_sums;
    edge_display(:, N + 1) = 0;
    edge_display(N + 1, :) = 0;
    edge_non0 = edge_display;
    edge_non0(edge_non0 == 0) = median(edge_non0(:));
    minval = min(edge_non0(:));
    maxval = max(edge_non0(:));
    
    % Edge Matrix
    h = figure(1);
    clf(h)
    ha = gca;
    surf(0:N, 0:N, ones(N+1), edge_display, 'LineStyle', 'none');
    colorbar;
    caxis([minval maxval])
    titlestr = sprintf('PTC3 %s %s Edge Interactions', condition, subcondition);
    title(titlestr);
    xlabel('Destination Node #');
    ylabel('Source Node #');
    set(ha, 'YDir', 'reverse');
    set(ha, 'XAxisLocation', 'top');
    view(2)
    axis([0 N 0 N]);
    frame = getframe(h);
    filename = sprintf('PTC3_%s_%s_edges_values.png', condition, subcondition);
    imwrite(frame.cdata, filename, 'png');
    
    % Edge Matrix (sorted in clusters)
    h = figure(2);
    clf(h)
    ha = gca;
    surf(0:N, 0:N, ones(N+1), edge_display([outperm N+1], [outperm N+1]), 'LineStyle', 'none');
    colorbar;
    caxis([minval maxval])
    titlestr = sprintf('PTC3 %s %s Edge Interactions (Arranged by Clustering)', condition, subcondition);
    title(titlestr);
    xlabel('Destination Node #');
    ylabel('Source Node #');
    set(ha, 'YDir', 'reverse');
    set(ha, 'XAxisLocation', 'top');
    view(2)
    axis([0 N 0 N]);
    frame = getframe(h);
    filename = sprintf('PTC3_%s_%s_edges_values_arrangedbyclustering.png', condition, subcondition);
    imwrite(frame.cdata, filename, 'png');

%     % Scatter of Points in 3D Space, labeled by clusters
%     h = figure(4);
%     clf(h);
%     ha = gca;
%     scatter3([V.xcoord], [V.ycoord], [V.zcoord], ones(N, 1) * 10, [V.clust10]);
%     title('Coactivation Points Clustered');
%     xlabel('X: Right(+) to Left(-)');
%     ylabel('Y: Anterior(+) to Posterior(-)');
%     zlabel('Z: Superior(+) to Inferior(-)');
%     view(3)
%     frame = getframe(h);
%     filename = sprintf('PTC3_%s_%s_vertices_clust10.png', condition, subcondition);
%     imwrite(frame.cdata, filename, 'png');
%     view(2)
%     frame = getframe(h);
%     filename = sprintf('PTC3_%s_%s_vertices_clust10_overhead.png', condition, subcondition);
%     imwrite(frame.cdata, filename, 'png');

    % Edges in 3D Space, plot only the top 2*N highest though (or we may never
    % stop rendering)
    h = figure(5);
    clf(h);
    ha = gca;
    cmap = jet(maxval - minval);
    for i = 1:N
        for j = (i + 1):N
            val = floor(mean([edge_sums(i, j) edge_sums(j, i)]));
            line([V(i).xcoord V(j).xcoord],...
                [V(i).ycoord V(j).ycoord],...
                [V(i).zcoord V(j).zcoord],...
                'Color', cmap(val - minval, :));
        end
    end
            
    titlestr = sprintf('PTC3 %s %s Edges (mean of both sides)', condition, subcondition);
    title(titlestr);
    xlabel('X: Right(+) to Left(-)');
    ylabel('Y: Anterior(+) to Posterior(-)');
    zlabel('Z: Superior(+) to Inferior(-)');
    view(3)
    frame = getframe(h);
    filename = sprintf('PTC3_%s_%s_edges.png', condition, subcondition);
    imwrite(frame.cdata, filename, 'png');
    view(2)
    frame = getframe(h);
    filename = sprintf('PTC3_%s_%s_edges_overhead.png', condition, subcondition);
    imwrite(frame.cdata, filename, 'png');

    %% Save Data as CSV

    filename = sprintf('PTC3_%s_%s_E.csv', condition, subcondition);
    struct2csv(E, filename);
end % for all conditions

end % function