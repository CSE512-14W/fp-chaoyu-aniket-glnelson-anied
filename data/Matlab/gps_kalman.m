function varargout = gps_kalman(data, model_order, pred_adapt)
% Performs Kalman analysis on the data as a part of granger processing
%
% Author: A. Conrad Nied
%
% Changelog:
% 2012.03.12 - Originally created as GPS1.6(-)/kalman.m
% 2012.03.28 - Last modified in GPS1.6(-)
% 2012.10.11 - Updated to GPS1.7 format

% M: Milde
% H: Havlicek, M et al. / NeuroImage 53 (2010) 65-77

tbegin = tic;
conrad = 1;

%% Set Parameters

% Set constants
[N_trials N_ROIs N_time] = size(data); % k, d, and N

% pred_adapt = .03;
state_adapt = pred_adapt; % C, State Adaptation aka Fading Memory Weight
pred_adapt = pred_adapt; % c, Prediction Adaptation

N_order = model_order; % p
N_past = N_ROIs * N_order; % d*p

% Setup output variables
if (nargout == 1)
    simple_granger = true;
    all_pred_noise_cov = zeros(N_ROIs, N_ROIs, N_time);
else
    simple_granger = false;
    all_state_process = zeros(N_past, N_ROIs, N_time);
    all_pred_noise_cov = zeros(N_ROIs, N_ROIs, N_time);
    all_residual = zeros(N_trials, N_ROIs, N_time);
end

% Ricky OR Conrad
if(conrad)

% Set Kalman initial conditions
state_transition = eye(N_past); % G

state_process = zeros(N_past, N_ROIs); % Q_p = 0
pred_noise_cov = eye(N_ROIs) * 0;%1e-25; % W_p = I_d
state_cov = eye(N_past); % P_p = I_dp

state_noise_cov = state_adapt * eye(N_past); % Vbar_n = C * I_dp;
%     % H: Q_t = I * lamdba * trace(P_t|t-1) / (p * N)
%     state_noise_cov = eye(N_past) * state_adapt * trace(state_cov) / ...
%         (N_order * N_time);
%     % M: P_n = G_n-1 * P+_n-1 * G_n-1' + Vbar_n
%     state_cov = state_transition * state_cov * state_transition' + ...
%         state_noise_cov;

% Compute for all time points in the model, n = p + 1 : N
for i_time = (N_order + 1) : N_time
    
    %% Get the Data
    
    % M: H_n = (O_n-1, ..., O_n-p)
%     past_data = data(:, :, i_time - (1:N_order));
    past_data = data(:, :, i_time - (N_order:-1:1));
    past_data = reshape(past_data, N_trials, N_past);
    
    % M: O(n)
    cur_data = squeeze(data(:, :, i_time));
    
    %% Prediction Error
    
    % 'M': (O_n - Q_n-1) reinterpreted as (O_n - H_n * Q_n-1)
    % H: e_t = y_t - C_t-1' * a_t|t-1
    residual = cur_data - past_data * state_process;
    
    %% Prediction Noise Covariance
    % M: Wbar_n = Wbar_n-1 * (1-c) + c * (O_n - Q_n-1)'(O_n - Q_n-1)/(k-1)
%     pred_noise_cov = (1 - pred_adapt) * pred_noise_cov + ...
%         pred_adapt * (pred_error') * pred_error / (N_trials - 1);
    
    % H: R_t = (1 - lambda) * R_t-1 + lambda * e_t^2, note no /N_trials
    pred_noise_cov = (1 - pred_adapt) * pred_noise_cov + ...
        pred_adapt * (residual') * residual;
    
    %% Kalman Gain Matrix
    % Filter gain, tells us how much the prediction state process should be
    % corrected on the current time step.
    
    % M: S_n = H_n * P_n-1 * H_n' + tr(Wbar_n) * I_k
    trial_cov = past_data * state_cov * past_data' + ...
        trace(pred_noise_cov) * eye(N_trials);
    
    % M: K_n = P_n-1 * H_n' / S_n
    kalman_gain = state_cov * past_data' / trial_cov;
%     kalman_gain = state_cov * past_data' * inv(trial_cov);

    % H: P_t|t-1 * C_t-1 (C_t-1' * P_t|t-1 * C_t-1 + R_t)^-1
    % Note that this equation does not take the trace of the noise
    % covariance but uses the whole thing, potentially different
%     trial_cov = past_data * state_cov * past_data' + ...
%         trace(pred_noise_cov) * eye(N_trials); % indirect implementation
%     kalman_gain = state_cov * past_data' / trial_cov;

    %% Compute the state process
    
    % M: Q+_n-1 = Q_n-1 + K_n (O_n - H_n * Q_n-1);
    state_process = state_process + kalman_gain * residual;
    
    % M: Q_n = G_n-1 * Q+_n-1
    state_process = state_transition * state_process;
    
    %% Compute the state covariance
    
    % M: P+_n-1 = (I_dp - K_n * H_n) P_n-1
    state_cov = (eye(N_past) - kalman_gain * past_data) * ...
        state_cov;
    
    % Havlicek recalculates the state noise covariance
    % H: Q_t = I * lamdba * trace(P_t|t-1) / (p * N)
%     state_noise_cov = eye(N_past) * state_adapt * trace(state_cov) / ...
%         (N_order * N_time);
    
    % M: P_n = G_n-1 * P+_n-1 * G_n-1' + Vbar_n
    state_cov = state_transition * state_cov * state_transition' + ...
        state_noise_cov;
    
    %% Save Timepoint Information
    
    if (simple_granger)
        all_pred_noise_cov(:, :, i_time) = pred_noise_cov;
    else
        all_state_process(:, :, i_time) = state_process;
        all_pred_noise_cov(:, :, i_time) = pred_noise_cov;
        all_residual(:, :, i_time) = residual;
    end
    
end % for all time points

else % ricky
    [all_state_process, all_pred_noise_cov, all_residual] = rs_kalman(data, model_order, N_trials, N_ROIs, pred_adapt);
end

% toc(tbegin)

%% Configure Output

if (simple_granger)
    varargout(1) = {all_pred_noise_cov};
else
    varargout(1) = {all_state_process};
    varargout(2) = {all_pred_noise_cov};
    varargout(3) = {all_residual};
end

end % function