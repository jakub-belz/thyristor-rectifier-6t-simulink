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
T_stop = 0.3;        % [s]
offset_deg = 30;    % [deg]

% Test case
mode = "inverter";
control_mode = "auto_E";

% User inputs
alpha_in = 105;     % [deg]
I_in = 60;          % [A]
E_in = 0;           % [V]

params = configure_rectifier_case(mode, control_mode, alpha_in, I_in, E_in);

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

set_file_gen();

if ~bdIsLoaded(model)
    load_system(modelFile);
end

fprintf("Running model: %s\n", model);

simOut = sim(model, "StopTime", num2str(T_stop));

fprintf("Simulation finished.\n");

fprintf("\n--- Expected operating point ---\n");
fprintf("Mode selected:      %s\n", mode);
fprintf("Mode detected:      %s\n", params.detected_mode);
fprintf("alpha_deg:          %.3f deg\n", params.alpha_deg);
fprintf("Eo:                 %.3f V\n", params.Eo);
fprintf("I_ref:              %.3f A\n", params.I_ref);
fprintf("Ud_expected:        %.3f V\n", params.Ud_expected);
fprintf("P_expected:         %.3f W\n", params.P_expected);
fprintf("--------------------------------\n");

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
