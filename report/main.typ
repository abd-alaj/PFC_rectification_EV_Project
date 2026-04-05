#import "template.typ": *

// Check for the private compile flag
#let use-private = sys.inputs.at("private", default: "false") == "true"

#show cite: it => super(it)

// Conditionally load the array of authors
#let document-authors = if use-private {
  import "authors.typ": private-authors
  private-authors
} else {
  (
    (
      names: ("[REDACTED AUTHOR 1]",),
      affiliation: "[REDACTED AFFILIATION]",
      email: "[REDACTED EMAIL]",
      student-id: "[REDACTED SID]"
    ),
    (
      names: ("[REDACTED AUTHOR 2]",),
      affiliation: "[REDACTED AFFILIATION]",
      email: "[REDACTED EMAIL]",
      student-id: "[REDACTED SID]"
    )
  )
}

#show: project.with(
  header_text: [ELEC 4450 - Power Electronics],
  title: [Project - PFC Rectifier Design and Simulation],
  authors: document-authors,
  date: auto,
  abstract:[
    I'm not writing an abstract. read the report. no one reads this part anyways.
  ],
)

= Introduction
The design of an electric vehicle (EV) charging system requires a multistage power conversion architecture to convert alternating current (AC) from the utility grid with a high voltage DC battery pack. Let grid voltage $v_(a c)$ be a 240 volt RMS sinusoidal wave that must be converted to a 400-volt DC output, suitable to charge an EV battery. The abstracted architecture of the system, illustrated in @fig-ev-arch, defines the primary functional blocks and their respective roles in the conversion process.

#figure( 
  image("./figures/arch-rectifier.png", width: 80%),
  caption: [High level architectural overview of the rectifier and PFC circuit.] 
) <fig-ev-arch>

In @fig-ev-arch, the DC-AC, transformer, and AC-DC stages are idealized as a 1:1 transformer, and omitted from the architectural diagram, making design slightly easier for this final project. 

= Power Stage Topology
The front end of the system utilizes an uncontrolled full-bridge rectifier to convert the AC mains voltage to a pulsating DC bus. This is immediately followed by a boost converter to regulate the voltage step-up, as shown in @fig-rectifier-boost.

#figure(
  image("./figures/onboard_charging_circuit_model.png", width: 80%),
  caption: [Full-Bridge Rectifier and Boost Converter Topology]
) <fig-rectifier-boost>

= Calculations
== Assumptions and Parameters


#figure(
  apa_table(
    columns: (auto, 1fr),
    "Parameters", "Value",
    [Grid Voltage], [ 240V RMS $:= 240 sqrt(2) cos(2 pi 60 t)$],
    [Current Draw], [60A RMS $:= 60 sqrt(2) cos(2 pi 60 t)$],
    [Power Factor ], [1],
    [Battery Load], [$C_("batt") = 40 F, " " R_("ESR") = 200 m Omega$],
    [Max $Delta i_L$], [3A],
  ),
  caption: [Table of Parameters provided by the instructor of the PFC rectifier project]
) 


There were multiple assumptions made in the creation of the ideal model of both the rectification and boost stage.

+ conversion ratio is ideal. 
+ electrical components are ideal.
+ the $K$ value is sufficiently large enough that the boost converter is in continuous conduction mode (CCM) operation

== Rectification Stage

The simplest way to model the full bridge rectifier is to assume that the forward voltage drop $V_F$ in a diode is negligible ($2 V_F >> V_(a c)$). Since $v_(a c) = 240 sqrt(2) cos(120 pi t)$, $v_1(t)$ becomes:  

$ v_1 (t) = hat(v_i) |cos(omega t)| = 240 sqrt(2) |cos(120 pi t)| $

Equivantly, the current entering inductor, becomes:

$ i_1 (t) = 60 sqrt(2) |cos(120 pi t)| $

== Boost Stage 

The boost conversion stages requires the mathematical model of the current ripple, $Delta i_L$, thus we model current via definition: 

$ i_L = 1/L integral_(0)^(D T_(s w)) v_L d t $

where $v_L$ is defined as the input voltage multiplied by the duty cycle $D$. I will no longer yap and just show how the steps. 

