;; Airborne Disease Model CS3200 Final Project
;; Abraham Farias & Steven Crisostomo
;; This model simulates the spread of an infectious disease traveling via air through
;; a randomly moving population.  The user can draw walls, buildings, or obstacles in the
;; environment to simulate different environments.

breed [healthy healthies] ;; Different breeds of turtles to show heatlh state, as well as the particles of disease themselves.
breed [infected infects]
breed [sick sicks]
breed [immune immunes]
breed [dead deads]
breed [ particles particle ]

globals [ ;; Global variables.
  total-healthy                   ;; total number of people healthy
  total-sick                      ;; total number of people sick
  total-infected                  ;; total number of people infected
  total-immune                    ;; total number of people immune
  total-dead                      ;; total number of people dead
  tick-delta                      ;; how much we advance the tick counter this time through
  max-tick-delta                  ;; the largest tick-delta is allowed to be
  init-avg-speed init-avg-energy  ;; initial averages
  avg-speed avg-energy            ;; current averages
  fast medium slow                ;; current counts
  percent-fast percent-medium     ;; percentage of the counts
  percent-slow                    ;; percentage of the counts

]

turtles-own [  ;; Turtle variables.
  turn-check
  wall-turn-check
  incubate
  sickness
  terminal-check
  immune-check
]

particles-own
[
  speed mass energy          ;; particle info
  last-collision
]

to building-draw ;; Use the mouse to draw buildings.
  if mouse-down?
    [
      ask patch mouse-xcor mouse-ycor
        [ set pcolor grey ]]
end

to setup  ;; Initialize the model.
  reset-ticks
  clear-turtles
  set-default-shape particles "dot"
  set max-tick-delta 0.1073
  make-particles
  set init-avg-speed avg-speed
  set init-avg-energy avg-energy
  pop-check
  setup-agents
  update-globals
  do-plots
end

to go  ;; Run the model.
   ask particles [ move ]
   disease-check
   repeat 5 [ ask healthy [ fd 0.2 ] display ]
   repeat 5 [ ask infected [ fd 0.2 ] display ]
   repeat 5 [ ask sick [ fd 0.2 ] display ]
   repeat 5 [ ask immune [ fd 0.2 ] display ]
   update-globals
   do-plots
   tick
end


to setup-agents  ;;  Setup the begining number of agents and their initial states.
  set-default-shape healthy "person"
  set-default-shape infected "person"
  set-default-shape sick "person"
  set-default-shape immune "person"
  set-default-shape dead "caterpillar"

  ask n-of initial-healthy patches with [pcolor  = black]
     [ sprout-healthy 1
      [ set color blue ] ]

  ask n-of initial-sick patches with [pcolor = black]
    [ sprout-sick 1
      [ set color yellow
        set sickness disease-period ] ]

end

to disease-check ;;  Check to see if an infected or sick turtle occupies the same patch.
  ask healthy[
    if any? other turtles-here with [color = yellow]
    [infect]
    if any? other turtles-here with [color = pink]
    [infect]
    wander
  ]

  ask sick[
    if any? other turtles-here with [color = blue]
    [infect]
    wander
    set sickness sickness - 1
    if sickness = 0
    [live-or-die]
  ]

  ask infected[
    if any? other turtles-here with [color = blue]
    [infect]
    wander
    set incubate incubate - 1
    if incubate = 0
    [get-sick]
  ]

  ask immune[wander]
end

to infect ;;  Infect a healthy turtle, test if it is immune and set the incubation timer if it isn't.
  set immune-check random 100
  ifelse immune-check < immune-chance
  [recover]
  [ask healthy-on patch-here[
    set breed infected
    set incubate incubation-period]
  ask infected-on patch-here [set color pink]]
end

to get-sick ;;  Change an infected turtle into an sick turtle and set the disease progression timer.
   set breed sick
   set color yellow
   set sickness disease-period
end

to terminate ;;  Kill a sick turtle who reaches the end of the disease progression and fails the terminal check.
  set breed dead
  set color white
end

to live-or-die ;; Test if the turtle dies from the disease.
  set terminal-check random 100
  ifelse terminal-check < terminal-chance
  [terminate]
  [recover]
end

to recover  ;;  Change turtle breed to immune.
  set breed immune
  set color sky
end


to wander ;; Random movement for agents.
    set turn-check random 20
    if turn-check > 15
    [right-turn]
    if turn-check < 5
    [left-turn]
     if [pcolor] of patch-ahead 1 != black
     [wall]

end

