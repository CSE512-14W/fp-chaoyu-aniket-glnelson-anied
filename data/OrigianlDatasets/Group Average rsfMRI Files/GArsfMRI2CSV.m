function GArsfMRI2CSV()
% Reads the coactivation matrix file and produces images, vertex list, and
% edge list
%
% Author: Alexander Conrad Nied (anied@cs.washington.edu)
%
% 2014-03-02

%% Process Data

% Load the Data
file = load('GroupAverage_rsfMRI_matrix.mat');
edge_matrix = file.GroupAverage_rsfMRI;
vertex_coords = file.Coord;
N = length(vertex_coords);
% M = N * N; % Number of edges

% Run clustering
hierarchy = linkage(1 - edge_matrix);
clust10 = cluster(hierarchy, 'maxclust', 10);
h = figure(6);
[~, ~, outperm] = dendrogram(hierarchy, N);
frame = getframe(h);
filename = 'GArsfMRI_vertices_clust10_dendrogram.png';
imwrite(frame.cdata, filename, 'png');

% Form vertex structure
for i = 1:N
    V(i).label = num2str(i);
    V(i).xcoord = vertex_coords(i, 1);
    V(i).ycoord = vertex_coords(i, 2);
    V(i).zcoord = vertex_coords(i, 3);
    V(i).clust10 = clust10(i);
end % For all vertices

% Form edges structure
for i = 1:N % For all sources
    for j = 1:N % For all sinks
        e = (i - 1) * N + j;
        E(e).src = i;
        E(e).snk = j;
%         E(e).src_label = V(i).label;
%         E(e).snk_label = V(j).label;
        E(e).value = edge_matrix(i, j);
%         E(e).src_xcoord = V(i).xcoord;
%         E(e).src_ycoord = V(i).ycoord;
%         E(e).src_zcoord = V(i).zcoord;
%         E(e).snk_xcoord = V(j).xcoord;
%         E(e).snk_ycoord = V(j).ycoord;
%         E(e).snk_zcoord = V(j).zcoord;
    end
end

% Remove edges that have 0 values
E([E.value] == 0) = [];

%% Produce Figures

% Edge Matrix
h = figure(1);
clf(h)
image(edge_matrix / max(edge_matrix(:)) * 255);
% caxis([min(edge_matrix(:)) max(edge_matrix(:))]);
% colorbar;
title('Group Average rsfMRI Edge Strength');
xlabel('Destination Node #');
ylabel('Source Node #');
% set(h, 'XAxisLocation', 'top');
pause(10);
frame = getframe(h);
filename = 'GArsfMRI_edge_values.png';
imwrite(frame.cdata, filename, 'png');

% Edge Matrix (sorted in clusters)
h = figure(2);
clf(h)
ha = gca;
image(edge_matrix(outperm, outperm) / max(edge_matrix(:)) * 255);
% set(ha, 'CLim', [min(edge_matrix(:)) max(edge_matrix(:))]);
% colorbar;
% caxis([min(edge_matrix(:)) max(edge_matrix(:))]);
title('Group Average rsfMRI Edge Strength (Arranged by Clustering)');
% xlabel('Node #');
% ylabel('Node #');
% set(ha, 'XAxisLocation', 'top');
axis('off')
pause(10);
frame = getframe(h);
filename = 'GArsfMRI_edge_values_arrangedbyclustering.png';
imwrite(frame.cdata, filename, 'png');

% Scatter of Points in 3D Space
h = figure(3);
clf(h);
ha = gca;
scatter3([V.xcoord], [V.ycoord], [V.zcoord], ones(N, 1) * 10, 'b');
title('Group Average rsfMRI Points');
xlabel('X: Right(+) to Left(-)');
ylabel('Y: Anterior(+) to Posterior(-)');
zlabel('Z: Superior(+) to Inferior(-)');
view(3)
pause(10);
frame = getframe(h);
filename = 'GArsfMRI_vertices.png';
imwrite(frame.cdata, filename, 'png');
view(2)
pause(10);
frame = getframe(h);
filename = 'GArsfMRI_vertices_overhead.png';
imwrite(frame.cdata, filename, 'png');

% Scatter of Points in 3D Space, labeled by clusters
h = figure(4);
clf(h);
ha = gca;
scatter3([V.xcoord], [V.ycoord], [V.zcoord], ones(N, 1) * 10, [V.clust10]);
title('Group Average rsfMRI Points Clustered');
xlabel('X: Right(+) to Left(-)');
ylabel('Y: Anterior(+) to Posterior(-)');
zlabel('Z: Superior(+) to Inferior(-)');
view(3)
pause(10);
frame = getframe(h);
filename = 'GArsfMRI_vertices_clust10.png';
imwrite(frame.cdata, filename, 'png');
view(2)
pause(10);
frame = getframe(h);
filename = 'GArsfMRI_vertices_clust10_overhead.png';
imwrite(frame.cdata, filename, 'png');

% Edges in 3D Space, plot only the top 2*N highest though (or we may never
% stop rendering)
h = figure(5);
clf(h);
ha = gca;
[~, e_vals_sortedi] = sort([E.value], 'descend');
for i = 1:(2 * N) % for all edges
    e = e_vals_sortedi(i);
    line([V(E(e).src).xcoord, V(E(e).snk).xcoord],...
        [V(E(e).src).ycoord, V(E(e).snk).ycoord],...
        [V(E(e).src).zcoord, V(E(e).snk).zcoord]);
end % for all edges
title('Group Average rsfMRI Edges');
xlabel('X: Right(+) to Left(-)');
ylabel('Y: Anterior(+) to Posterior(-)');
zlabel('Z: Superior(+) to Inferior(-)');
view(3)
pause(10);
frame = getframe(h);
filename = 'GArsfMRI_edges.png';
imwrite(frame.cdata, filename, 'png');
view(2)
pause(10);
frame = getframe(h);
filename = 'GArsfMRI_edges_overhead.png';
imwrite(frame.cdata, filename, 'png');

%% Save Data as CSV

struct2csv(V, 'GArsfMRI_V.csv');
struct2csv(E, 'GArsfMRI_E.csv');

end % function