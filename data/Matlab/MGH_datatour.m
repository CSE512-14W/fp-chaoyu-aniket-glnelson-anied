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

% filename = sprintf('PTC3_%s_V.csv', condition);
% struct2csv(V, filename);
  
% % Scatter of Points in 3D Space
% h = figure(3);
% clf(h);
% ha = gca;
% scatter3([V.xcoord], [V.ycoord], [V.zcoord], ones(N, 1) * 10, 'b');
% titlestr = sprintf('PTC3 %s Points', condition);
% title(titlestr);
% xlabel('X: Right(+) to Left(-)');
% ylabel('Y: Anterior(+) to Posterior(-)');
% zlabel('Z: Superior(+) to Inferior(-)');
% view(3)
% frame = getframe(h);
% filename = sprintf('PTC3_%s_vertices.png', condition);
% imwrite(frame.cdata, filename, 'png');
% view(2)
% frame = getframe(h);
% filename = sprintf('PTC3_%s_vertices_overhead.png', condition);
% imwrite(frame.cdata, filename, 'png');

%% Manage Edge Datasets

subconditions = {'HD', 'HF', 'LD', 'LF'};
nullfile = load('PTC3_words_data.mat');
% nullfile = load('PTCs_words_nullwinwaves.mat');

percentiles = [.95 .99];
quantiles = quantile(nullfile.results_null(:), percentiles);