$  
  i_L = 1/L integral_(0)^(D T_(s w)) D v_1(t) d t \
  Delta i_(L,p p) = frac(D v_1 T_(s w), L) => frac(D v_1 , f_(s w) L) \
  => Delta i_L = frac(D v_1, 2 f_(s w) L)    
$

the conversion ratio, $M(D)$ in a boost converter is: 

$
  frac(V_o, v_1(t)) = frac(1, overline(d(t))) => frac(1, 1 - d(t))\
  => d(t) = 1 - (frac(v_1(t), V_o))
$

thus, 
$
  Delta i_L = frac(d(t)  v_1(t) , 2 L f_(s w)) = frac(v_1(t), 2 L f_(s w)) ( 1 - frac(v_1(t), V_o))
$

where $v_1(t) = hat(V_i) |cos(omega t)| = 240 sqrt(2) |cos(120 pi t)|$ and $Delta i_L = 3"A"$. We arrange the above equation to model the relationship between $f_(s w)$ and $v_1(t)$: 

$ 
  f_(s w) (v_1(t)) = frac(v_1(t), 2 L Delta i_L ) ( 1 - frac(v_1(t), V_o)) 
$

which in time domain, is defined as: 

$
  f_(s w) (t) = frac(hat(V_i)|cos(omega t)|, 2 L Delta i_L ) ( 1 - frac(hat(V_i)|cos(omega t), V_o)) 
$

Usually, in commercial design, a ballpark frequency is chosen based on the technology, (SiC, GaN, etc.) and then an inductor is chosen. Thus, we will choose a ballpark frequency of 100 KHz, which is approximately the values chosen in switching speeds concerning GaN technology. @gan_ev_review_2025

plugging in values to determine $L$ we set $cos(omega t) = 1$ and solve: 

$ 
  L  = frac(hat(V_i), 2 f_(s w) Delta i_L ) ( 1 - frac(hat(V_i), V_o)) \
  L = frac(240 sqrt(2), 2(100 "kHz")(3 "A")) (1 - frac(240 sqrt(2), 400)) \
  L = 85.686 mu"H"
$ 

we choose an inductor with a value $L = 85 - 90 mu"H"$ with a rating of $64-90 "A"$ then adjust $f_(s w)$ accordingly.

There is a problem. there is no 90 A inductor, the closest inductor we could find are 100A inductors on digikey. Such as @digikeyL

#figure( 
  image("./figures/inductor_digikey.png"),
  caption: [500mH 100A rated inductor found on digikey, which at the time of writing, is found to be \$363.44 USD]
) <digikeyL>

A 100 A rated $500 mu"H"$ inductor was found, which requires us to recalculate the switching frequency: 

$
  f_(s w)  = frac(hat(V_i), 2 L Delta i_L ) ( 1 - frac(hat(V_i), V_o)) \
  f_(s w) = frac(240 sqrt(2), 2 (500 mu"H")(3A))(1 - frac(240 sqrt(2), 400)) \
  // what 
  f_(s w) = 17 "kHz"
$

this switching frequency is unreasonable, it will cause audible noise (human hearing is approximately 4 - 20 kHz), thus we choose 50 kHz, and that will minimize the current ripple $Delta i_L$ to $ approx 1.03 "A"$. 

== Determining The capacitor size. 

We are aiming to get a Power Factor of approximately 1, which then we can assume in our calculations. A $P F = 1$ allows us to model the power input $P_"in"$ and power output $P_"out"$ without considering the reactive power in out equations. Recall that $P = sqrt(S^2 + Q^2) => P = V I cos(phi.alt) + V I sin(phi.alt)$, if $P F approx 1$, then the phase between the voltage and current is effectively $0 degree$. Thus, 

$ P_("out") = V_"RMS" I_"RMS" cos(0) + cancel(V_"RMS" I_"RMS" sin(0))^0==> V_"RMS" dot I_"RMS" $

We will also assume an ideal conversion ratio $P_"in" = P_"out"$ as that inherently gives us a degree of safety when choosing a capacitor. 

$
  P_"in" = P_"out" = (240 "V")(60 "A") = 14400 "W" \
  I_"batt" = P_"out" / V_o = frac(14400 "W" , 400 "V") = 36 "A"
