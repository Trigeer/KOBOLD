-- Resolution constants (612x480, scaled 3x up)
Scaling = 3
ScreenWidth  = 204
ScreenHeight = 160

-- Rendering constants
ShadowIntensity = 0.33

-- Field of View
Hfov = 0.73 --* ScreenHeight / ScreenWidth
Vfov = 0.2

SensitivityX = 0.03
SensitivityY = 0.05

-- Camera constraints
EyeHeight  = 6      -- Height of camera by default
DuckHeight = 2.5    -- Height of camera when crouched
HeadMargin = 1      -- Bumping margin above camera
KneeHeight = 2      -- Max height of step
Speed      = 0.05   -- Speed modifier
DecayLow   = 0.95   -- Speed percentage retained when moving
DecayTop   = 0.85    -- Speed percentage retained when not moving
WallOffset = 0.5    -- Camera collider radius

RenderDepth = 10