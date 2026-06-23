clear;
clc;

addDir = fileparts(mfilename("fullpath"));
srcDir = fileparts(addDir);
rootDir = fileparts(srcDir);

addpath(srcDir);
addpath(addDir);

% Simulink model name without .slx
model = "rectifier_6T_RLE_refactor";
modelFile = fullfile(rootDir, "model", model + ".slx");

% Simulation setup
T_stop = 0.3;     
offset_deg = 30;   
t_avg_start = 0.15; 
t_plot_start = 0.10; 

% Validation cases
cases(1).name = "Rectifier_E150";
cases(1).mode = "rectifier";
cases(1).control_mode = "auto_alpha";
cases(1).alpha_input = 0;
cases(1).I_ref = 50;
cases(1).Eo = 150;

cases(2).name = "Rectifier_E300";
cases(2).mode = "rectifier";
cases(2).control_mode = "auto_alpha";
cases(2).alpha_input = 0;
cases(2).I_ref = 50;
cases(2).Eo = 300;

cases(3).name = "Inverter_Eminus150";
cases(3).mode = "inverter";
cases(3).control_mode = "auto_alpha";
cases(3).alpha_input = 0;
cases(3).I_ref = 50;
cases(3).Eo = -150;

cases(4).name = "Inverter_Eminus300";
cases(4).mode = "inverter";
cases(4).control_mode = "auto_alpha";
cases(4).alpha_input = 0;
cases(4).I_ref = 50;
cases(4).Eo = -300;

resDir = fullfile(rootDir, "results");

if ~exist(resDir, "dir")
    mkdir(resDir);
end

figDir = fullfile(resDir, "figures");

if ~exist(figDir, "dir")
    mkdir(figDir);
end

for k = 1:numel(cases)
    oldMat = fullfile(resDir, cases(k).name + ".mat");

    if isfile(oldMat)
        delete(oldMat);
    end
end

set_file_gen();

if ~bdIsLoaded(model)
    load_system(modelFile);
end

n = numel(cases);

caseName = strings(n,1);
selMode = strings(n,1);
detMode = strings(n,1);

alpha = zeros(n,1);
EoVal = zeros(n,1);
Iref = zeros(n,1);

UdExp = zeros(n,1);
PExp = zeros(n,1);

UavgOut = zeros(n,1);
IavgOut = zeros(n,1);
PavgOut = zeros(n,1);

Uerr = zeros(n,1);
Ierr = zeros(n,1);
Perr = zeros(n,1);

Urms = zeros(n,1);
Irms = zeros(n,1);
Prms = zeros(n,1);

for k = 1:n
    fprintf("\n--- Running case %d/%d: %s ---\n", k, n, cases(k).name);

    params = configure_rectifier_case( ...
        cases(k).mode, ...
        cases(k).control_mode, ...
        cases(k).alpha_input, ...
        cases(k).I_ref, ...
        cases(k).Eo);

    % Values used by the Simulink model
    assignin("base", "U_LL", params.U_LL);
    assignin("base", "ULL", params.U_LL);
    assignin("base", "f_grid", params.f_grid);

    assignin("base", "Rs", params.Rs);
    assignin("base", "Ls", params.Ls);
    assignin("base", "Lk", params.Lk);

    assignin("base", "Ro", params.Ro);
    assignin("base", "Lo", params.Lo);
    assignin("base", "Eo", params.Eo);

    assignin("base", "alpha_deg", params.alpha_deg);
    assignin("base", "pulse_width_deg", params.pulse_width_deg);
    assignin("base", "offset_deg", offset_deg);
    assignin("base", "enable", params.enable);

    assignin("base", "I_ref", params.I_ref);
    assignin("base", "T_stop", T_stop);

    simOut = sim(model, "StopTime", num2str(T_stop));

    [Uavg, Urip] = read_avg(simOut, "u_dc_log", t_avg_start);
    [Iavg, Irip] = read_avg(simOut, "i_dc_log", t_avg_start);
    [Pavg, Prip] = read_avg(simOut, "p_dc_log", t_avg_start);

    [tu, u] = read_vec(simOut, "u_dc_log");
    [ti, i] = read_vec(simOut, "i_dc_log");
    [tp, p] = read_vec(simOut, "p_dc_log");

    pngFile = fullfile(figDir, cases(k).name + ".png");
    save_case_plot(pngFile, cases(k).name, params, ...
        tu, u, ti, i, tp, p, ...
        Uavg, Iavg, Pavg, Urip, Irip, Prip, t_plot_start);

    fprintf("Saved figure: %s\n", pngFile);

    caseName(k) = cases(k).name;
    selMode(k) = cases(k).mode;
    detMode(k) = params.detected_mode;

    alpha(k) = params.alpha_deg;
    EoVal(k) = params.Eo;
    Iref(k) = params.I_ref;

    UdExp(k) = params.Ud_expected;
    PExp(k) = params.P_expected;

    UavgOut(k) = Uavg;
    IavgOut(k) = Iavg;
    PavgOut(k) = Pavg;

    Uerr(k) = Uavg - params.Ud_expected;
    Ierr(k) = Iavg - params.I_ref;
    Perr(k) = Pavg - params.P_expected;

    Urms(k) = Urip;
    Irms(k) = Irip;
    Prms(k) = Prip;
end

