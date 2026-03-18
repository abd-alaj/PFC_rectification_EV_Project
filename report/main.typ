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

Usually, in commercial design, a ballpark frequency is chosen based on the technology, (SiC, GaN, etc.) and then an inductor is chosen. Thus, we will choose a ballpark frequency of 100 KHz, which is approximately the values chosen in switching speeds concerning GaN technology@gan_ev_review_2025.

#pagebreak()

#bibliography("references.bib", style: "ieee")