to wall ;;  Turn agent away from wall
    set wall-turn-check random 10
    if wall-turn-check >= 6
    [wall-right-turn]
    if wall-turn-check <= 5
    [wall-left-turn]
end

to wall-right-turn ;; Generate a random degree of turn for the wall sub-routine.
  rt 170
end

to wall-left-turn ;; Generate a random degree of turn for the wall sub-routine.
  lt 170
end

to right-turn ;; Generate a random degree of turn for the wander sub-routine.
  rt random-float 10
end

to left-turn   ;; Generate a random degree of turn for the wander sub-routine.
  lt random-float 10
end

to make-particles   ;; creates initial particles
  create-particles number-of-particles
  [
    setup-particle
    random-position
  ]
  calculate-tick-delta
end

to setup-particle  ;; particle procedure
  set color yellow
  set speed init-particle-speed
  set mass particle-mass
  set energy (0.5 * mass * (speed ^ 2))
  set last-collision nobody
end


to random-position ;; particle procedure, place particle at random location inside the box.
  setxy ((1 + min-pxcor) + random-float ((2 * max-pxcor) - 2))
        ((1 + min-pycor) + random-float ((2 * max-pycor) - 2))
end

to calculate-tick-delta
  ;; tick-delta is calculated in such way that even the fastest
  ;; particle will jump at most 1 patch length in a tick. As
  ;; particles jump (speed * tick-delta) at every tick, making
  ;; tick length the inverse of the speed of the fastest particle
  ;; (1/max speed) assures that. Having each particle advance at most
  ;; one patch-length is necessary for them not to jump over each other
  ;; without colliding.
  ifelse any? particles with [speed > 0]
    [ set tick-delta min list (1 / (ceiling max [speed] of particles)) max-tick-delta ]
    [ set tick-delta max-tick-delta ]
end

to update-globals ;; Set globals to current values for reporters.
  set total-healthy (count healthy)
  set total-infected (count infected)
  set total-sick (count sick)
  set total-immune (count immune)
  set total-dead (count dead)
end

to move  ;; particle procedure
  if patch-ahead (speed * tick-delta) != patch-here
    [ set last-collision nobody ]
  jump (speed * tick-delta)
  if [pcolor] of patch-ahead 1 != black
     [wall]
end

to do-plots ;; Update graph.
  set-current-plot "Population Totals"
  set-current-plot-pen "Healthy"
  plot total-healthy
  set-current-plot-pen "Infected"
  plot total-infected
  set-current-plot-pen "Sick"
  plot total-sick
  set-current-plot-pen "Immune"
  plot total-immune
  set-current-plot-pen "Dead"
  plot total-dead

end

to pop-check  ;; Make sure total population does not exceed total number of patches.
  if initial-healthy + initial-sick > count patches
    [ user-message (word "This simulation only has room for " count patches " agents.")
      stop ]
end


; This model was built using a combination of these two models :


; Infectious Disease Model
; *** NetLogo 4.1 Model Copyright Notice ***
;
; Copyright 2010 by Michael D. Ball.  All rights reserved.
;
; Permission to use, modify or redistribute this model is hereby granted,
; provided that both of the following requirements are followed:
; a) this copyright notice is included.
; b) this model will not be redistributed for profit without permission
;    from Michael D. Ball.
; Contact Michael D. Ball for appropriate licenses for redistribution for
; profit.
;
; To refer to this model in academic publications, please use:
; Ball, M. (2010).  Infectious Disease Model ver. 1.
; http://www.personal.kent.edu/~mdball/netlogo_models.htm.
; The Center for Complexity in Health,
; Kent State University at Ashtabula, Ashtabula, OH.
;
; In other publications, please use:
; Copyright 2010 Michael D. Ball.  All rights reserved.
; See http://www.personal.kent.edu/~mdball/netlogo_models.htm
; for terms of use.
;
; *** End of NetLogo 4.1 Model Copyright Notice ***


; Gas Particle Physics from: GasLab Free Gas Model in NetLogo Library
; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
25
10
89
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
102
10
165
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
215
460
387
493
initial-healthy
initial-healthy
0
1000
300.0
1
1
NIL
HORIZONTAL

SLIDER
400
460
572
493
initial-sick
initial-sick
0
1000
0.0
1
1
NIL
HORIZONTAL

SLIDER
310
505
482
538
incubation-period
incubation-period
1
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
210
555
382
588
disease-period
disease-period
1
20
15.0
1
1
NIL
HORIZONTAL

SLIDER
395
555
567
588
immune-chance
immune-chance
0
100
5.0
1
1
%
HORIZONTAL