$ <cap>

In a single-phase system, the instantaneous power $p_c (t)$ fluctuates at twice the line frequency ($2 omega$). We model the capacitor power as:

$ p_c (t) = P_o cos(2 omega t) $

For a small ripple approximation, the power in the capacitor is also related to the voltage derivative:

$ p_c (t) = C V_o (d v_o) / (d t) $

By integrating the power fluctuation, we find the time-varying ripple voltage $v_o (t)$:

$ v_o (t) = P_o / (2 omega C V_o) sin(2 omega t) $

The peak ripple amplitude $V_"ripple"$ is the coefficient of the sine term:

$ V_("ripple") = P_o / (2 omega C V_o) $

The peak-to-peak voltage ripple ($Delta V_(p p)$) is twice the peak amplitude. We require this ripple to be less than $4 "V"$:

$ Delta V_(p p) = 2 V_("ripple") = P_o / (omega C V_o) < 4 "V" $

Rearranging to solve for the minimum capacitance ($C$):

$ 
  C > P_o / (4 omega V_o) ==> C > frac(14400 "W", 8 pi 60 (400 "V")) \
  ==> C > 24 "mF" 
$ <cmin>

using the parameters calculated in @cap and a capacitor that satsifies @cmin, we find a part on digikey: 

#figure(
  image("./figures/capacitor_digikey.png"),
  caption: [2 of these 15 mF Aluminum Electrolytic Capacitors in parallel would create the correct capacitance with a margin of safety for the PFC rectifier.]
) <cap_digikey>

Calculating the voltage ripple using the capacitor found: 

$
  Delta V_(p p) = P_o / (omega C V_o) = frac( 14400 "W", (2 pi 60 "Hz") ( 30 "mF") (400 "V")) \
  Delta V_(p p) approx 3.18 "V"
$ 

= Modelling 

To model the PFC rectifier stage accurately, it is important to derive the average model first. We use the classical boost converter topology and extract the state variables as a function of the average inductor current $chevron.l i_L chevron.r$, battery $chevron.l v_"batt" chevron.r$ and input voltage $chevron.l v_1 chevron.r$. We use CCB and VSB laws and get the following: 

$
  C frac(d, d t) chevron.l V_"batt" chevron.r = (1 - d) chevron.l i_L chevron.r - 1 / R chevron.l V_"batt" chevron.r \

  L frac(d, d t) chevron i_L chevron.r = chevron v_1 chevron.r - (1 - d)chevron V_"batt" chevron.r
$

== Determining the Quiescent Point 

At the peak of the AC cycle ($V_1 = 340 "V"$, $V_(b a t t) = 400 "V"$, $I_L = 60 sqrt(2) "A"$):
$ chevron.l V_L chevron.r = D(V_1) + (1-D)(V_1 - V_(b a t t)) = 0\
V_(b a t t) / V_1 = 1 / (1-D) ==>  400 / 340 = 1 / (1-D)\ 1 - D = 0.85 ==> D = 0.15 "(15% duty cycle)" $

== Linearizing the Model

To analyze the system's dynamic response, we perturb the variables around the quiescent operating point:
$ 
  v_"batt"(t) = V_"batt" + tilde(v)_"batt" (t) \
  i_L(t) = I_L + tilde(i)_L (t) \
  d(t) = D + tilde(d)(t) 
$

Substituting these into the average capacitor equation:
$
  C d/(d t) (V_"batt" + tilde(v)_"batt" (t)) = (1 - [D + tilde(d)(t)])(I_L + tilde(i)_L (t)) - (V_"batt" + tilde(v)_"batt" (t)) / R \
  C d/(d t) tilde(v)_"batt" (t) = underbrace(cancel((1-D)I_L - V_"batt"/R)^0, "DC Term") + (1-D)tilde(i)_L (t) - I_L tilde(d)(t) - frac(tilde(v)_"batt" (t),R )- underbrace(cancel(tilde(d)(t)tilde(i)_L (t))^(approx 0), "2nd Order Term")
$

At steady state, $(1-D)I_L - V_"batt"/R = 0$. Note that 2nd order terms, (pertubations multiplied by pertubations) are very small: $tilde(d)tilde(i)_L approx 0$. Thus, we neglect them and isolate the linearized time-domain equation:

