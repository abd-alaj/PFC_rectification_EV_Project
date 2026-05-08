# PFC Rectifier Design and Simulation

## How To Run This Project: 

1. git clone this repo:
```
git clone https://github.com/abd-alaj/PFC_rectification_EV_Project.git
```
2. in the `Simulink/` directory, run the script `PFC_params.m` prior to running any of the simulink models. 

## Project Description

### Situation
The project involves designing a single-phase boost Power Factor Correction (PFC) rectifier intended for electric vehicle charging applications, converting 240V RMS AC to a 400V DC output.

### Task
The objective was to size power stage components, derive a small-signal average model, design a cascaded PI controller. in the endeavour of doing so, a PLL and soft start functionality was added.

### Action
A boost converter topology was modeled using an uncontrolled full-bridge rectifier. Component values for the inductor and output capacitor were determined based on continuous conduction mode (CCM) requirements and ripple constraints. A linearized small-signal model was developed to design nested PI controllers for current and voltage regulation. Simulations were conducted in Simulink to test the controller against both static resistive loads and dynamic RC battery models.

### Result
The design achieved: 
*  a Power Factor of 0.9990
*  a Total Harmonic Distortion (THD) of 4.08% 
* The system demonstrated stable transient response and successful regulation under varying loads. 
 
**note:** a 99.9% power factor is very high and is probably due to the ideal conditions presented in a simulation, as most switching losses along with passive component parasitics were not considered in this case. 

# Project Visuals

### Plant and Load Models
* **Resistive Load Model:** ![Resistive Load](./assets/figures/plant_R_load.png)
* **RC Battery Model:** ![RC Load](./assets/figures/Plant_RC.png)

### Performance Analysis
* **Resistor Load (Single R):**
    ![Voltage Transient and Steady State Ripple](./assets/figures/R_load/V_out.png)
    ![Current Transient and Steady State Ripple](./assets/figures/R_load/I_out.png)
* **RC Load Modeling:**
    ![Output Voltage RC](./assets/figures/RC_load/V_out_RC.png)
    ![Inductor Current RC](./assets/figures/RC_load/inductor_current_RC.png)
* **Current and Grid Analysis:**
    ![Current Draw](./assets/figures/R_load/inductor_current_annotated.png)
* **Harmonic Analysis:**
    ![THD Harmonics](./assets/figures/R_load/thd_harmonics.png)