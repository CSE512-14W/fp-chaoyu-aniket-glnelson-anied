function MGH2CSV()
% Reads MGH granger causality over neural indices models
%
% Author: Alexander Conrad Nied (anied@cs.washington.edu)
%
% 2014-03-16 to 18

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

for c = 1:length(subconditions) % for all subconditions
    subcondition = subconditions{c};

    % Load the Data
    filefind = dir(sprintf('/homes/gws/anied/CSE512/Datasets/MGH/PTC3_%s_%s*.mat', subcondition, condition));
    file(c) = load(filefind(end).name);
    
    results(c, :, :, :) = file(c).results;

    %% Save Data as CSV
% 
%     filename = sprintf('PTC3_%s_%s_E.csv', condition, subcondition);
%     struct2csv(E, filename);
end % for all conditions

flat_results = results(:);
flat_results(flat_results > 10) = [];
flat_results(flat_results < -10) = [];
hist(flat_results, 400);

% Save as picture
figure(1)
results_mean = mean(flat_results);
results_std = std(flat_results);
results_skew = skewness(flat_results);
results_kurt = kurtosis(flat_results);
titlestr = sprintf('PTC3 %s GCI Distribution\nmu: %.2f    std: %.2f    skew: %.2f    kurt:%.2f', condition, results_mean, results_std, results_skew, results_kurt);
title(titlestr);
ylabel('Count of GCI');
xlabel('GCI Bins');
ylim([0, 3e5]);
xlim([-1.5, 1.5]);
frame = getframe(gcf);
filename = sprintf('PTC3_%s_gci_distribution.png', condition);
imwrite(frame.cdata, filename, 'png');

% Make null models
for c = 1:length(subconditions)
    fprintf('Making Null Hypotheses for %s\n', subconditions{c});
    act = file(c).act;
    dims = size(act);
    data = reshape(act(randperm(prod(dims))), dims);

    results_null(c, :, :, :) = gps_granger(data, file(c).model_order, file(c).pred_adapt);
end

flat_results = results_null(:);
flat_results(flat_results > 10) = [];
flat_results(flat_results < -10) = [];
hist(flat_results, 400);

% Save as picture
results_mean = mean(flat_results);
results_std = std(flat_results);
results_skew = skewness(flat_results);
results_kurt = kurtosis(flat_results);
titlestr = sprintf('PTC3 %s GCI Null Distribution (Random cortical activity)\nmu: %.2f    std: %.2f    skew: %.2f    kurt:%.2f', condition, results_mean, results_std, results_skew, results_kurt);
title(titlestr);
ylabel('Count of GCI');
xlabel('GCI Bins');
ylim([0, 3e5]);
xlim([-1.5, 1.5]);
frame = getframe(gcf);
filename = sprintf('PTC3_%s_gci_null_distribution.png', condition);
imwrite(frame.cdata, filename, 'png');

save('PTC3_words_data.mat');

end % function