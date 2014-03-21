function granger_causality_indices = gps_granger(data, model_order, pred_adapt, varargin)
% Performs Granger analysis on the data
%
% Author: A. Conrad Nied (conrad.logos@gmail.com)
%         Ricky Sachdeva
%
% Changelog:
% 2011-02-28 - Originally created as GPS1.6(-)/granger.m
% 2012-04-09 - Last modified in GPS1.6(-)
% 2012-10-11 - Updated to GPS1.7 format
% 2013-07-08 - GPS1.8 General cleaning up
%
% Input: The data matrix of sensors by time, the model order, and the
% factor that the prediction error adapts by, and more specifications if
% they are useful at limiting the data overhead
% Output: The computed granger causality indices

%% Setup

[~, N_ROIs, N_time] = size(data);
granger_causality_indices = zeros(N_ROIs, N_ROIs, N_time);

% Source and Receiving ROIs to be looked at in Granger
if (nargin == 5)
    src_ROIs = varargin{1};
    rcv_ROIs = varargin{2};
else % Do all
    src_ROIs = 1:N_ROIs; % ROIs that are being tested for influence from
    rcv_ROIs = 1:N_ROIs; % ROIs that are being tested to influence on
end

%% Analysis

prediction_error_standard = gps_kalman(data, model_order, pred_adapt);
prediction_errors_withoutROI = zeros(N_ROIs, N_ROIs, N_ROIs, N_time); % Excluded ROI x prediction_error matrix

% For Each ROI that influences another ROI
for i_ROI = src_ROIs
    % Remove the ROI
    ROI_list_without = ones(N_ROIs,1);
    ROI_list_without(i_ROI) = 0;
    ROI_list_without = find(ROI_list_without);
    data_reduced = data(:, ROI_list_without, :);
    
    % Find the prediction error matrix without the ROI
    prediction_error_withoutROI1 = gps_kalman(data_reduced, model_order, pred_adapt);
    
    % Conform this to the full prediction error matrix
    prediction_error_withoutROI = zeros(N_ROIs, N_ROIs, N_time);
    prediction_error_withoutROI(ROI_list_without, ROI_list_without, :) = prediction_error_withoutROI1;
    
    prediction_errors_withoutROI(i_ROI, :, :, :) = prediction_error_withoutROI;
end % For Each ROI

% For Each Time Point (starting at when you can because of the model order)
for i_time = (model_order + 1):N_time;
    
    % For Each ROI (this one is the reduced one)
    for i_ROI = src_ROIs
        
        % For Each ROI (Again)
        for j_ROI = rcv_ROIs
            % Get the prediction error in both models
            prediction_error_withoutROI = prediction_errors_withoutROI(i_ROI, j_ROI, j_ROI, i_time);
            prediction_error = prediction_error_standard(j_ROI, j_ROI, i_time);
            
            % Calculate the difference in the prediction error with and without the ROI
            granger_causality_index = log(prediction_error_withoutROI / prediction_error);
            
            granger_causality_indices(j_ROI, i_ROI, i_time) = granger_causality_index;
        end % For Each ROI
    end % For Each ROI
end % For Each Timepoint

end % function