$ C d/(d t) tilde(v)_"batt" (t) approx (1-D)tilde(i)_L(t) - I_L tilde(d)(t) - frac(tilde(v)_"batt" (t), R) $

We now apply the Laplace transform. Note that the derivative $d/(d t)$ becomes $s$ in the $s$-domain #footnote[Tehcnically, $frac(d, d t) f(t) = s F(s) + f(0)$, however we assume all initial values are 0, simplifying the calculations.], and the time-varying functions $f(t)$ become $F(s)$:

$ 
  C s tilde(V)_"batt" (s) = (1-D)tilde(I)_L (s) - I_L tilde(D)(s) - frac(tilde(V)_"batt" (s), R) \
  tilde(V)_"batt" (s) (C s + 1/R) = (1-D)tilde(I)_L (s) - I_L tilde(D)(s) \
  tilde(V)_"batt" (s) = ((1-D)tilde(I)_L (s) - I_L tilde(D)(s)) / (C s + 1/R) 
$

To find the transfer function for the inductor current, we apply perturbations to the average inductor equation:
$ L d/(d t) chevron.l i_L(t) chevron.r = chevron.l v_1(t) chevron.r - (1 - d(t)) chevron.l v_"batt"(t) chevron.r $

Substituting $i_L(t) = I_L + tilde(i)_L(t)$, $v_"batt" (t) = V_"batt" + tilde(v)_"batt" (t)$, and $d(t) = D + tilde(d)(t)$:

$
 L d/(d t) (I_L + tilde(i)_L (t)) = (V_1) - (1 - [D + tilde(d)(t)])(V_"batt" + tilde(v)_"batt" (t)) \
 L d/(d t) tilde(i)_L (t) = underbrace(cancel(V_1 - (1 - D) V_"batt")^0, "steady state cond.") - (1 - D) tilde(v)_"batt" (t) + V_"batt" tilde(d)(t) + underbrace(cancel(tilde(d)(t) tilde(v)_"batt" (t))^(approx 0), "second order product")\
  L d/(d t) tilde(i)_L (t) approx V_"batt" tilde(d)(t) - (1 - D) tilde(v)_"batt" (t) \
  s L tilde(I)_L (s) = V_"batt" tilde(D)(s) - (1 - D) tilde(V)_"batt" (s) 
$

Thus, the resulting small-signal equation for the inductor current is:
$ tilde(I)_L (s) = (V_"batt" tilde(D)(s) - (1 - D) tilde(V)_"batt"(s)) / (s L) $

== Transfer Function in relation to pertubations in the Duty cycle, $tilde(d)(s)$

Now, we must determine the transfer function of the duty cycle in relation to duty cycle input pertubation: 

$ 
  tilde(v)_"batt"(s) = frac((1-D) tilde(i)_L (s) - I_L tilde(d)(s), s C + frac(1, R)) \
  tilde(i)_L (s) = frac(V_"batt" tilde(d)(s) - (1-D) tilde(v)_"batt"(s), s L)
$ <linearized_model>

combine both lines in @linearized_model by subbing in $v_("batt") (s)$ and isolate input pertubation $tilde(d)(s)$:

$ 
  tilde(i)_L (s) = frac(V_"batt" tilde(d)(s) (s C + frac(1, R)) - (1-D)^2 tilde(i)_L (s) + (1-D) I_L tilde(d)(s), s L (s C + frac(1, R))) \ 
  tilde(i)_L (s) [1 + frac((1-D)^2, s L (s C + frac(1, R)))] = frac((V_"batt" (s C + frac(1, R)) + (1-D) I_L) tilde(d)(s), s L (s C + frac(1, R))) \
$

which results in the following transfer function: 

$
  frac(tilde(i)_L (s), tilde(d)(s)) = frac(V_"batt" (s C + frac(1, R)) + (1-D) I_L, s L (s C + frac(1, R)) + (1-D)^2)
$ <tf_il>

For the battery voltage transfer function, we substitute $tilde(i)_L (s)$ back into the original expression:

$ 
  tilde(v)_"batt"(s) = frac((1-D) V_"batt" tilde(d)(s) - (1-D)^2 tilde(v)_"batt"(s) - I_L tilde(d)(s) s L, s L (s C + frac(1, R))) \
  tilde(v)_"batt"(s) [1 + frac((1-D)^2, s L (s C + frac(1, R)))] = frac(((1-D) V_"batt" - I_L s L) tilde(d)(s), cancel(s L (s C + frac(1, R)))) 
$

The resulting control-to-output voltage transfer function is:

$ 
  frac(tilde(v)_"batt" (s), tilde(d)(s)) = frac((1-D) V_"batt" - s L I_L, s L (s C + frac(1, R)) + (1-D)^2)
$ <tf_vbatt>

// TODO write simulations for when these transfer functions would and would not work and add them here along with explanations


= Controller Design

To create a PI controller, classical control system steps were used to determine the gain values $K_p$ and $K_i$. In small signal modelling, we treat the battery as an equivalent resistance at its operating point, using Ohm's law: 

$ R = V_"batt" / I_"batt" = frac( 400 "V", 36 "A" ) = 11.1 Omega $

Using the transfer functions determined in @tf_il, we can inspect the characteristic equation and extract our damping ratio, $zeta$, and our cutoff frequency $omega_n$. The characteristic equation $Delta(s)$ of the current transfer function is: 

$ 
  Delta(s)_(i_L) =  s L (s C + frac(1, R)) + (1-D)^2 \
  ==> Delta(s)_(i_L) = s^2 + frac(1, R C)s + frac((1 - D)^2, L C)
$

using $Delta(s) = s^2 + 2 zeta omega_n + omega_n^2$, we can extract the damping ratio and cutoff frequency: 

$
  omega_n = frac((1-D), sqrt(L C)) "  " zeta = frac(1 , 2 R C omega_n) 
$

plugging in parameters and extracting the margins on the bode plot, we can determine the current phase and gain margin. The current loop PI controller $C_i (s)$ is then designed by selecting a crossover frequency $f_(c,i)$ at $1/20$ of the switching frequency $f_s$. The controller takes the form:

$ C_i (s) = K_(p,i) + frac(K_(i,i), s) $

To achieve the target phase margin $phi.alt_m$, the required phase contribution from the zero, $phi_z$, is calculated by accounting for the plant's phase at the crossover frequency:

$ phi.alt_z = -90^degree + phi.alt_m - angle G_i (j omega_(c,i)) $

The zero frequency $omega_z$ and gains are then derived:

$ omega_z = frac(omega_(c,i), tan(phi.alt_z)) quad K_(p,i) = frac(omega_(c,i), |G_i (j omega_(c,i))| sqrt(omega_(c,i)^2 + omega_z^2)) quad K_(i,i) = K_(p,i) omega_z $

For the outer voltage loop, the plant is simplified to a first-order approximation based on the average capacitor current:

$ G_(v,"avg") (s) = frac(V_("pk"), 2 V_("batt") C) dot frac(1, s + frac(2, R C)) $

The nested loop stability is verified by combining the voltage controller, the average voltage plant, and the closed-loop current response $T_(i,c l)(s)$:

$ L_(v,"nested") (s) = C_v (s) dot G_(v,"avg") (s) dot T_(i,c l) (s) $

The resulting controller gains and system performance metrics are summarized below:

#figure(
  apa_table(
    columns: (auto, 1fr),
    "Parameter", "Value",
    [$K_(p,v)$ of PI controller $C_v (s)$], [1.7],
    [$K_(i,v)$ of PI controller $C_v (s)$], [4.24],
    [$K_(p,i)$ of PI controller $C_i (s)$], [0.101010],
    [$K_(i,i)$ of PI controller $C_i (s)$], [0.054]
  ),
  caption: [gain values for both PID controllers for a static load $R = 11.1 Omega$]
)

== Implementation in simulink
#figure(
  image("./figures/controller_PI.png"),
  caption: [Controller layout of the cascaded PI controller.]
)

