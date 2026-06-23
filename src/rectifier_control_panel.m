function rectifier_control_panel()

defModel = "rectifier_6T_RLE_refactor";
defT = 0.3;
defOff = 30;

srcDir = fileparts(mfilename("fullpath"));
rootDir = fileparts(srcDir);
resDir = fullfile(rootDir, "results");

addpath(srcDir);

addDir = fullfile(srcDir, "additional");

if exist(addDir, "dir")
    addpath(addDir);
end

last = [];

% Main window
fig = uifigure( ...
    "Name", "6T Thyristor Rectifier Control Panel", ...
    "Position", [80 80 1200 720]);

mainGrid = uigridlayout(fig, [1 2]);
mainGrid.ColumnWidth = {340, "1x"};
mainGrid.RowHeight = {"1x"};

% Input panel
leftPanel = uipanel(mainGrid, "Title", "Input parameters");
leftGrid = uigridlayout(leftPanel, [11 2]);

leftGrid.RowHeight = { ...
    30, 30, 30, 30, 30, 30, 30, ...
    38, 38, 38, 38};

leftGrid.ColumnWidth = {170, "1x"};

modelLabel = uilabel(leftGrid, "Text", "Model:");
modelField = uieditfield(leftGrid, "text");
modelField.Value = char(defModel);

modeLabel = uilabel(leftGrid, "Text", "Mode:");
modeDrop = uidropdown(leftGrid);
modeDrop.Items = ["rectifier", "inverter"];
modeDrop.Value = "rectifier";
modeDrop.ValueChangedFcn = @onInputChanged;

ctrlLabel = uilabel(leftGrid, "Text", "Control mode:");
ctrlDrop = uidropdown(leftGrid);
ctrlDrop.Items = ["manual", "auto_E", "auto_alpha"];
ctrlDrop.Value = "auto_alpha";
ctrlDrop.ValueChangedFcn = @onCtrlChanged;

alphaLabel = uilabel(leftGrid, "Text", "alpha [deg, 0...170]:");
alphaField = uieditfield(leftGrid, "numeric");
alphaField.Value = 66.4;
alphaField.Limits = [0 170];
alphaField.ValueChangedFcn = @onInputChanged;

iRefLabel = uilabel(leftGrid, "Text", "I_ref [A, 0...500]:");
iRefField = uieditfield(leftGrid, "numeric");
iRefField.Value = 50;
iRefField.Limits = [0 500];
iRefField.ValueChangedFcn = @onInputChanged;

eLabel = uilabel(leftGrid, "Text", "Eo [V]:");
eField = uieditfield(leftGrid, "numeric");
eField.Value = 150;
eField.Limits = [-Inf Inf];
eField.ValueChangedFcn = @onInputChanged;

tStopLabel = uilabel(leftGrid, "Text", "T_stop [s, >0]:");
tStopField = uieditfield(leftGrid, "numeric");
tStopField.Value = defT;
tStopField.Limits = [0.01 Inf];

runBtn = uibutton(leftGrid, "push");
runBtn.Text = "Run single case";
runBtn.ButtonPushedFcn = @runOne;

clearTableBtn = uibutton(leftGrid, "push");
clearTableBtn.Text = "Clear table";
clearTableBtn.ButtonPushedFcn = @clearTable;

clearLogBtn = uibutton(leftGrid, "push");
clearLogBtn.Text = "Clear log";
clearLogBtn.ButtonPushedFcn = @clearLog;

savePlotBtn = uibutton(leftGrid, "push");
savePlotBtn.Text = "Save current plot";
savePlotBtn.ButtonPushedFcn = @savePlot;

runAllBtn = uibutton(leftGrid, "push");
runAllBtn.Text = "Run all cases";
runAllBtn.ButtonPushedFcn = @runAll;

plotBtn = uibutton(leftGrid, "push");
plotBtn.Text = "Save all plots";
plotBtn.ButtonPushedFcn = @plotAll;

openBtn = uibutton(leftGrid, "push");
openBtn.Text = "Open results";
openBtn.ButtonPushedFcn = @openResults;

