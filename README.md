# 6T Thyristor Rectifier Simulator
## License
This project is licensed under the MIT License.


MATLAB/Simulink project for simulation and analysis of a three-phase fully controlled 6-pulse thyristor rectifier with R-L-E load.
Requirements:
- MATLAB,
- Simulink,
- Simscape Electrical / Specialized Power Systems

The project includes:
- Simulink model of the 6T thyristor bridge,
- rectifier and inverter operating modes,
- automatic operating point calculation,
- MATLAB GUI control panel,
- validation scripts,
- result plots and summary tables


Open MATLAB and navigate to the project root folder.

Add the source folder to the MATLAB path:

addpath("src")

Open the Simulink model:

open_system(fullfile("model", "rectifier_6T_RLE_refactor.slx"))

Launch the graphical control panel: "rectifier_control_panel"


The graphical panel allows the user to:
- choose the operating mode
- choose the control mode
- set input parameters,
- run a single simulation with the set parameters
- view waveform plots,
- save the current plot,
- run all validation cases,
- generate all result plots,
- clear the result table,
- clear the log window.

