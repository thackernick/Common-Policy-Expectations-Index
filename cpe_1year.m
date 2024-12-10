%% Load Excel data and remove missing values
FFF_data = rmmissing(readtable('CrystalBall_Data(Market).xlsx', 'Sheet', 'FFF'));
OIS_data = rmmissing(readtable('CrystalBall_Data(Market).xlsx', 'Sheet', 'OIS'));
EFFR_data = rmmissing(readtable('CrystalBall_Data(Market).xlsx', 'Sheet', 'EFFR'));
Bluechip_data = readtable('bc_surv_exp.xls'); 

%% Delete first rows 
FFF_data(1, :) = [];
OIS_data(1, :) = [];
EFFR_data(1, :) = [];

% Rename 'Var1' to 'Date' 
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

% Select the relevant columns for the 1-year analysis
FFF_1year = FFF_monthly(:, {'FF12Comdty'});
OIS_1year = OIS_monthly(:, {'USSO1Curncy'});
Bluechip_1year = Bluechip_monthly(:, {'RFF_FF_F4'});
EFFR = EFFR_monthly(:, {'Var2'});  

% Convert FF12Comdty to double and subtract from 100
FFF_1year.FF12Comdty = str2double(FFF_1year.FF12Comdty);
FFF_1year.FF12Comdty = 100 - FFF_1year.FF12Comdty;

% Fitted Instantaneous Forward Rate 1 Year Hence (Kim-Wright)
c = fred();  
series_id = 'THREEFF1';
data = fetch(c, series_id);
KimW_1year = timetable(datetime(data.Data(:,1), 'ConvertFrom', 'datenum'), data.Data(:,2), 'VariableNames', {'KimW1yr'});

% Resample KimW_1year to monthly data (last day of each month)
KimW_1year = retime(KimW_1year, 'monthly', 'lastvalue');

%% Merge all
merged_data = synchronize(KimW_1year, FFF_1year, OIS_1year, Bluechip_1year, EFFR);

% Create lag
EFFR_lag = merged_data.Var2(13:end);  % Lagging by 12 months (i.e., one year)
FedFundsFutures_lag = merged_data.FF12Comdty(1:end-12);
OIS_lag = merged_data.USSO1Curncy(1:end-12);
BlueChipSurvey_lag = merged_data.RFF_FF_F4(1:end-12);
Kim_lag = merged_data.KimW1yr(1:end-12);

lagged_data = timetable(merged_data.Date(13:end), EFFR_lag, FedFundsFutures_lag, OIS_lag, BlueChipSurvey_lag, Kim_lag, ...
    'VariableNames', {'EFFR_lag', 'FedFundsFutures_lag', 'OIS_lag', 'BlueChipSurvey_lag', 'Kim_lag'});
%cut to 2005
%lagged_data = lagged_data(lagged_data.Time >= datetime(2005, 1, 1), :);
% Remove rows with NaN values from lagged_data & removing covid
lagged_data = rmmissing(lagged_data);
%lagged_data = lagged_data(lagged_data.Time<datetime('01-Jan-2020'),:);

% Extract the variables from lagged_data 
EFFR = lagged_data.EFFR_lag;
FedFundsFutures = lagged_data.FedFundsFutures_lag;
OIS = lagged_data.OIS_lag;
BlueChipSurvey = lagged_data.BlueChipSurvey_lag;
kim = lagged_data.Kim_lag;
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
error_kim = EFFR - kim; 
% Mean Squared Error for each measure
MSE_Futures = mean(error_Futures.^2);
MSE_OIS = mean(error_OIS.^2);
MSE_BlueChip = mean(error_BlueChip.^2);
MSE_kim = mean(error_kim.^2);


%% Display error metrics
fprintf('\nError Metrics:\n');
displayWithSignificance('Fed Funds Futures', MSE_Futures);
displayWithSignificance('OIS', MSE_OIS);
displayWithSignificance('Blue Chip Survey', MSE_BlueChip);
displayWithSignificance('Kim Wright', MSE_kim);
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


% Diebold-Mariano Test for fff vs Kim Wright
d = (error_Futures.^2) - (error_kim.^2);
dBar = mean(d);
DM_num = dBar;
DM_den = sqrt(sum((d - dBar).^2) / T^2);
DM_Futures_kim = DM_num / DM_den;

% Diebold-Mariano Test for OIS vs Kim Wright
d = (error_OIS.^2) - (error_kim.^2);
dBar = mean(d);
DM_num = dBar;
DM_den = sqrt(sum((d - dBar).^2) / T^2);
DM_OIS_kim = DM_num / DM_den;
fprintf('\nDiebold-Mariano Test Results:\n');
displayWithSignificance('Futures vs OIS', DM_Futures_OIS);
displayWithSignificance('Futures vs Blue Chip', DM_Futures_BlueChip);
displayWithSignificance('OIS vs Blue Chip', DM_OIS_BlueChip);
displayWithSignificance('OIS vs kim', DM_OIS_kim); 
displayWithSignificance('FFF vs kim', DM_Futures_kim);
%% Clark-West Test
CW_Futures_OIS = zeros(T, 1);
CW_Futures_BlueChip = zeros(T, 1);
CW_OIS_BlueChip = zeros(T, 1);
CW_Futures_kim = zeros(T, 1);

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

    % Futures vs Kim Wright
    f1 = error_Futures(t)^2;
    f2 = error_kim(t)^2 - (FedFundsFutures(t) - kim(t))^2;
    CW_Futures_kim(t) = f1 - f2;