summary = table( ...
    caseName, ...
    selMode, ...
    detMode, ...
    round(alpha, 2), ...
    round(EoVal, 1), ...
    round(Iref, 1), ...
    round(UdExp, 2), ...
    round(UavgOut, 2), ...
    round(Uerr, 2), ...
    round(IavgOut, 2), ...
    round(Ierr, 2), ...
    round(PExp/1000, 3), ...
    round(PavgOut/1000, 3), ...
    round(Perr/1000, 3), ...
    round(Urms, 2), ...
    round(Irms, 2), ...
    round(Prms/1000, 3));

summary.Properties.VariableNames = { ...
    'case_name', ...
    'selected_mode', ...
    'detected_mode', ...
    'alpha_deg', ...
    'Eo_V', ...
    'I_ref_A', ...
    'Udc_expected_V', ...
    'Udc_mean_V', ...
    'Udc_error_V', ...
    'Idc_mean_A', ...
    'Idc_error_A', ...
    'Pdc_expected_kW', ...
    'Pdc_mean_kW', ...
    'Pdc_error_kW', ...
    'Udc_ripple_rms_V', ...
    'Idc_ripple_rms_A', ...
    'Pdc_ripple_rms_kW'};

disp(summary);

summary_file = fullfile(resDir, "summary.csv");
writetable(summary, summary_file, 'Delimiter', ';');

fprintf("\nAll cases finished.\n");
fprintf("Summary saved to: %s\n", summary_file);
fprintf("CSV delimiter: semicolon\n");
fprintf("Figures saved to: %s\n", figDir);

function set_file_gen()

cacheDir = fullfile(tempdir, "rectifier_6T_cache");
codeDir = fullfile(tempdir, "rectifier_6T_codegen");

try
    Simulink.fileGenControl("set", ...
        "CacheFolder", cacheDir, ...
        "CodeGenFolder", codeDir, ...
        "createDir", true);
catch ME
    warning('%s', ['Could not move Simulink generated files: ' ME.message]);
end

end

function [avg, rmsRip] = read_avg(simOut, varName, tStart)

ts = read_ts(simOut, varName);

t = ts.Time;
x = squeeze(ts.Data);

if size(x,2) > 1
    x = x(:,1);
end

idx = t >= tStart;

if ~any(idx)
    error("No samples after t_start = %.3f s for signal %s.", tStart, varName);
end

xs = x(idx);
avg = mean(xs);
rmsRip = sqrt(mean((xs - avg).^2));

end

function ts = read_ts(simOut, varName)

try
    ts = simOut.get(varName);
catch
    if evalin("base", "exist('" + varName + "', 'var')")
        ts = evalin("base", varName);
    else
        error("Variable %s was not found. Check the To Workspace block name.", varName);
    end
end

if ~isa(ts, "timeseries")
    error("Variable %s is not a Timeseries. Set Save format = Timeseries.", varName);
end

end

function [t, x] = read_vec(simOut, varName)

ts = read_ts(simOut, varName);

t = ts.Time;
x = squeeze(ts.Data);

if size(x,2) > 1
    x = x(:,1);
end

end

function save_case_plot(outPng, name, params, tu, u, ti, i, tp, p, Uavg, Iavg, Pavg, Urip, Irip, Prip, tStart)

idxU = tu >= tStart;
idxI = ti >= tStart;
idxP = tp >= tStart;

fig = figure("Color", "w", "Visible", "off");
fig.Position = [100 100 1300 850];

subplot(3,2,1);
plot(tu(idxU), u(idxU), "LineWidth", 1.0);
grid on;
ylabel("u_{dc} [V]");
title(sprintf("%s | u_{dc}(t) | mode: %s | alpha = %.2f deg | Eo = %.1f V", ...
    name, params.detected_mode, params.alpha_deg, params.Eo), ...
    "Interpreter", "none");
yline(Uavg, "--", sprintf("avg = %.2f V", Uavg), ...
    "LabelHorizontalAlignment", "left");

subplot(3,2,2);
plot(tu(idxU), Uavg*ones(nnz(idxU),1), "LineWidth", 1.0);
grid on;
ylabel("mean u_{dc} [V]");
title(sprintf("mean = %.2f V | ripple RMS = %.2f V", Uavg, Urip));

subplot(3,2,3);
plot(ti(idxI), i(idxI), "LineWidth", 1.0);
grid on;
ylabel("i_{dc} [A]");
title("i_{dc}(t)");
yline(Iavg, "--", sprintf("avg = %.2f A", Iavg), ...
    "LabelHorizontalAlignment", "left");

subplot(3,2,4);
plot(ti(idxI), Iavg*ones(nnz(idxI),1), "LineWidth", 1.0);
grid on;
ylabel("mean i_{dc} [A]");
title(sprintf("mean = %.2f A | ripple RMS = %.2f A", Iavg, Irip));

subplot(3,2,5);
plot(tp(idxP), p(idxP)/1000, "LineWidth", 1.0);
grid on;
ylabel("p_{dc} [kW]");
xlabel("Time [s]");
title("p_{dc}(t)");
yline(Pavg/1000, "--", sprintf("avg = %.2f kW", Pavg/1000), ...
    "LabelHorizontalAlignment", "left");

subplot(3,2,6);
plot(tp(idxP), (Pavg/1000)*ones(nnz(idxP),1), "LineWidth", 1.0);
grid on;
ylabel("mean p_{dc} [kW]");
xlabel("Time [s]");
title(sprintf("mean = %.2f kW | ripple RMS = %.2f kW", Pavg/1000, Prip/1000));

try
    exportgraphics(fig, outPng, "Resolution", 200);
catch
    saveas(fig, outPng);
end

close(fig);

end
