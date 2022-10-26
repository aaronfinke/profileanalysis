# ProfileAnalysis

Utilities for handling CrystFEL's indexamajig profiling output.

## Quick start
```julia
  using ProfileAnalysis
  t = loadprofiles("profile-85.log")
  r = map(significanttimes, averagetimes(t, 100))
  plottimes(r)
```