helpBtn = uibutton(leftGrid, "push");
helpBtn.Text = "Help";
helpBtn.ButtonPushedFcn = @showHelp;

% Output tabs
rightPanel = uipanel(mainGrid, "Title", "Output");
rightGrid = uigridlayout(rightPanel, [1 1]);

tabs = uitabgroup(rightGrid);

tabResults = uitab(tabs, "Title", "Results table");
tabPlots = uitab(tabs, "Title", "Plots");
tabLog = uitab(tabs, "Title", "Log");

tableGrid = uigridlayout(tabResults, [1 1]);

resultsTable = uitable(tableGrid);
resultsTable.ColumnName = { ...
    "mode", ...
    "control", ...
    "alpha_deg", ...
    "Eo_V", ...
    "I_ref_A", ...
    "Uavg_V", ...
    "Iavg_A", ...
    "Pavg_W", ...
    "detected"};

resultsTable.Data = cell(0, 9);

plotGrid = uigridlayout(tabPlots, [3 2]);
plotGrid.RowHeight = {"1x", "1x", "1x"};
plotGrid.ColumnWidth = {"1x", "1x"};

axU = uiaxes(plotGrid);
title(axU, "DC voltage u_{dc}(t)");
xlabel(axU, "Time [s]");
ylabel(axU, "u_{dc} [V]");
grid(axU, "on");

axUm = uiaxes(plotGrid);
title(axUm, "Mean DC voltage");
xlabel(axUm, "Time [s]");
ylabel(axUm, "mean u_{dc} [V]");
grid(axUm, "on");

axI = uiaxes(plotGrid);
title(axI, "DC current i_{dc}(t)");
xlabel(axI, "Time [s]");
ylabel(axI, "i_{dc} [A]");
grid(axI, "on");

axIm = uiaxes(plotGrid);
title(axIm, "Mean DC current");
xlabel(axIm, "Time [s]");
ylabel(axIm, "mean i_{dc} [A]");
grid(axIm, "on");

axP = uiaxes(plotGrid);
title(axP, "DC power p_{dc}(t)");
xlabel(axP, "Time [s]");
ylabel(axP, "p_{dc} [kW]");
grid(axP, "on");

axPm = uiaxes(plotGrid);
title(axPm, "Mean DC power");
xlabel(axPm, "Time [s]");
ylabel(axPm, "mean p_{dc} [kW]");
grid(axPm, "on");

logGrid = uigridlayout(tabLog, [1 1]);

logArea = uitextarea(logGrid);
logArea.Editable = "off";
logArea.Value = "Panel ready.";