This control law consists of two PI controllers, an inner loop PI controller denoted as $C_v (s)$ and an outer loop PI controller denoted as $C_i (s)$. The controller along with its inputs were discretized, with a down sampler (denoted as a zero-order hold (ZOH) block) at the output of $C_v (s)$. Some functionality was also added, mainly, "soft-start" logic, made to mitigate large current draw from the grid, and a phase locked loop to determine the phase angle of the voltage input, which mitigates drift in the controller.

The controller uses the following control law@erickson2020fundamentals @reza2026pfc: 
+ determine the voltage error $e_v$, defined as $V_o - 400 "V"$
+ feed $e_v$ into $C_v (s)$, this PI output dictates the current draw from the grid and is denoted as $hat(I_i)^*$.
+ this is then multiplied by a normalized $|cos(omega t)|$, to form $i_1^* = hat(I_i)^* |cos(omega t)|$
+ current error is then determined as $e_i = i_1^* - i_1$, where $i_1$ is the measured current through the inductor.
+ the second PI controller is then used to correct the current error $e_i$

== System with an arbitrary load resistor $R_"load"$

to implement a load with a current draw of 14.4 kW, a plant with an equivalent load resistor of 11.1 $Omega$ was used as shown in @r_plant. 

#figure(
  image("./figures/plant_R_load.png"),
  caption: [Entire system layout with only a static resistive load]
) <r_plant>

Simulations of the output voltage, voltage ripple, inductor current, and current draw were made and data was gathered. the following plots were then acquired. 
#figure(
  image(
    "./figures/R_load/V_out.png",
  ),
  caption: [Output Voltage transience from $t in [0, 2] "s"$]
) <voutr>

#figure(
  image(
    "./figures/R_load/I_out.png",
  ),
  caption: [Output Current transience from $t in [0, 2] "s"$]
) <ioutr>

#figure(
  image(
    "./figures/R_load/curr_draw_and_inductor.png"
  ),
  caption: [Current draw from the grid as well as the inductor current as steady state. ]
)

#figure(
  image(
    "figures/R_load/inductor_current_annotated.png"
  ),
  caption: [current draw of the inductor, with when controller is turned on annotated.]
) <inrush>

Notice how there's a second transience like output in both @voutr and @ioutr, this is from the soft start logic applied in the controller. It ensures that the controller doesn't turn on until a little after the first in-rush current phase (determined at $t = 0.1 "s"$), which mitigates integrator wind-up from the controller as well as mitigates 400A rush-in event to a more manageable double 200A rush-in event spaced 100 ms apart, as shown in @inrush. 

Another thing to note is despite $C_v (s)$ having its output saturate at $60 sqrt(2)$, inductor current still draws all the way to 120 A, which is not a very favorable outcome. To mitigate this, a higher current rated inductor could be chosen or using a 2 by 2 matrix of inductors to mitigate the load on each one. In the industry, a more robust control schema would be utilized to mitigate current overloading, with physical changes to the circuit being made, however, this simulation is never meant to be applied in real-life, and thus such measures were not thoroughly explored. 

== unorthodox control events
//TODO Place your answer for question 3.c here change the subtitle too i have no clue what were demonstrating here

== System with modelled battery as an $R C$ load

In this scenario, instead of an arbitrary resistor $R_"load"$ being placed at the output of the boost converter, an equivalent $R C$ model was added. 

#figure(
  image("./figures/Plant_RC.png"),
  caption: [system model with equivalent battery model.]
)

In this case, The entire controller needs to be redetermined, we need to re-analyze the plant in @tf_il and @tf_vbatt, we can rewrite these in terms of equivalent admittance. in the static $R_"load"$ the equivalent admittance $Y(s) = (s C + 1/R)$, we can rewrite the the aforementioned equations in terms of the admittance. 

$
  frac(tilde(i)_L (s), tilde(d)(s)) = frac(V_"batt" Y(s) + (1-D) I_L, s L Y(s) + (1-D)^2) \
  frac(tilde(v)_"batt" (s), tilde(d)(s)) = frac((1-D) V_"batt" - s L I_L, s L Y(s) + (1-D)^2)
$ <tf_gen>

to determine the new admittance we will calculate the impedance of the output of the new system with the $R C$ equvalent load: 

#let Yrc = $frac(s C_2 R_"ESR" + 1, s^2 C_1 C_2 + s C_2)$

