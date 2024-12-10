%% Plot 1: Errors between EFFR and Forecast Measures

figure;
plot(lagged_data.Time, error_Futures, '-', 'Color', tol_colors(4,:), 'LineWidth', 1.5); hold on;
plot(lagged_data.Time, error_OIS, '-', 'Color', tol_colors(1,:), 'LineWidth', 1.5);
plot(lagged_data.Time, error_BlueChip, '-', 'Color', tol_colors(3,:), 'LineWidth', 1.5);
plot(lagged_data.Time, error_kim, '-', 'Color', tol_colors(5,:), 'LineWidth', 1.5); % Added Kim color


yline(0, '--k', 'LineWidth', 1.2); % Dotted horizontal line at zero


%title('Errors in Forecasting EFFR', 'FontSize', 14, 'FontWeight', 'bold'); 
xlabel('Date', 'FontSize', 12);
ylabel('Error', 'FontSize', 12);


legend({'Fed Funds Futures Error', 'OIS Error', 'Blue Chip Error', 'Kim Error'}, 'Location', 'best', 'FontSize', 10);


grid off;


hold off;


%% Plot 2: Comparison of EFFR with OIS and Blue Chip Survey
figure;
plot(lagged_data.Time, EFFR, '-', 'Color', tol_colors(2,:), 'LineWidth', 1.5); hold on; % Use tol_colors for EFFR
plot(lagged_data.Time, OIS, '-', 'Color', tol_colors(1,:), 'LineWidth', 1.5); % Use tol_colors for OIS
plot(lagged_data.Time, BlueChipSurvey, '-', 'Color', tol_colors(3,:), 'LineWidth', 1.5); % Use tol_colors for Blue Chip Survey
hold off;
%title('EFFR vs OIS and Blue Chip Survey');
legend('EFFR', 'OIS', 'Blue Chip Survey', 'Location', 'best');
xlabel('Date'); 
ylabel('Fed Funds Rate');
grid off;

%% Plot 2.2: Comparison of OIS and Blue Chip Survey
% Filter data for the range 2010 to 2012
startDate = datetime(2010, 1, 1);
endDate = datetime(2012, 12, 31);
filteredIndices = (lagged_data.Time >= startDate) & (lagged_data.Time <= endDate);
filteredTime = lagged_data.Time(filteredIndices);
filteredOIS = OIS(filteredIndices);
filteredBlueChipSurvey = BlueChipSurvey(filteredIndices);

% Plot 2: Comparison of OIS and Blue Chip Survey (2010 to 2012)
figure;
plot(filteredTime, filteredOIS, '-', 'Color', tol_colors(1,:), 'LineWidth', 1.5); hold on; % Use tol_colors for OIS
plot(filteredTime, filteredBlueChipSurvey, '-', 'Color', tol_colors(3,:), 'LineWidth', 1.5); % Use tol_colors for Blue Chip Survey
hold off;
%title('OIS and Blue Chip Survey (2010-2012)');
legend('OIS', 'Blue Chip Survey', 'Location', 'best');
xlabel('Date'); 
ylabel('Fed Funds Rate');
grid off;

%% plot 2.3

% Filter data for the range 2015 to 2017
startDate = datetime(2015, 1, 1);
endDate = datetime(2017, 12, 31);
filteredIndices = (lagged_data.Time >= startDate) & (lagged_data.Time <= endDate);
filteredTime = lagged_data.Time(filteredIndices);
filteredOIS = OIS(filteredIndices);
filteredBlueChipSurvey = BlueChipSurvey(filteredIndices);
filteredFedFundsFutures = FedFundsFutures(filteredIndices);