end

% Normalize
CW_Futures_OIS = sqrt(T) * mean(CW_Futures_OIS) / std(CW_Futures_OIS, 'omitnan');
CW_Futures_BlueChip = sqrt(T) * mean(CW_Futures_BlueChip) / std(CW_Futures_BlueChip, 'omitnan');
CW_OIS_BlueChip = sqrt(T) * mean(CW_OIS_BlueChip) / std(CW_OIS_BlueChip, 'omitnan');
CW_Futures_kim = sqrt(T) * mean(CW_Futures_kim) / std(CW_Futures_kim, 'omitnan');
CW_OIS_kim = zeros(T, 1);

for t = 1:T
    % OIS vs Kim Wright
    f1 = error_OIS(t)^2;
    f2 = error_kim(t)^2 - (OIS(t) - kim(t))^2;
    CW_OIS_kim(t) = f1 - f2;
end

% Normalize
CW_OIS_kim = sqrt(T) * mean(CW_OIS_kim) / std(CW_OIS_kim, 'omitnan');

fprintf('\nClark-West Test Results:\n');
displayWithSignificance('Futures vs OIS', CW_Futures_OIS);
displayWithSignificance('Futures vs Blue Chip', CW_Futures_BlueChip);
displayWithSignificance('OIS vs Blue Chip', CW_OIS_BlueChip);
displayWithSignificance('OIS vs Kim', CW_OIS_kim);
displayWithSignificance('FFF vs Kim', CW_Futures_kim);

%% equally weighted index
% Ensure the variables are aligned in time
index_data = (FedFundsFutures + OIS + BlueChipSurvey + kim) / 4;

% Add the index to the timetable
lagged_data.EquallyWeighted = index_data;


%% Given MSE values
MSE_Futures = mean(error_Futures.^2);
MSE_OIS = mean(error_OIS.^2);
MSE_BlueChip = mean(error_BlueChip.^2);

% Parameter tau
% Parameter tau
tau = 1;  % Define your value for tau

% Calculate weights for each measure
w_Futures = exp(-tau * MSE_Futures);
w_OIS = exp(-tau * MSE_OIS);
w_BlueChip = exp(-tau * MSE_BlueChip);
w_Kim = exp(-tau * MSE_kim);

% Sum of all weights
total_w = w_Futures + w_OIS + w_BlueChip + w_Kim;

% Normalize
weight_Futures = w_Futures / total_w;
weight_OIS = w_OIS / total_w;
weight_BlueChip = w_BlueChip / total_w;
weight_Kim = w_Kim / total_w;

% Display the weights
disp(['Weight for Futures: ', num2str(weight_Futures)]);
disp(['Weight for OIS: ', num2str(weight_OIS)]);
disp(['Weight for Blue Chip: ', num2str(weight_BlueChip)]);
disp(['Weight for Kim: ', num2str(weight_Kim)]);

% Optimal index including Kim Wright
optimal_index = weight_Futures * FedFundsFutures + weight_OIS * OIS + ...
                weight_BlueChip * BlueChipSurvey + weight_Kim * kim;

% Add the optimal index to the timetable
lagged_data.OptimalIndex = optimal_index;
%% verify
disp(head(lagged_data));


%% Errors for indices
error_EquallyWeighted = EFFR - lagged_data.EquallyWeighted;
error_OptimalIndex = EFFR - lagged_data.OptimalIndex;

% Calculate Mean Squared Errors for the indices
MSE_EquallyWeighted = mean(error_EquallyWeighted.^2);
MSE_OptimalIndex = mean(error_OptimalIndex.^2);

% Display MSE results
fprintf('\nError Metrics for Indices:\n');
displayWithSignificance('MSE for Equally Weighted Index: ', MSE_EquallyWeighted);
displayWithSignificance('MSE for Optimally Weighted Index: ', MSE_OptimalIndex); 

% Diebold-Mariano Test for Equally Weighted vs Optimally Weighted
d = (error_EquallyWeighted.^2) - (error_OptimalIndex.^2);
T = length(d);  % Sample size
dBar = mean(d);  % Mean of differences
DM_num = dBar;  % Numerator of DM statistic
DM_den = sqrt(sum((d - dBar).^2) / T^2);  % Denominator (standard error)
DM_Equally_vs_Optimal = DM_num / DM_den;

% Display the DM test results
fprintf('\nDiebold-Mariano Test Results:\n');
displayWithSignificance('Equally Weighted vs Optimally Weighted Index: ', DM_Equally_vs_Optimal); 

% Initialize
CW_Equally_vs_Optimal = zeros(T, 1);

for t = 1:T
    % Equally Weighted vs Optimally Weighted
    f1 = error_EquallyWeighted(t)^2;
    f2 = error_OptimalIndex(t)^2 - (lagged_data.EquallyWeighted(t) - lagged_data.OptimalIndex(t))^2;
    CW_Equally_vs_Optimal(t) = f1 - f2;
end

% Normalize the CW statistic
CW_Equally_vs_Optimal = sqrt(T) * mean(CW_Equally_vs_Optimal) / std(CW_Equally_vs_Optimal, 'omitnan');

% Display the CW test results
%fprintf('\nClark-West Test Results:\n');
%displayWithSignificance(Equally Weighted vs Optimally Weighted Index: ' , CW_Equally_vs_Optimal);
