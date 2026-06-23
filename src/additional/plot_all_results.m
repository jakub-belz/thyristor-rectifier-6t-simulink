clear;
clc;
close all;

addDir = fileparts(mfilename("fullpath"));
srcDir = fileparts(addDir);
rootDir = fileparts(srcDir);

addpath(srcDir);
addpath(addDir);

% Output folders
resDir = fullfile(rootDir, "results");
figDir = fullfile(resDir, "figures");

if ~exist(figDir, "dir")
    mkdir(figDir);
end

files = [
    "Rectifier_E150.mat"
    "Rectifier_E300.mat"
    "Inverter_Eminus150.mat"
    "Inverter_Eminus300.mat"
];

t_plot_start = 0.10; 
t_avg_start = 0.15;  

for k = 1:numel(files)
    file = fullfile(resDir, files(k));

    if ~isfile(file)
        warning("File not found: %s", file);
        continue;
    end

    data = load(file);
    name = erase(files(k), ".mat");

    fprintf("Plotting case: %s\n", name);

    [t, u] = read_vec(data, "u_dc_log");
    [~, i] = read_vec(data, "i_dc_log");
    [~, p] = read_vec(data, "p_dc_log");

    idxAvg = t >= t_avg_start;

    Uavg = mean(u(idxAvg));
    Iavg = mean(i(idxAvg));
    Pavg = mean(p(idxAvg));

    Urms = sqrt(mean((u(idxAvg) - Uavg).^2));
    Irms = sqrt(mean((i(idxAvg) - Iavg).^2));
    Prms = sqrt(mean((p(idxAvg) - Pavg).^2));

    idxPlot = t >= t_plot_start;

    tPlot = t(idxPlot);
    uPlot = u(idxPlot);
    iPlot = i(idxPlot);
    pPlot = p(idxPlot);

    if isfield(data, "params")
        params = data.params;
        alpha = params.alpha_deg;
        Eo = params.Eo;
        mode = params.detected_mode;
    else
        alpha = NaN;
        Eo = NaN;
        mode = "unknown";
    end

    fig = figure("Color", "w");
    fig.Position = [100 100 1000 750];

    subplot(3,1,1);
    plot(tPlot, uPlot, "LineWidth", 1.0);
    grid on;
    ylabel("u_{dc} [V]");
    title(sprintf("%s | mode: %s | alpha = %.2f deg | E_o = %.1f V", ...
        name, mode, alpha, Eo), ...
        "Interpreter", "none");

    yline(Uavg, "--", sprintf("avg = %.2f V", Uavg), ...
        "LabelHorizontalAlignment", "left");

    subplot(3,1,2);
    plot(tPlot, iPlot, "LineWidth", 1.0);
    grid on;
    ylabel("i_{dc} [A]");

    yline(Iavg, "--", sprintf("avg = %.2f A", Iavg), ...
        "LabelHorizontalAlignment", "left");

    subplot(3,1,3);
    plot(tPlot, pPlot/1000, "LineWidth", 1.0);
    grid on;
    ylabel("p_{dc} [kW]");
    xlabel("Time [s]");

    yline(Pavg/1000, "--", sprintf("avg = %.2f kW", Pavg/1000), ...
        "LabelHorizontalAlignment", "left");

    fprintf("  Uavg = %.3f V, ripple RMS = %.3f V\n", Uavg, Urms);
    fprintf("  Iavg = %.3f A, ripple RMS = %.3f A\n", Iavg, Irms);
    fprintf("  Pavg = %.3f W, ripple RMS = %.3f W\n", Pavg, Prms);

    outPng = fullfile(figDir, name + ".png");

    try
        exportgraphics(fig, outPng, "Resolution", 200);
    catch
        saveas(fig, outPng);
    end

    fprintf("  Saved figure: %s\n\n", outPng);
end

fprintf("All plots generated.\n");

function [t, x] = read_vec(data, varName)

if isfield(data, varName)
    ts = data.(varName);
elseif isfield(data, "simOut")
    try
        ts = data.simOut.get(varName);
    catch
        error("Variable %s was not found in the .mat file or simOut.", varName);
    end
else
    error("Variable %s was not found in the result file.", varName);
end

if ~isa(ts, "timeseries")
    error("Variable %s is not a timeseries.", varName);
end

t = ts.Time;
x = squeeze(ts.Data);

if size(x,2) > 1
    x = x(:,1);
end

end