% Plot Activity
figure(1)
plot(nullfile.file(4).sample_times, squeeze(nullfile.file(4).act(1, 1:2, :))')
xlim([min(nullfile.file(4).sample_times) max(nullfile.file(4).sample_times)]);
roiA = nullfile.file(1).rois{1}; roiA(roiA == '_') = '-';
roiB = nullfile.file(1).rois{2}; roiB(roiB == '_') = '-';
legend({roiA, roiB});
xlabel('Time (s)');
ylabel('Strength of Activity (Tesla)');
titlestr = sprintf('Averaged Cortical Activity of Subject PTC3\\_02\n perceiving LF (low phonetic-frequency) words');
title(titlestr);
frame = getframe(gcf);
filename = sprintf('background_cortact.png');
imwrite(frame.cdata, filename, 'png');
ylim_cortact = ylim;

% Plot regular GCIs
figure(2)
plot(nullfile.file(4).sample_times, squeeze([nullfile.file(4).results(1, 2, :) nullfile.file(4).results(2, 1, :)])')
line(xlim, [quantiles(1) quantiles(1)], 'Color', 'r');
line(xlim, [quantiles(2) quantiles(2)], 'Color', 'm');
xlim([min(nullfile.file(4).sample_times) max(nullfile.file(4).sample_times)]);
ylim_gci = ylim;
roiA = nullfile.file(1).rois{1}; roiA(roiA == '_') = '-';
roiB = nullfile.file(1).rois{2}; roiB(roiB == '_') = '-';
A2B = sprintf('%s to %s', roiA, roiB); B2A = sprintf('%s to %s', roiB, roiA); 
legend({A2B, B2A, '95th Percentile of Null', '99th Percentile of Null'});
xlabel('Time (s)');
ylabel('Granger Causality Index (GCI, log ratio)');
titlestr = sprintf('Causality between areas as predicted by group cortical activity\n perceiving LF (low phonetic-frequency) words');
title(titlestr);
frame = getframe(gcf);
filename = sprintf('background_gci.png');
imwrite(frame.cdata, filename, 'png');

% Plot jumbled Activity
figure(202)
plot(nullfile.file(4).sample_times, squeeze(nullfile.data(1, 1:2, :))')
xlim([min(nullfile.file(4).sample_times) max(nullfile.file(4).sample_times)]);
ylim(ylim_cortact)
legend({roiA, roiB});
xlabel('Time (s)');
ylabel('Strength of Activity (Tesla)');
titlestr = sprintf('Jumbled Averaged Cortical Activity of Subject PTC3\\_02\n perceiving LF (low phonetic-frequency) words');
title(titlestr);

% Plot null GCIs
figure(203)
plot(nullfile.file(4).sample_times, squeeze([nullfile.results_null(4, 1, 2, :) nullfile.results_null(4, 2, 1, :)])')
line(xlim, [quantiles(1) quantiles(1)], 'Color', 'r');
line(xlim, [quantiles(2) quantiles(2)], 'Color', 'm');
xlim([min(nullfile.file(4).sample_times) max(nullfile.file(4).sample_times)]);
ylim(ylim_gci)
roiA = nullfile.file(1).rois{1}; roiA(roiA == '_') = '-';
roiB = nullfile.file(1).rois{2}; roiB(roiB == '_') = '-';
A2B = sprintf('%s to %s', roiA, roiB); B2A = sprintf('%s to %s', roiB, roiA); 
legend({A2B, B2A, '95th Percentile of Null', '99th Percentile of Null'});
xlabel('Time (s)');
ylabel('Granger Causality Index (GCI, log ratio)');
titlestr = sprintf('Causality between areas as predicted by null model\nmade by randomly permuting original cortical activity');
title(titlestr);
frame = getframe(gcf);
filename = sprintf('background_gcinull.png');
imwrite(frame.cdata, filename, 'png');

% Plot discretized GCI
res = squeeze([nullfile.file(4).results(1, 2, :) nullfile.file(4).results(2, 1, :)])';

% draw in segments > 0
figure(10)
clf

subplot(3, 1, 1)
xlim([0 600]);
ylim([0.5 2.5]);
set(gca, 'YTickLabel', {B2A, A2B});
titlestr = sprintf('Discretized Causality: Above 99th percentile of null model(%2.2f)', quantiles(2));
title(titlestr);

subplot(3, 1, 2)
xlim([0 600]);
ylim([0.5 2.5]);
set(gca, 'YTickLabel', {B2A, A2B});
titlestr = sprintf('Discretized Causality: Above 95th percentile of null model(%2.2f)', quantiles(1));
title(titlestr);

subplot(3, 1, 3)
xlim([0 600]);
ylim([0.5 2.5]);
set(gca, 'YTickLabel', {B2A, A2B});
title('Discretized Causality: all GCIs above 0 (50th percentile in the null model)');
xlabel('Time (ms)');

sign0 = res > 0;
sign95 = res > quantiles(1);
sign99 = res > quantiles(2);
for i = 1:600
    subplot(3, 1, 1)
    if(sign99(i, 1) && sign0(i, 1))
        line([i - 1 i], [1 1] * 1, 'Color', 'b');
    end
    if(sign99(i, 2) && sign0(i, 2))
        line([i - 1 i], [1 1] * 2, 'Color', 'g');
    end
    
    subplot(3, 1, 2)
    if(sign95(i, 1) && sign0(i, 1))
        line([i - 1 i], [1 1] * 1, 'Color', 'b');
    end
    if(sign95(i, 2) && sign0(i, 2))
        line([i - 1 i], [1 1] * 2, 'Color', 'g');
    end
    
    subplot(3, 1, 3)
    if(sign0(i, 1) && sign0(i, 1))
        line([i - 1 i], [1 1] * 1, 'Color', 'b');
    end
    if(sign0(i, 2) && sign0(i, 2))
        line([i - 1 i], [1 1] * 2, 'Color', 'g');
    end
end



figure(10)
plot(nullfile.file(4).sample_times, squeeze([nullfile.file(4).results(1, 2, :) nullfile.file(4).results(2, 1, :)])')
line(xlim, [quantiles(1) quantiles(1)], 'Color', 'r');
line(xlim, [quantiles(2) quantiles(2)], 'Color', 'm');
xlim([min(nullfile.file(4).sample_times) max(nullfile.file(4).sample_times)]);
ylim_gci = ylim;
roiA = nullfile.file(1).rois{1}; roiA(roiA == '_') = '-';
roiB = nullfile.file(1).rois{2}; roiB(roiB == '_') = '-';
A2B = sprintf('%s to %s', roiA, roiB); B2A = sprintf('%s to %s', roiB, roiA); 
legend({A2B, B2A, '95th Percentile of Null', '99th Percentile of Null'});
xlabel('Time (s)');
ylabel('Granger Causality Index (GCI, log ratio)');
titlestr = sprintf('Causality between areas as predicted by group cortical activity\n perceiving LF (low phonetic-frequency) words');
title(titlestr);
frame = getframe(gcf);
filename = sprintf('background_gci.png');
imwrite(frame.cdata, filename, 'png');


return
condi = condition;

for q = 1:length(quantiles)
    quant = quantiles(q);
    conditionsave = sprintf('%s%02.0f', condi, percentiles(q)*100);

for c = 1:length(subconditions) % for all subconditions
    subcondition = subconditions{c};

    % Load the Data
    description = sprintf('PTC3_%s_%s', conditionsave, subcondition);
    filefind = dir(sprintf('PTC3_%s_%s*.mat', subcondition, condition));
    file = load(filefind(end).name);
    edge_matrix = file.results;
    M = N * N; % Number of edges
    T = size(edge_matrix, 3);
    times = file.sample_times;

    % Run clustering
    edge_matrix = edge_matrix > quant;
    edge_sums = sum(edge_matrix, 3);
%     edge_sums = zeros(N);
%     edge_sums([4, 7, 11], [4, 7, 11]) = 200;
%     edge_sums([1 30 31 32 33 40], [1 30 31 32 33 40]) = 300;
%     edge_sums([2 3 6 8 20:23], [2 3 6 8 20:23]) = 150;
%     edge_sums = edge_sums - edge_sums';
    hierarchy = linkage(edge_sums);
    clust10 = cluster(hierarchy, 'maxclust', 10);
    % h = figure(6);
    % [~, ~, outperm] = dendrogram(hierarchy, N);
    % frame = getframe(h);
    % filename = sprintf('%s_vertices_clust10_dendrogram.png', description);
    % imwrite(frame.cdata, filename, 'png');

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
    
    % % Edge Matrix
    % h = figure(1);
    % clf(h)
    % ha = gca;
    % surf(0:N, 0:N, ones(N+1), edge_display, 'LineStyle', 'none');
    % colorbar;
    % caxis([minval maxval])
    % titlestr = sprintf('PTC3 %s %s Edge Interactions', conditionsave, subcondition);
    % title(titlestr);
    % xlabel('Destination Node #');
    % ylabel('Source Node #');
    % set(ha, 'YDir', 'reverse');
    % set(ha, 'XAxisLocation', 'top');
    % view(2)
    % axis([0 N 0 N]);
    % frame = getframe(h);
    % filename = sprintf('PTC3_%s_%s_edges_values.png', conditionsave, subcondition);
    % imwrite(frame.cdata, filename, 'png');
    
    % % Edge Matrix (sorted in clusters)
    % h = figure(2);
    % clf(h)
    % ha = gca;
    % surf(0:N, 0:N, ones(N+1), edge_display([outperm N+1], [outperm N+1]), 'LineStyle', 'none');
    % colorbar;
    % caxis([minval maxval])
    % titlestr = sprintf('PTC3 %s %s Edge Interactions (Arranged by Clustering)', conditionsave, subcondition);
    % title(titlestr);
    % xlabel('Destination Node #');
    % ylabel('Source Node #');
    % set(ha, 'YDir', 'reverse');
    % set(ha, 'XAxisLocation', 'top');
    % view(2)
    % axis([0 N 0 N]);
    % frame = getframe(h);
    % filename = sprintf('PTC3_%s_%s_edges_values_arrangedbyclustering.png', conditionsave, subcondition);
    % imwrite(frame.cdata, filename, 'png');

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
    % h = figure(5);
    % clf(h);
    % ha = gca;
    % cmap = jet(maxval - minval);
    % for i = 1:N
    %     for j = (i + 1):N
    %         val = floor(mean([edge_sums(i, j) edge_sums(j, i)]));
    %         line([V(i).xcoord V(j).xcoord],...
    %             [V(i).ycoord V(j).ycoord],...
    %             [V(i).zcoord V(j).zcoord],...
    %             'Color', cmap(val - minval, :));
    %     end
    % end
            
    % titlestr = sprintf('PTC3 %s %s Edges (mean of both sides)', conditionsave, subcondition);
    % title(titlestr);
    % xlabel('X: Right(+) to Left(-)');
    % ylabel('Y: Anterior(+) to Posterior(-)');
    % zlabel('Z: Superior(+) to Inferior(-)');
    % view(3)
    % frame = getframe(h);
    % filename = sprintf('PTC3_%s_%s_edges.png', conditionsave, subcondition);
    % imwrite(frame.cdata, filename, 'png');
    % view(2)
    % frame = getframe(h);
    % filename = sprintf('PTC3_%s_%s_edges_overhead.png', conditionsave, subcondition);
    % imwrite(frame.cdata, filename, 'png');

    %% Save Data as CSV

    filename = sprintf('PTC3_%s_%s_E.csv', conditionsave, subcondition);
    struct2csv(E, filename);
end % for all conditions

end % for all quantiles

end % function