# Tilt Shift Mouse Follow

Construct 3 effect addon for a focus-following tilt-shift blur. It supports both WebGL and WebGPU.

## Addon ID

`sgtconti_tilt_shift_mouse_follow`

## Features

- Focus point controlled by layout X/Y coordinates.
- Band, ellipse and radial focus modes.
- Background sampling support for use as a layer effect above scene content.
- Reduced 5-sample blur path for lower shader cost.

## Parameters

| Parameter | Description |
|---|---|
| Focus X | Layout X coordinate of the focus point. |
| Focus Y | Layout Y coordinate of the focus point. |
| Angle | Band angle in degrees. |
| Focus size | Distance around the focus kept sharp. |
| Transition | Soft transition distance into blur. |
| Blur radius | Maximum blur radius in pixels. |
| Intensity | Overall blur strength. |
| Mode | `0` = band, `50` = ellipse, `100` = radial. |
| Ellipse aspect | Horizontal scale for ellipse mode. |

## Suggested layer setup

For a whole-scene postprocess, apply the effect to a transparent layer above the scene and pass the mouse/touch position in layout coordinates to **Focus X** and **Focus Y**.