updateState();

    function onCtrlChanged(~, ~)
        updateState();
    end

    function onInputChanged(~, ~)
        updateState();
    end

    function updateState()
        c = sysConst();
        ctrl = string(ctrlDrop.Value);

        a = alphaField.Value;
        I = iRefField.Value;
        E = eField.Value;

        Ud0 = c.Ud0;
        K = c.Kdrop;
        Ro = c.Ro;

        Emin = -Ud0 - (Ro + K)*I;
        Emax =  Ud0 - (Ro + K)*I;

        colNorm = [0 0 0];
        colRange = [0.00 0.30 0.70];
        colCalc = [0.45 0.45 0.45];
        colBad = [0.85 0.00 0.00];

        modelLabel.FontColor = colNorm;
        modeLabel.FontColor = colNorm;
        ctrlLabel.FontColor = colNorm;

        tStopLabel.FontColor = colRange;
        alphaLabel.FontColor = colRange;
        iRefLabel.FontColor = colRange;
        eLabel.FontColor = colRange;

        alphaLabel.Text = "alpha [deg, 0...170]:";
        iRefLabel.Text = "I_ref [A, 0...500]:";
        eLabel.Text = sprintf("Eo [V, %.0f...%.0f]:", Emin, Emax);

        alphaField.Enable = "on";
        iRefField.Enable = "on";
        eField.Enable = "on";

        switch ctrl
            case "manual"
                alphaField.Enable = "on";
                iRefField.Enable = "on";
                eField.Enable = "on";

            case "auto_E"
                alphaField.Enable = "on";
                iRefField.Enable = "on";
                eField.Enable = "off";

                Ud = Ud0*cosd(a) - K*I;
                eField.Value = Ud - Ro*I;

                eLabel.Text = "Eo [V, calculated]:";
                eLabel.FontColor = colCalc;

            case "auto_alpha"
                alphaField.Enable = "off";
                iRefField.Enable = "on";
                eField.Enable = "on";

                r = (E + Ro*I + K*I) / Ud0;

                if r >= -1 && r <= 1
                    aReq = acosd(r);

                    if aReq <= 170
                        alphaField.Value = aReq;
                        alphaLabel.Text = "alpha [deg, calculated]:";
                        alphaLabel.FontColor = colCalc;
                    else
                        alphaLabel.Text = "alpha [deg, >170 invalid]:";
                        alphaLabel.FontColor = colBad;
                    end
                else
                    alphaLabel.Text = "alpha [deg, invalid Eo/I]:";
                    alphaLabel.FontColor = colBad;
                end

                eLabel.Text = sprintf("Eo [V, %.0f...%.0f]:", Emin, Emax);
        end
    end

    function runOne(~, ~)
        try
            addLog("Running single case...");

            updateState();
            modelFile = getModelFile(string(modelField.Value), rootDir);
            [~, model] = fileparts(modelFile);
            mode = string(modeDrop.Value);
            ctrl = string(ctrlDrop.Value);

            aIn = alphaField.Value;
            iIn = iRefField.Value;
            eIn = eField.Value;

            T_stop = tStopField.Value;
            offset_deg = defOff;

            params = configure_rectifier_case(mode, ctrl, aIn, iIn, eIn);

            if params.alpha_deg < 0 || params.alpha_deg > 170
                error("Calculated alpha = %.3f deg is outside allowed range 0...170 deg.", params.alpha_deg);
            end

            if ctrl == "auto_E"
                eField.Value = params.Eo;
            elseif ctrl == "auto_alpha"
                alphaField.Value = params.alpha_deg;
            end

            updateState();

            assignBase(params, offset_deg, T_stop);

            setFileGen();

            if ~bdIsLoaded(model)
                load_system(modelFile);
            end

            simOut = sim(model, "StopTime", num2str(T_stop));

            tAvg = max(0, T_stop/2);
            tPlot = max(0, T_stop/3);

            uTs = readTs(simOut, "u_dc_log");
            iTs = readTs(simOut, "i_dc_log");
            pTs = readTs(simOut, "p_dc_log");

            [tu, u] = tsVec(uTs);
            [ti, i] = tsVec(iTs);
            [tp, p] = tsVec(pTs);

            [Uavg, Urip] = avgVec(tu, u, tAvg);
            [Iavg, Irip] = avgVec(ti, i, tAvg);
            [Pavg, Prip] = avgVec(tp, p, tAvg);

            row = { ...
                char(mode), ...
                char(ctrl), ...
                params.alpha_deg, ...
                params.Eo, ...
                params.I_ref, ...
                Uavg, ...
                Iavg, ...
                Pavg, ...
                char(params.detected_mode)};

            resultsTable.Data = [resultsTable.Data; row];

            last.case = sprintf("%s_%s_alpha_%.1f_E_%.1f", ...
                mode, ctrl, params.alpha_deg, params.Eo);

            last.tu = tu;
            last.u = u;
            last.ti = ti;
            last.i = i;
            last.tp = tp;
            last.p = p;

            last.params = params;

            last.Uavg = Uavg;
            last.Iavg = Iavg;
            last.Pavg = Pavg;

            last.Urip = Urip;
            last.Irip = Irip;
            last.Prip = Prip;

            last.tPlot = tPlot;

            plotPanel(last);

            tabs.SelectedTab = tabPlots;

            addLog("Simulation finished.");
            addLog(sprintf("alpha = %.3f deg", params.alpha_deg));
            addLog(sprintf("Eo = %.3f V", params.Eo));
            addLog(sprintf("Expected Ud = %.3f V", params.Ud_expected));
            addLog(sprintf("Expected P = %.3f W", params.P_expected));
            addLog(sprintf("Sim Uavg = %.3f V, ripple RMS = %.3f V", Uavg, Urip));
            addLog(sprintf("Sim Iavg = %.3f A, ripple RMS = %.3f A", Iavg, Irip));
            addLog(sprintf("Sim Pavg = %.3f W, ripple RMS = %.3f W", Pavg, Prip));
            addLog("------------------------------------");

        catch ME
            addLog("ERROR:");
            addLog(ME.message);
            uialert(fig, ME.message, "Simulation error");
        end
    end

    function runAll(~, ~)
        try
            addLog("Running run_all_cases.m ...");
            runScriptInBase(fullfile(addDir, "run_all_cases.m"));
            addLog("run_all_cases finished.");
            addLog("Summary saved to results/summary.csv");
            addLog("Figures saved to results/figures");
            addLog("------------------------------------");
        catch ME
            addLog("ERROR in run_all_cases:");
            addLog(ME.message);
            uialert(fig, ME.message, "run_all_cases error");
        end
    end

    function plotAll(~, ~)
        try
            addLog("Running plot_all_results.m ...");
            runScriptInBase(fullfile(addDir, "plot_all_results.m"));
            addLog("plot_all_results finished.");
            addLog("Figures saved to results/figures");
            addLog("------------------------------------");
        catch ME
            addLog("ERROR in plot_all_results:");
            addLog(ME.message);
            uialert(fig, ME.message, "plot_all_results error");
        end
    end

    function clearTable(~, ~)
        resultsTable.Data = cell(0, 9);
        addLog("Results table cleared.");
    end

    function clearLog(~, ~)
        logArea.Value = "Log cleared.";
    end

    function savePlot(~, ~)
        try
            if isempty(last)
                uialert(fig, "No plot available. Run a simulation first.", "No data");
                return;
            end

            if ~exist(resDir, "dir")
                mkdir(resDir);
            end

            figDir = fullfile(resDir, "figures");

            if ~exist(figDir, "dir")
                mkdir(figDir);
            end

            safe = string(matlab.lang.makeValidName(last.case));
            outPng = fullfile(figDir, safe + ".png");

            savePlotFig(last, outPng);

            addLog("Current plot saved:");
            addLog(outPng);
        catch ME
            addLog("ERROR while saving current plot:");
            addLog(ME.message);
            uialert(fig, ME.message, "Save plot error");
        end
    end

    function openResults(~, ~)
        if ~exist(resDir, "dir")
            mkdir(resDir);
        end

        try
            if ispc
                winopen(resDir);
            elseif ismac
                system("open """ + resDir + """");
            else
                system("xdg-open """ + resDir + """");
            end
        catch
            addLog("Could not open results folder automatically.");
        end
    end

    function showHelp(~, ~)
        msg = [
            "Control modes:"
            ""
            "manual:"
            "  User sets alpha and Eo manually."
            "  I_ref is used only as an approximate reference value."
            ""
            "auto_E:"
            "  User sets alpha and I_ref."
            "  Eo is calculated automatically and the Eo field is disabled."
            ""
            "auto_alpha:"
            "  User sets Eo and I_ref."
            "  alpha is calculated automatically and the alpha field is disabled."
            ""
            "Expected signs:"
            "  Rectifier: Udc > 0, Idc > 0, Pdc > 0"
            "  Inverter:  Udc < 0, Idc > 0, Pdc < 0"
            ""
            "Label colors:"
            "  Blue  - user-editable range or parameter range."
            "  Gray  - automatically calculated field."
            "  Red   - invalid calculated value."
        ];

        uialert(fig, strjoin(msg, newline), "Help");
    end

    function addLog(msg)
        old = string(logArea.Value);
        logArea.Value = [old; string(msg)];
        drawnow;
    end

    function plotPanel(d)
        idxU = d.tu >= d.tPlot;
        idxI = d.ti >= d.tPlot;
        idxP = d.tp >= d.tPlot;

        cla(axU);
        cla(axUm);
        cla(axI);
        cla(axIm);
        cla(axP);
        cla(axPm);

        colU = [0.0000 0.4470 0.7410];
        colI = [0.8500 0.3250 0.0980];
        colP = [0.4940 0.1840 0.5560];

        plot(axU, d.tu(idxU), d.u(idxU), "Color", colU, "LineWidth", 1.2);
        hold(axU, "on");
        yline(axU, d.Uavg, "--", sprintf("mean = %.2f V", d.Uavg));
        hold(axU, "off");
        grid(axU, "on");
        title(axU, sprintf("DC voltage u_{dc}(t) | mean = %.2f V | ripple RMS = %.2f V | alpha = %.2f deg | Eo = %.1f V", ...
            d.Uavg, d.Urip, d.params.alpha_deg, d.params.Eo));
        xlabel(axU, "Time [s]");
        ylabel(axU, "u_{dc} [V]");

        plot(axUm, d.tu(idxU), d.Uavg*ones(nnz(idxU),1), ...
            "Color", colU, "LineWidth", 1.2);
        grid(axUm, "on");
        title(axUm, sprintf("Mean u_{dc} | %.2f V | ripple RMS = %.2f V", ...
            d.Uavg, d.Urip));
        xlabel(axUm, "Time [s]");
        ylabel(axUm, "mean u_{dc} [V]");

        plot(axI, d.ti(idxI), d.i(idxI), "Color", colI, "LineWidth", 1.2);
        hold(axI, "on");
        yline(axI, d.Iavg, "--", sprintf("mean = %.2f A", d.Iavg));
        hold(axI, "off");
        grid(axI, "on");
        title(axI, sprintf("DC current i_{dc}(t) | mean = %.2f A | ripple RMS = %.2f A", ...
            d.Iavg, d.Irip));
        xlabel(axI, "Time [s]");
        ylabel(axI, "i_{dc} [A]");

        plot(axIm, d.ti(idxI), d.Iavg*ones(nnz(idxI),1), ...
            "Color", colI, "LineWidth", 1.2);
        grid(axIm, "on");
        title(axIm, sprintf("Mean i_{dc} | %.2f A | ripple RMS = %.2f A", ...
            d.Iavg, d.Irip));
        xlabel(axIm, "Time [s]");
        ylabel(axIm, "mean i_{dc} [A]");

        plot(axP, d.tp(idxP), d.p(idxP)/1000, "Color", colP, "LineWidth", 1.2);
        hold(axP, "on");
        yline(axP, d.Pavg/1000, "--", sprintf("mean = %.2f kW", d.Pavg/1000));
        hold(axP, "off");
        grid(axP, "on");
        title(axP, sprintf("DC power p_{dc}(t) | mean = %.2f kW | ripple RMS = %.2f kW", ...
            d.Pavg/1000, d.Prip/1000));
        xlabel(axP, "Time [s]");
        ylabel(axP, "p_{dc} [kW]");

        plot(axPm, d.tp(idxP), (d.Pavg/1000)*ones(nnz(idxP),1), ...
            "Color", colP, "LineWidth", 1.2);
        grid(axPm, "on");
        title(axPm, sprintf("Mean p_{dc} | %.2f kW | ripple RMS = %.2f kW", ...
            d.Pavg/1000, d.Prip/1000));
        xlabel(axPm, "Time [s]");
        ylabel(axPm, "mean p_{dc} [kW]");
    end

end

function modelFile = getModelFile(modelText, rootDir)

modelText = strtrim(string(modelText));

if endsWith(modelText, ".slx") || contains(modelText, filesep) || contains(modelText, "/")
    modelFile = char(modelText);
else
    modelFile = fullfile(rootDir, "model", modelText + ".slx");
end

if ~isfile(modelFile)
    error("Model file not found: %s", modelFile);
end

end

function runScriptInBase(scriptFile)

if ~isfile(scriptFile)
    error("Script file not found: %s", scriptFile);
end

cmd = "run('" + replace(string(scriptFile), "'", "''") + "')";
evalin("base", cmd);

end

function assignBase(params, off, tStop)

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
assignin("base", "offset_deg", off);
assignin("base", "enable", params.enable);

assignin("base", "I_ref", params.I_ref);
assignin("base", "T_stop", tStop);

end

function setFileGen()

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

function ts = readTs(simOut, varName)

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

function [t, x] = tsVec(ts)

t = ts.Time;
x = squeeze(ts.Data);

if size(x,2) > 1
    x = x(:,1);
end

end

function [avg, rmsRip] = avgVec(t, x, tStart)

idx = t >= tStart;

if ~any(idx)
    error("No samples after t_start = %.3f s.", tStart);
end

xs = x(idx);
avg = mean(xs);
rmsRip = sqrt(mean((xs - avg).^2));

end

function c = sysConst()

c.U_LL = 400;
c.f_grid = 50;

c.Rs = 10e-3;
c.Ls = 1e-3;
c.Lk = 10e-6;

c.Ro = 1;
c.Lo = 15e-3;

w = 2*pi*c.f_grid;

c.Ud0 = 1.35*c.U_LL;
c.Kdrop = (3*w*(c.Ls + c.Lk)/pi) + 2*c.Rs;

end

function savePlotFig(d, outPng)

fig = figure("Color", "w");
fig.Position = [100 100 1300 850];

idxU = d.tu >= d.tPlot;
idxI = d.ti >= d.tPlot;
idxP = d.tp >= d.tPlot;

colU = [0.0000 0.4470 0.7410];
colI = [0.8500 0.3250 0.0980];
colP = [0.4940 0.1840 0.5560];

subplot(3,2,1);
plot(d.tu(idxU), d.u(idxU), "Color", colU, "LineWidth", 1.2);
grid on;
hold on;
yline(d.Uavg, "--", sprintf("mean = %.2f V", d.Uavg));
hold off;
ylabel("u_{dc} [V]");
title(sprintf("DC voltage | mean = %.2f V | ripple RMS = %.2f V | alpha = %.2f deg | Eo = %.1f V", ...
    d.Uavg, d.Urip, d.params.alpha_deg, d.params.Eo));

subplot(3,2,2);
plot(d.tu(idxU), d.Uavg*ones(nnz(idxU),1), "Color", colU, "LineWidth", 1.2);
grid on;
ylabel("mean u_{dc} [V]");
title(sprintf("Mean u_{dc} | %.2f V | ripple RMS = %.2f V", d.Uavg, d.Urip));

subplot(3,2,3);
plot(d.ti(idxI), d.i(idxI), "Color", colI, "LineWidth", 1.2);
grid on;
hold on;
yline(d.Iavg, "--", sprintf("mean = %.2f A", d.Iavg));
hold off;
ylabel("i_{dc} [A]");
title(sprintf("DC current | mean = %.2f A | ripple RMS = %.2f A", ...
    d.Iavg, d.Irip));

subplot(3,2,4);
plot(d.ti(idxI), d.Iavg*ones(nnz(idxI),1), "Color", colI, "LineWidth", 1.2);
grid on;
ylabel("mean i_{dc} [A]");
title(sprintf("Mean i_{dc} | %.2f A | ripple RMS = %.2f A", d.Iavg, d.Irip));

subplot(3,2,5);
plot(d.tp(idxP), d.p(idxP)/1000, "Color", colP, "LineWidth", 1.2);
grid on;
hold on;
yline(d.Pavg/1000, "--", sprintf("mean = %.2f kW", d.Pavg/1000));
hold off;
ylabel("p_{dc} [kW]");
xlabel("Time [s]");
title(sprintf("DC power | mean = %.2f kW | ripple RMS = %.2f kW", ...
    d.Pavg/1000, d.Prip/1000));

subplot(3,2,6);
plot(d.tp(idxP), (d.Pavg/1000)*ones(nnz(idxP),1), "Color", colP, "LineWidth", 1.2);
grid on;
ylabel("mean p_{dc} [kW]");
xlabel("Time [s]");
title(sprintf("Mean p_{dc} | %.2f kW | ripple RMS = %.2f kW", ...
    d.Pavg/1000, d.Prip/1000));

try
    exportgraphics(fig, outPng, "Resolution", 200);
catch
    saveas(fig, outPng);
end

close(fig);

end
