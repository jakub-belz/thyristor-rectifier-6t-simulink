function params = configure_rectifier_case(mode, control_mode, alpha_deg, I_ref, E_user)
% control_mode:
%   "manual" - alpha and Eo are entered directly
%   "auto_E"- alpha and I_ref are entered, Eo is calculated
%   "auto_alpha"- Eo and I_ref are entered, alpha is calculated

% System data
params.U_LL = 400;         
params.f_grid = 50;        

params.Rs = 10e-3;         
params.Ls = 1e-3;          
params.Lk = 10e-6;         

params.Ro = 1;            
params.Lo = 15e-3;        

params.pulse_width_deg = 120;
params.enable = 1;

% Derived constants
w = 2*pi*params.f_grid;
Ls_tot = params.Ls + params.Lk;

params.Ud0 = 1.35 * params.U_LL;

K = (3 * w * Ls_tot / pi) + 2 * params.Rs;
params.K_drop = K;

% Operating point
switch control_mode
    case "manual"
        params.alpha_deg = alpha_deg;
        params.I_ref = I_ref;
        params.Eo = E_user;

        params.Ud_expected = params.Ud0*cosd(params.alpha_deg) ...
                             - K*params.I_ref;

    case "auto_E"
        params.alpha_deg = alpha_deg;
        params.I_ref = I_ref;

        params.Ud_expected = params.Ud0*cosd(params.alpha_deg) ...
                             - K*params.I_ref;

        params.Eo = params.Ud_expected - params.Ro*params.I_ref;

    case "auto_alpha"
        params.I_ref = I_ref;
        params.Eo = E_user;

        U_req = params.Eo + params.Ro*params.I_ref + K*params.I_ref;
        ratio = U_req / params.Ud0;

        if ratio > 1 || ratio < -1
            error("Cannot calculate alpha: required voltage is outside the rectifier range.");
        end

        params.alpha_deg = acosd(ratio);
        params.Ud_expected = params.Eo + params.Ro*params.I_ref;

    otherwise
        error("Unknown control_mode. Use: manual, auto_E, or auto_alpha.");
end

% Power sign defines the operating mode.
params.P_expected = params.Ud_expected * params.I_ref;

if params.P_expected > 0
    params.detected_mode = "rectifier";
elseif params.P_expected < 0
    params.detected_mode = "inverter";
else
    params.detected_mode = "zero_power";
end

if mode == "rectifier" && params.P_expected < 0
    warning("Rectifier mode was selected, but the calculated point has P < 0.");
end

if mode == "inverter" && params.P_expected > 0
    warning("Inverter mode was selected, but the calculated point has P > 0.");
end

fprintf("\n--- Rectifier 6T operating point ---\n");
fprintf("Selected mode:      %s\n", mode);
fprintf("Detected mode:      %s\n", params.detected_mode);
fprintf("Control mode:       %s\n", control_mode);
fprintf("alpha_deg:          %.3f deg\n", params.alpha_deg);
fprintf("I_ref:              %.3f A\n", params.I_ref);
fprintf("Eo:                 %.3f V\n", params.Eo);
fprintf("Ud_expected:        %.3f V\n", params.Ud_expected);
fprintf("P_expected:         %.3f W\n", params.P_expected);
fprintf("------------------------------------\n\n");

end