$
  Z(s) = frac(1, s C_1) || (R_"ESR" + frac(1, s C_2)) \
  ==> frac( s^2 C_1 C_2 + s C_2, s C_2 R_"ESR" + 1)
$

where $C_1$ and $C_2$ are the filtering capacitor, and battery capacitance, respectively. to Determine $Y(s)$, we take the inverse of the impedance: 

$
  Y_(R C) (s) = Yrc
$

determining our new transfer functions: 

$
  frac(tilde(i)_L (s), tilde(d)(s)) = frac(V_"batt" ( Yrc ) + (1-D) I_L, s L ( Yrc ) + (1-D)^2) \
  frac(tilde(v)_"batt" (s), tilde(d)(s)) = frac((1-D) V_"batt" - s L I_L, s L ( Yrc ) + (1-D)^2)
$ 

The same principles were used to determine the $K_p$, $K_i$ values, granted it is much more involved and was a pain to figure out. Ball park gains were determined then it was an iterative process to make a functioning controller. 

#figure(
  apa_table(
    columns: (auto, 1fr),
    "Parameter", "Value",
    [$K_(p,i)$ of PI controller $C_v (s)$], [0.01700481],
    [$K_(i,i)$ of PI controller $C_v (s)$], [154.080540],
    [$K_(p,i)$ of PI controller $C_i (s)$], [0.101010],
    [$K_(i,i)$ of PI controller $C_i (s)$], [0.054]
  ),
  caption: [gain values for both PID controllers for an equivalent battery $R = 200 "mF, " C = 40 "F"$]
)

=== simulations

#figure(
  image(
    "./figures/RC_load/V_out_RC.png", 
  ),
  caption: [Output Voltage transience from $t in [0, 10] "s"$ (top), along with steady state voltage ripple (bottom)]
) <voutrc>

Inspecting @voutrc, the voltage ripple is approximately $Delta V_(p p) =  0.04 V$. 

#figure(
  image(
    "./figures/RC_load/I_out_RC.png",
  ),
  caption: [Output Current transience from $t in [0, 10] "s"$ (top), along with steady state current ripple (bottom)]
) <ioutrc>

Doing the same thing for @ioutrc, $Delta i_(p p) =  0.04 V$. It's important that these ripple values are only during steady state, i.e. when the capacitor is practically fully charged, mainly due to transient results being a poor indication of ripple behavior. 

// TODO add more explanation here. Mainly on on the over current during transience. also explain why limiting overcurrent will also kill my PC. 

== Grid-Zero crossing behavior

In CCM PFC, when the instantaneous AC line voltage approaches zero, the inductor current drops below the threshold needed to maintain continuous conduction, causing the converter to fall into discontinuous conduction mode (DCM) near the zero crossing. This means the current reference cannot be tracked accurately during this brief window, introducing distortion into the input current waveform.@McDonald2020PFC

= Power Factor and Total Harmonic Distortion

To calculate total harmonic distortion (THD) and power factor (PF), the following fomulae were used@erickson2020fundamentals. They were mainly implemented as scripts in matlab, to process data from `.mat` files. 

$
"THD" &= (sqrt(sum_(n=2)^(N) I_n^2)) / I_1 times 100% \
"PF"  &= P / S = P / (V_"rms" I_"rms")
$

== Static $R$-load

#figure(
  image(
    "./figures/R_load/thd_harmonics.png", width: 80%
  ),
  caption: [Input current harmonics contributing to total harmonic distortion]
)

#figure(
  apa_table(
    columns: (auto, 1fr),
    "Parameter", "Value",
    "Fundamental Amplitude", "115.70",
    "THD", "4.08%",
    [V#sub[rms]], "240.00 V",
    [I#sub[rms]], "81.89 A",
    "Real Power", "19633.48 W",
    "Apparent Power", "19652.58 VA",
    "Power Factor", "0.9990",
  ),
  caption: [THD and Power Factor Analysis Results for PFC with a static $R_"load"$]
)
== Complex $R C$-load

// TODO calculate RC-load THD and PF, explain THD distortion and maybe steps to mitigate it (optional)

= Conclusion

// TODO write a conclusion

#pagebreak()

#bibliography("references.bib", style: "ieee")