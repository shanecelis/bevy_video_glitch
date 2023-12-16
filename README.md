# bevy_video_glitch

This crate provides a post processing video glitch effect for the bevy game engine. 

# Install

``` sh
cargo add bevy_video_glitch
```

# Usage

## Add plugin to app
``` rust
app.add_plugins(VideoGlitchPlugin)
```

## Add settings to camera

``` rust
    commands.spawn((
        Camera3dBundle::default(),
        // This component is also used to determine on which camera to run the post processing effect.
        VideoGlitchSettings {
            intensity: 1.0,
            color_aberration: Mat3::IDENTITY
        },
    ));
```

# Example
