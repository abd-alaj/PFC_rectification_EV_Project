#import "template.typ": *

// Check for the private compile flag
#let use-private = sys.inputs.at("private", default: "false") == "true"

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
    I shidded my pant
  ],
)

= Introduction
The design of an electric vehicle (EV) charging system requires a multistage power conversion architecture to convert alternating current (AC) from the utility grid with a high voltage DC battery pack. Let grid voltage $v_(a c)$ be a 240 volt RMS sinusoidal wave that must be converted to a 400-volt DC output, suitable to charge an EV battery. The abstracted architecture of the system, illustrated in @fig-ev-arch, defines the primary functional blocks and their respective roles in the conversion process.

#figure( 
  image("./figures/arch-rectifier.svg", width: 80%),
  caption: [High level architectural overview of the rectifier and PFC circuit.] 
) <fig-ev-arch>

In @fig-ev-arch, the DC-AC, transformer, and AC-DC stages are idealized as a 1:1 transformer, and omitted from the architectural diagram, making design slightly easier for this final project. 

= Power Stage Topology
The front end of the system utilizes an uncontrolled full-bridge rectifier to convert the AC mains voltage to a pulsating DC bus. This is immediately followed by a boost converter to regulate the voltage step-up, as shown in @fig-rectifier-boost.

#figure(
  image("./figures/onboard_charging_circuit_model.svg", width: 80%),
  caption: [Full-Bridge Rectifier and Boost Converter Topology]
) <fig-rectifier-boost>

= Calculations
== Assumptions and Parameters


#figure(
  apa_table(
    columns: (auto, 1fr),
    headers: ("Parameters", "Value"),
    [Grid Voltage], [ 240V RMS $:= 240 sqrt(2) cos(2 pi 60 t)$],
    [Current Draw], [60A RMS $:= 60 sqrt(2) cos(2 pi 60 t)$],
    [Power Factor ], [1],
    [Battery Load], [$C_("batt") = 40 F, " " R_("ESR") = 200 m Omega$],
    [Max $Delta i_L$], [3A]
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


#pagebreak()

#bibliography("references.bib", style: "ieee")