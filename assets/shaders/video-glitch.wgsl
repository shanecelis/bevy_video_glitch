// Description : Array and textureless GLSL 2D simplex noise function.
// Author : Ian McEwan, Ashima Arts.
// Maintainer : stegu
// Lastmod : 20110822 (ijm)
// License : Copyright (C) 2011 Ashima Arts. All rights reserved.
// Distributed under the MIT License. See LICENSE file.
// https://github.com/ashima/webgl-noise
// https://github.com/stegu/webgl-noise
// https://www.shadertoy.com/view/XtK3W3

#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput
#import bevy_render::globals::Globals

struct VideoGlitchSettings {
    intensity: f32,
#ifdef SIXTEEN_BYTE_ALIGNMENT
    // WebGL2 structs must be 16 byte aligned.
    _webgl2_padding: vec3<f32>
#endif
}

@group(0) @binding(0) var screen_texture: texture_2d<f32>;
@group(0) @binding(1) var texture_sampler: sampler;
@group(0) @binding(2) var<uniform> settings: VideoGlitchSettings;
@group(0) @binding(3) var<uniform> globals: Globals;

fn mod289(x: vec3<f32>) -> vec3<f32> {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

fn mod289v2(x: vec2<f32>) -> vec2<f32> {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

fn permute(x: vec3<f32>) -> vec3<f32> {
    return mod289(((x * 34.0) + 1.0) * x);
}

fn snoise(v: vec2<f32>) -> f32 {
    let C: vec4<f32> = vec4<f32>(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                                  0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                                  -0.577350269189626, // -1.0 + 2.0 * C.x
                                  0.024390243902439); // 1.0 / 41.0

    // First corner
    var i: vec2<f32> = floor(v + dot(v, C.yy));
    let x0: vec2<f32> = v - i + dot(i, C.xx);

    // Other corners
    let i1: vec2<f32> = select(vec2<f32>(0.0, 1.0), vec2<f32>(1.0, 0.0), x0.x > x0.y);
    var x12: vec4<f32> = x0.xyxy + C.xxzz;
    x12.x -= i1.x;
    x12.y -= i1.y;

    // Permutations
    i = mod289v2(i); // Avoid truncation effects in permutation
    let p: vec3<f32> = permute(permute(i.y + vec3<f32>(0.0, i1.y, 1.0))
        + i.x + vec3<f32>(0.0, i1.x, 1.0));

    var m: vec3<f32> = max(vec3<f32>(0.5) - vec3<f32>(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), vec3<f32>(0.0));
    m = m * m;
    m = m * m;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    let x: vec3<f32> = 2.0 * fract(p * C.www) - 1.0;
    let h: vec3<f32> = abs(x) - 0.5;
    let ox: vec3<f32> = floor(x + 0.5);
    let a0: vec3<f32> = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m = m * (1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h));

    // Compute final noise value at P
    let g: vec3<f32> = vec3<f32>(a0.x * x0.x + h.x * x0.y, a0.yz * x12.xz + h.yz * x12.yw);
    return 130.0 * dot(m, g);
}

fn rand(co: vec2<f32>) -> f32 {
    return fract(sin(dot(co.xy, vec2<f32>(12.9898, 78.233))) * 43758.5453);
}

// [[stage(fragment)]]
// fn mainImage(fragCoord: vec2<f32>,
//              fragColor: &mut vec4<f32>) {
@fragment
fn fragment(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
// fn fragment(
//     @builtin(position) position: vec4<f32>,
//     #import bevy_sprite::mesh2d_vertex_output
// ) -> @location(0) vec4<f32> {
    // let uv: vec2<f32> = fragCoord.xy / iResolution.xy;
    let uv = in.uv; //coords_to_viewport_uv(position.xy, view.viewport);
    let time: f32 = globals.time * 2.0;

    // Create large, incidental noise waves
    var noise: f32 = max(0.0, snoise(vec2<f32>(time, uv.y * 0.3)) - 0.3) * (1.0 / 0.7);

    // Offset by smaller, constant noise waves
    noise = noise + (snoise(vec2<f32>(time * 10.0, uv.y * 2.4)) - 0.5) * 0.15;

    // Apply the noise as x displacement for every line
    let xpos: f32 = uv.x - noise * noise * 0.25;
    // fragColor = textureSample(iChannel0, vec2<f32>(xpos, uv.y));
    let texColor: vec4<f32> = textureSample(screen_texture, texture_sampler, vec2<f32>(xpos, uv.y));


    // Mix in some random interference for lines
    var fragColor = mix(texColor.rgb, vec3<f32>(rand(vec2<f32>(uv.y * time))), noise * 0.3);

    // Apply a line pattern every 4 pixels
    if (floor(uv.y * 0.25 % 2.0) == 0.0) {
        fragColor *= 1.0 - (0.15 * noise);
    }

    // Shift green/blue channels (using the red channel)
    // fragColor.g = mix(fragColor.r, textureSample(iChannel0, vec2<f32>(xpos + noise * 0.05, uv.y)).g, 0.25);
    fragColor.g = mix(fragColor.r, textureSample(screen_texture, texture_sampler, vec2<f32>(xpos + noise * 0.05, uv.y)).g, 0.25);
    // fragColor.b = mix(fragColor.r, textureSample(iChannel0, vec2<f32>(xpos - noise * 0.05, uv.y)).b, 0.25);
    fragColor.b = mix(fragColor.r, textureSample(screen_texture, texture_sampler, vec2<f32>(xpos - noise * 0.05, uv.y)).b, 0.25);
    return vec4<f32>(fragColor, texColor.a);
}
