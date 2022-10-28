# ProfileAnalysis

Utilities for handling CrystFEL's indexamajig profiling output.

## Quick start
```julia
  using ProfileAnalysis
  t = loadprofiles("profile-85.log")
  plottimes(t, 133)  # Average in blocks of 133 frames
  plottimes(t[1:500], 1)  # First 500 frames, no averaging
```
