-- Resolution constants (612x480, scaled 3x up)
-- Scaling = 3
-- ScreenWidth  = 204
-- ScreenHeight = 160

Scaling = 1
ScreenWidth  = 612
ScreenHeight = 480

-- Rendering constants
ShadowIntensity = 5

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
Speed      = 0.03   -- Speed modifier
DecayLow   = 0.9   -- Speed percentage retained when moving
DecayTop   = 0.8    -- Speed percentage retained when not moving
WallOffset = 0.5    -- Camera collider radius

RenderDepth = 10