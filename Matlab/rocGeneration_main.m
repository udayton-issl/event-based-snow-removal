clear; close all; clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT: rocGeneration_main -- Generate ablation/proposed ROC curves,    %
% ----------------------------------------------------------------------- %
% Script is used to generate ROC curves for both the proposed method and  %
% for the ablation study methods. ROC curve generation can be toggled for %
% each method in the GENERATION SETTINGS section. Additionally, certain   %
% metrics will be printed for a specific threshold index. This index can  %
% also be set in the GENERATION SETTINGS method. Velocity, snow diameter  %
% and sweep thresholds can be set in the TIME WINDOW SETTINGS section.    %
% Prior to running this script, the getTimewidths_main script must be run %
% in order to obtain a timewidths MAT file for use in this script. The    %
% name of this MAT file can be specified in the FILENAMES section.        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FILENAMES
tWidths_fName = "";

%% GENERATION SETTINGS
gen_noIE = true;                    % Generate ROC curve for no IE filter data?
gen_noLabelPropagation = true;      % Generate ROC curve for no label propogation data?
gen_spatialWindow = true;           % Generate ROC curve for spatial window data?
gen_perPixel = true;                % Generate ROC curve for no spatial window data?
gen_adaptiveWindow = true;          % Generate ROC curve for adaptive window data?
resultsPrintIdx = [8,10,1,2,9];     % Results index with best false positive rate.

%% TIME WINDOW SETTINGS
dSnow_max = 0.2;                    % Maximum snowflake diameter in inches.
carVelocity  = 30;                  % Car velocity in miles/hour.
etas = [ ...
    55,115,150,300,500,750, ...
    1000,1755,2065,2185,2500, ...
    5000,7500,10000,50000,100000 ...
];                                  % Threshold values.

%% THRESHOLD CALCULATION
% Convert max snowflake size to meters and car speed to meters/second
dSnow_max = dSnow_max/39.37;
carVelocity = carVelocity/2.237;

% Calculate tau values
taus = etas./(dSnow_max/carVelocity);

%% INITIALIZATION
load(tWidths_fName);
gtSnow = ones(1, length(etas))*sum(groundTruth);
gtNoSnow = ones(1, length(etas))*sum(~groundTruth);
alloc = zeros(1, length(etas));
predData = struct( ...
    "tp", alloc, ...
    "fp", alloc, ...
    "tn", alloc, ...
    "fn", alloc, ...
    "gtSnow", gtSnow, ...
    "gtNoSnow", gtNoSnow ...
);
genResults = [ ...
    gen_noIE, ...
    gen_noLabelPropagation, ...
    gen_spatialWindow, ...
    gen_adaptiveWindow, ...
    gen_perPixel ...
];
tWidths = [ ...
    tWidths_noIE, ...
    tWidths_noLabelPropagation, ...
    tWidths_spatialWindow, ...
    tWidths_adaptiveWindow, ...
    tWidths_perPixel ...
];
results(5) = struct( ...
    "precision", [], ...
    "recall", [], ...
    "accuracy", [], ...
    "tpRate", [], ...
    "fpRate", [], ...
    "tnRate", [], ...
    "fnRate", [] ...
);
printLabels = [ ...
    "No IE Filter", ...
    "No Label Propogation", ...
    "Spatial Window", ...
    "Adaptive Window", ...
    "Per Pixel" ...
];

for i = 1:length(genResults)
    if genResults(i)
        rocData = struct();
        for j = 1:length(etas)
            snowPred = tWidths(:, i) < etas(j);
            [tp, fp, tn, fn] = getTpFpTnFn(snowPred, groundTruth);
            predData.tp(j) = tp;
            predData.fp(j) = fp;
            predData.tn(j) = tn;
            predData.fn(j) = fn;
        end
        [precision, recall, accuracy] = getSuccessMetrics(predData);
        rates = getSuccessRates(predData);
        rocData.precision = precision;
        rocData.recall = recall;
        rocData.accuracy = accuracy;
        rocData.tpRate = rates.TP;
        rocData.fpRate = rates.FP;
        rocData.tnRate = rates.TN;
        rocData.fnRate = rates.FN;

        fprintf("\n%s\n=====\n", printLabels(i));
        fprintf("Eta = %i\n", etas(resultsPrintIdx(i)));
        fprintf("\tFP Rate:   %f\n", rates.FP(resultsPrintIdx(i)));
        fprintf("\tTP Rate:   %f\n", rates.TP(resultsPrintIdx(i)));
        fprintf("\tAccuracy:  %f\n", accuracy(resultsPrintIdx(i)));
        fprintf("\tAUC:       %f\n", trapz([rates.FP, 1], [rates.TP, 1]));

        results(i) = rocData;
    end
end

%% ROC CURVE GENERATION
figure;
hold on;
labels = {};
idx = 1;

if gen_perPixel
    p(idx) = plot(results(5).fpRate, results(5).tpRate, '.-');
    set(gca, 'ColorOrderIndex', idx);
    plot([results(5).fpRate(end), 1], [results(5).tpRate(end), 1], '--');
    labels{idx} = printLabels(5);
    idx = idx + 1;
end

if gen_adaptiveWindow
    p(idx) = plot(results(4).fpRate, results(4).tpRate, '.-');
    set(gca, 'ColorOrderIndex', idx);
    plot([results(4).fpRate(end), 1], [results(4).tpRate(end), 1], '--');
    labels{idx} = printLabels(4);
    idx = idx + 1;
end

if gen_noIE
    p(idx) = plot(results(1).fpRate, results(1).tpRate, '.-');
    set(gca, 'ColorOrderIndex', idx);
    plot([results(1).fpRate(end), 1], [results(1).tpRate(end), 1], '--');
    labels{idx} = printLabels(1);
    idx = idx + 1;
end

if gen_noLabelPropagation
    p(idx) = plot(results(2).fpRate, results(2).tpRate, '.-');
    set(gca, 'ColorOrderIndex', idx);
    plot([results(2).fpRate(end), 1], [results(2).tpRate(end), 1], '--');
    labels{idx} = printLabels(2);
    idx = idx + 1;
end

if gen_spatialWindow
    p(idx) = plot(results(3).fpRate, results(3).tpRate, '.-');
    set(gca, 'ColorOrderIndex', idx);
    plot([results(3).fpRate(end), 1], [results(3).tpRate(end), 1], '--');
    labels{idx} = printLabels(3);
    idx = idx + 1;
end

xlabel("False Positive");
ylabel("True Positive");
legend(p, labels);