% Plot 2: Comparison of OIS, Blue Chip Survey, and Fed Funds Futures (2015 to 2017)
figure;
plot(filteredTime, filteredOIS, '-', 'Color', tol_colors(1,:), 'LineWidth', 1.5); hold on; % Use tol_colors for OIS
plot(filteredTime, filteredBlueChipSurvey, '-', 'Color', tol_colors(3,:), 'LineWidth', 1.5); % Use tol_colors for Blue Chip Survey
plot(filteredTime, filteredFedFundsFutures, '-', 'Color', tol_colors(4,:), 'LineWidth', 1.5); % Use tol_colors for Fed Funds Futures
hold off;

%title('OIS, Blue Chip Survey, and Fed Funds Futures (2015-2017)');
legend('OIS', 'Blue Chip Survey', 'Fed Funds Futures', 'Location', 'best');
xlabel('Date'); 
ylabel('Fed Funds Rate');
grid off;


%% Plot 3: Error Differences during (GFC, Liftoff, COVID)

figure;
gfc_period = lagged_data.Time >= datetime('2008-01-01') & lagged_data.Time <= datetime('2010-12-31');
liftoff_period = lagged_data.Time >= datetime('2015-01-01') & lagged_data.Time <= datetime('2017-12-31');
covid_period = lagged_data.Time >= datetime('2020-01-01') & lagged_data.Time <= datetime('2021-12-31');

subplot(3, 1, 1);
plot(lagged_data.Time(gfc_period), error_Futures(gfc_period), '-', 'Color', tol_colors(4,:), 'LineWidth', 1.5); hold on;
plot(lagged_data.Time(gfc_period), error_OIS(gfc_period), '-', 'Color', tol_colors(1,:), 'LineWidth', 1.5);
plot(lagged_data.Time(gfc_period), error_BlueChip(gfc_period), '-', 'Color', tol_colors(3,:), 'LineWidth', 1.5);
plot(lagged_data.Time(gfc_period), error_kim(gfc_period), '-', 'Color', tol_colors(5,:), 'LineWidth', 1.5); % Added Kim color
hold off;
title('Error Differences during GFC');
legend('Futures', 'OIS', 'Blue Chip', 'Kim', 'Location', 'best');
grid off;

subplot(3, 1, 2);
plot(lagged_data.Time(liftoff_period), error_Futures(liftoff_period), '-', 'Color', tol_colors(4,:), 'LineWidth', 1.5); hold on;
plot(lagged_data.Time(liftoff_period), error_OIS(liftoff_period), '-', 'Color', tol_colors(1,:), 'LineWidth', 1.5);
plot(lagged_data.Time(liftoff_period), error_BlueChip(liftoff_period), '-', 'Color', tol_colors(3,:), 'LineWidth', 1.5);
plot(lagged_data.Time(liftoff_period), error_kim(liftoff_period), '-', 'Color', tol_colors(5,:), 'LineWidth', 1.5); % Added Kim color
hold off;
title('Error Differences during Liftoff');
grid off;

subplot(3, 1, 3);
plot(lagged_data.Time(covid_period), error_Futures(covid_period), '-', 'Color', tol_colors(4,:), 'LineWidth', 1.5); hold on;
plot(lagged_data.Time(covid_period), error_OIS(covid_period), '-', 'Color', tol_colors(1,:), 'LineWidth', 1.5);
plot(lagged_data.Time(covid_period), error_BlueChip(covid_period), '-', 'Color', tol_colors(3,:), 'LineWidth', 1.5);
plot(lagged_data.Time(covid_period), error_kim(covid_period), '-', 'Color', tol_colors(5,:), 'LineWidth', 1.5); % Added Kim color
hold off;
title('Error Differences during COVID');
grid off;



legend('Futures', 'OIS', 'Blue Chip', 'Kim', 'Location', 'best');
xlabel('Date');
ylabel('Error');
grid off;
hold off;

