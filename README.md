# bevy_video_glitch

This crate provides a post processing video glitch effect for the [bevy game engine](https://bevyengine.org). 

![Cube example of video glitch](https://github.com/shanecelis/bevy_video_glitch/raw/master/assets/movies/video-glitch.mp4)



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

Run the example like so:

``` sh
cargo run --example cube
```

This will show a rotating cube like the one shown at the beginning of this README.

# License

This crate is licensed under MIT License or the Apache License 2.0.

# Acknowlegments

* [Video Glitch](https://www.shadertoy.com/view/XtK3W3) by [dyvoid](https://www.shadertoy.com/user/dyvoid).

* [Post Processing](https://github.com/bevyengine/bevy/blob/v0.12.1/examples/shader/post_processing.rs) example from [bevy](https://bevyengine.org), which I wrote a series of toots about [here](https://mastodon.gamedev.place/@shanecelis/111583689226043395).