SLIDER
305
600
477
633
terminal-chance
terminal-chance
0
100
5.0
1
1
%
HORIZONTAL

BUTTON
50
55
142
88
Draw Walls
building-draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
95
100
128
Clear Turtles
clear-turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
110
95
187
128
Clear All
clear-all\nreset-ticks
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
660
10
1130
410
Population Totals
steps
populations
0.0
50.0
0.0
50.0
true
true
"" ""
PENS
"Healthy" 1.0 0 -13345367 true "" ""
"Infected" 1.0 0 -2064490 true "" ""
"Sick" 1.0 0 -1184463 true "" ""
"Immune" 1.0 0 -13791810 true "" ""
"Dead" 1.0 0 -16777216 true "" ""

MONITOR
680
425
767
470
Total Healthy
total-healthy
17
1
11

MONITOR
870
425
962
470
Total Infected
total-infected
17
1
11

MONITOR
970
425
1032
470
Total Sick
total-sick
17
1
11

MONITOR
775
425
862
470
Total Immune
total-immune
17
1
11

MONITOR
1040
425
1112
470
Total Dead
total-dead
17
1
11

SLIDER
15
165
187
198
number-of-particles
number-of-particles
0
50
15.0
1
1
NIL
HORIZONTAL

SLIDER
15
215
187
248
init-particle-speed
init-particle-speed
0
20
4.0
1
1
NIL
HORIZONTAL

SLIDER
15
265
187
298
particle-mass
particle-mass
0
5
1.0
1
1
NIL
HORIZONTAL

SLIDER
15
315
187
348
particle-size
particle-size
0
1
0.3
.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model simulates the spread of an airborne pathogen through a randomly moving population.  The user can draw walls, buildings, or obstacles in the environment to simulate different environments.

## HOW IT WORKS

The agents will wander randomly throughout the simulated area. If a healthy agent occupies a patch with a pathogen particle or an agent who is already infected, the healthy agent has a chance to become infected. This is controled by the immune-chance slider. A healthy agent that does not become infected will gain immunity to the disease, otherwise an agent will remain infected for a period determined by the incubation-period slider.  During this time, the agent will be contagious. Once the incubation period ends, the agent becomes sick.  Sick agents remain contagious through the length of the disease period, which is controlled by the disease-period slider. 

At the end of the disease period, the agent either dies or recovers and becomes fully immune. This is determined by the terminal-chance slider. Typically, the simulation will stagnate with all living agents immune to the disease. However, depending on how you set up the grid using the draw-walls button, you can end up with agents that were never introduced to the disease in the first place, try to make a grid where this occurs!

## HOW TO USE IT

1. Use the Draw Walls button to create different landscapes for the agents to move around.  
2. Set the initial healthy and sick populations.
3. Set the number of particles you would like to be in the "air". (How "suddenly" the disease occurs and spreads.)
3. Set the incubation and disease period to desired levels.  
4. Set the chance for immunity and terminal illness.  
5. Click Setup to populate the simulation grid.  
6. Click Go to set the agents in motion.

***Clear Turtles will remove agents and leave your landscape in place.  Click Clear All completely reset the model.

***The graph can be hard to read if time steps are set to the normal-speed option, we recommend setting it slow enough to where you are able to read the graph as the agents become infected in real time.

## EXTENDING THE MODEL

This model is for infectious disease that spreads via an airborne pathogen, then contact following infection. Future models could possibly show the progression of various other types of spreading disease, or even extend the model to where non-infected agents actively attempt to avoid infected ones.

## CREDITS AND REFERENCES

The original infectious disease model was developed as a part of research work for The Center for Complexity in Health at Kent State University Ashtabula.

*****************************************************************************

The particle physics for the airborne pathogen was based on the GasLab Free Gas model in the NetLogo model library:

Wilensky, U. (1997). NetLogo GasLab Free Gas model. http://ccl.northwestern.edu/netlogo/models/GasLabFreeGas. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

caterpillar
true
0
Polygon -7500403 true true 165 210 165 225 135 255 105 270 90 270 75 255 75 240 90 210 120 195 135 165 165 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 60 225 105 225 135 210 150 210 165 195 195 180 210
Line -16777216 false 135 255 90 210
Line -16777216 false 165 225 120 195
Line -16777216 false 135 165 180 210
Line -16777216 false 150 150 201 186
Line -16777216 false 165 135 210 150
Line -16777216 false 165 120 225 120
Line -16777216 false 165 106 221 90
Line -16777216 false 157 91 210 60
Line -16777216 false 150 60 180 45
Line -16777216 false 120 30 96 26
Line -16777216 false 124 0 135 15

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
