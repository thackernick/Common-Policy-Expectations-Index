clear all; clc;


FFF_data = rmmissing(readtable('CrystalBall_Data(Market).xlsx', 'Sheet', 'FFF'));
OIS_data = rmmissing(readtable('CrystalBall_Data(Market).xlsx', 'Sheet', 'OIS'));
EFFR_data = rmmissing(readtable('CrystalBall_Data(Market).xlsx', 'Sheet', 'EFFR'));
Bluechip_data = readtable('bc_surv_exp.xls'); 


FFF_data(1, :) = [];
OIS_data(1, :) = [];
EFFR_data(1, :) = [];

% Rename 'Var1' to 'Date' in all datasets 
FFF_data.Properties.VariableNames{'Var1'} = 'Date';
OIS_data.Properties.VariableNames{'Var1'} = 'Date';
EFFR_data.Properties.VariableNames{'Var1'} = 'Date';
Bluechip_data.Properties.VariableNames{'DATE'} = 'Date'; 

%% Convert tables to timetables
FFF_tt = table2timetable(FFF_data);
OIS_tt = table2timetable(OIS_data);
EFFR_tt = table2timetable(EFFR_data);
Bluechip_tt = table2timetable(Bluechip_data);

% Resample each timetable to monthly data (taking the last day of each month)
FFF_monthly = retime(FFF_tt, 'monthly', 'lastvalue');
OIS_monthly = retime(OIS_tt, 'monthly', 'lastvalue');
EFFR_monthly = retime(EFFR_tt, 'monthly', 'lastvalue');
Bluechip_monthly = retime(Bluechip_tt, 'monthly', 'lastvalue');

% Select the relevant columns for the 6 month analysis
FFF_6month = FFF_monthly(:, {'FF6Comdty'});
OIS_6month = OIS_monthly(:, {'USSOFCurncy'});
Bluechip_6month = Bluechip_monthly(:, {'RFF_FF_F2'});
EFFR = EFFR_monthly(:, {'Var2'});   

%% Convert FF3Comdty to double and subtract from 100 if needed
if ismember('FF6Comdty', FFF_6month.Properties.VariableNames)
    if ~isnumeric(FFF_6month.FF6Comdty)
        FFF_6month.FF6Comdty = str2double(FFF_6month.FF6Comdty);
    end
    FFF_6month.FF6Comdty = 100 - FFF_6month.FF6Comdty;
else
    warning('The column "FF6Comdty" does not exist in FFF_6month.');
end

%% Merge all
merged_data = synchronize(FFF_6month, OIS_6month, Bluechip_6month, EFFR);

% Create lag for 6-month analysis
EFFR_lag = merged_data.Var2(7:end);  % Lagging by 6 months
FedFundsFutures_lag = merged_data.FF6Comdty(1:end-6);
OIS_lag = merged_data.USSOFCurncy(1:end-6);
BlueChipSurvey_lag = merged_data.RFF_FF_F2(1:end-6);

lagged_data = timetable(merged_data.Date(7:end), EFFR_lag, FedFundsFutures_lag, OIS_lag, BlueChipSurvey_lag, ...
                        'VariableNames', {'EFFR_lag', 'FedFundsFutures_lag', 'OIS_lag', 'BlueChipSurvey_lag'});

% Remove rows with NaN values from lagged_data & removing covid period if necessary
lagged_data = rmmissing(lagged_data);
% lagged_data = lagged_data(lagged_data.Time<datetime('01-Jan-2020'),:);

% Extract the variables from lagged_data 
EFFR = lagged_data.EFFR_lag;
FedFundsFutures = lagged_data.FedFundsFutures_lag;
OIS = lagged_data.OIS_lag;
BlueChipSurvey = lagged_data.BlueChipSurvey_lag;
%% function to print results with significance levels
function displayWithSignificance(label, value1, value2)
    if nargin == 2  % For tests like Diebold-Mariano
        p_val = normcdf(-abs(value1));  % Two-tailed test
        stars = getSignificanceStars(p_val);
        fprintf('%s: %.3f %s (p = %.3f)\n', label, value1, stars, p_val);
    elseif nargin == 3  % For errors (MSE, RMSE)
        fprintf('%s - MSE: %.3f, RMSE: %.3f\n', label, value1, value2);
    end
end