%% Plot 4: Equally Weighted Index vs EFFR
figure;
plot(lagged_data.Time, EFFR, '-', 'Color', tol_colors(2,:), 'LineWidth', 1.5); hold on;
plot(lagged_data.Time, lagged_data.EquallyWeighted, '-', 'Color', tol_colors(5,:), 'LineWidth', 1.5);
hold off;
title('EFFR vs Equally Weighted Index');
legend('EFFR', 'Equally Weighted Index', 'Location', 'best');
xlabel('Date'); ylabel('Rate (%)');
grid off;

%% Plot 5: Errors between EFFR and Forecast Measures with limited x-axis range
figure;
plot(lagged_data.Time, error_Futures, '-', 'Color', tol_colors(4,:), 'LineWidth', 1.5); hold on;
plot(lagged_data.Time, error_OIS, '-', 'Color', tol_colors(1,:), 'LineWidth', 1.5);
plot(lagged_data.Time, error_BlueChip, '-', 'Color', tol_colors(3,:), 'LineWidth', 1.5);


yline(0, '--k', 'LineWidth', 1.2); % '--k' creates a black dashed line

% Set x-axis limits to go up to 2005
xlim([min(lagged_data.Time) datetime(2015, 1, 1)]);

legend('Fed Funds Futures Error', 'OIS Error', 'Blue Chip Error', 'Location', 'best');
xlabel('Date');
ylabel('Error');
title('Errors in Forecasting EFFR');
grid off;
hold off;

%% Plot 6: Optimally Weighted Index vs EFFR
figure;
plot(lagged_data.Time, EFFR, '-', 'Color', tol_colors(2,:), 'LineWidth', 1.5); hold on;
plot(lagged_data.Time, lagged_data.EquallyWeighted, '-', 'Color', tol_colors(5,:), 'LineWidth', 1.5);
plot(lagged_data.Time, optimal_index, '-', 'Color', tol_colors(4,:), 'LineWidth', 1.5);
hold off;
%title('EFFR vs Equally and Optimally Weighted Indices');
legend('EFFR', 'Equally Weighted Index', 'Optimally Weighted Index', 'Location', 'best');
xlabel('Date');
ylabel('Rate (%)');
grid off;

%%  Summary Statistics

if istimetable(lagged_data) || istable(lagged_data)
    varNames = lagged_data.Properties.VariableNames;  
    dataArray = table2array(lagged_data);             
else
    error('merged_data must be a table or timetable.');
end


numObs = sum(~isnan(dataArray));    % Number of Observations (non-NaN)
means = mean(dataArray, 'omitnan'); % Mean
stdDevs = std(dataArray, 'omitnan'); % Standard Deviation
mins = min(dataArray);               % Minimum
maxs = max(dataArray);               % Maximum
p25 = prctile(dataArray, 25);        % 25th Percentile
p50 = prctile(dataArray, 50);        % Median (50th Percentile)
p75 = prctile(dataArray, 75);        % 75th Percentile

% Create a Summary Table
summaryTable = table(numObs', means', stdDevs', mins', maxs', p25', p50', p75', ...
    'VariableNames', {'Observations', 'Mean', 'StdDev', 'Min', 'Max', 'P25', 'Median', 'P75'}, ...
    'RowNames', varNames);

% Display the Summary Statistics Table
disp('Summary Statistics Table:');
disp(summaryTable); 


%% Plot: Optimally/equal Weighted Index vs EFFR
figure;
plot(lagged_data.Time, EFFR, '-k', 'LineWidth', 1.5); hold on;
plot(lagged_data.Time, optimal_index, '-r', 'LineWidth', 1.5);
plot(lagged_data.Time, lagged_data.EquallyWeighted, '-b', 'LineWidth', 1.5);
plot(dates, EFFR_nonlagged, 'm-', 'LineWidth', 1.5);
xlabel('Time');
ylabel('Rate');
legend('Effective Federal Funds Rate (EFFR)', 'Optimally Weighted Index (MSE-Based)','Location', 'Best');
title('Equally & Optimally Weighted Index vs. Effective Federal Funds Rate');
grid on;
hold off;