%% function to determine significance stars based on p-value
function stars = getSignificanceStars(p_val)
    if p_val < 0.01
        stars = '***';  % p < 0.01
    elseif p_val < 0.05
        stars = '**';   % 0.01 <= p < 0.05
    elseif p_val < 0.10
        stars = '*';    % 0.05 <= p < 0.10
    else
        stars = '';     % Not significant
    end
end






%% Calculate errors
error_Futures = EFFR - FedFundsFutures;
error_OIS = EFFR - OIS;
error_BlueChip = EFFR - BlueChipSurvey;

% Mean Squared Error for each measure
MSE_Futures = mean(error_Futures.^2);
MSE_OIS = mean(error_OIS.^2);
MSE_BlueChip = mean(error_BlueChip.^2);

% Root Mean Squared Error 
RMSE_Futures = sqrt(MSE_Futures);
RMSE_OIS = sqrt(MSE_OIS);
RMSE_BlueChip = sqrt(MSE_BlueChip);

%% Display error metrics
fprintf('\nError Metrics:\n');
displayWithSignificance('Fed Funds Futures', MSE_Futures, RMSE_Futures);
displayWithSignificance('OIS', MSE_OIS, RMSE_OIS);
displayWithSignificance('Blue Chip Survey', MSE_BlueChip, RMSE_BlueChip);
%% Diebold-Mariano Test
%T = length();  % Sample size

% Diebold-Mariano Test for Fed Funds Futures vs OIS
d = (error_Futures.^2) - (error_OIS.^2);
T = length(d);
dBar = mean(d);  % Mean of differences
DM_num = dBar;
DM_den = sqrt(sum((d - dBar).^2) / T^2);  % Standard error of differences
DM_Futures_OIS = DM_num / DM_den;

% Diebold-Mariano Test for Fed Funds Futures vs Blue Chip Survey
d = (error_Futures.^2) - (error_BlueChip.^2);
dBar = mean(d);
DM_num = dBar;
DM_den = sqrt(sum((d - dBar).^2) / T^2);
DM_Futures_BlueChip = DM_num / DM_den;

% Diebold-Mariano Test for OIS vs Blue Chip Survey
d = (error_OIS.^2) - (error_BlueChip.^2);
dBar = mean(d);
DM_num = dBar;
DM_den = sqrt(sum((d - dBar).^2) / T^2);
DM_OIS_BlueChip = DM_num / DM_den;


fprintf('\nDiebold-Mariano Test Results:\n');
displayWithSignificance('Futures vs OIS', DM_Futures_OIS);
displayWithSignificance('Futures vs Blue Chip', DM_Futures_BlueChip);
displayWithSignificance('OIS vs Blue Chip', DM_OIS_BlueChip);
%% Clark-West test stats
CW_Futures_OIS = zeros(T, 1);
CW_Futures_BlueChip = zeros(T, 1);
CW_OIS_BlueChip = zeros(T, 1);

for t = 1:T
    % Futures vs OIS
    f1 = error_Futures(t)^2;
    f2 = error_OIS(t)^2 - (FedFundsFutures(t) - OIS(t))^2;
    CW_Futures_OIS(t) = f1 - f2;

    % Futures vs Blue Chip Survey
    f1 = error_Futures(t)^2;
    f2 = error_BlueChip(t)^2 - (FedFundsFutures(t) - BlueChipSurvey(t))^2;
    CW_Futures_BlueChip(t) = f1 - f2;

    % OIS vs Blue Chip Survey
    f1 = error_OIS(t)^2;
    f2 = error_BlueChip(t)^2 - (OIS(t) - BlueChipSurvey(t))^2;
    CW_OIS_BlueChip(t) = f1 - f2;
end

% Normalize
CW_Futures_OIS = sqrt(T) * mean(CW_Futures_OIS) / std(CW_Futures_OIS, 'omitnan');
CW_Futures_BlueChip = sqrt(T) * mean(CW_Futures_BlueChip) / std(CW_Futures_BlueChip, 'omitnan');
CW_OIS_BlueChip = sqrt(T) * mean(CW_OIS_BlueChip) / std(CW_OIS_BlueChip, 'omitnan');


fprintf('\nClark-West Test Results:\n');
displayWithSignificance('Futures vs OIS', CW_Futures_OIS);
displayWithSignificance('Futures vs Blue Chip', CW_Futures_BlueChip);
displayWithSignificance('OIS vs Blue Chip', CW_OIS_BlueChip); 



