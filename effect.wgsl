// Tilt Shift Mouse Follow (WGSL)
%%FRAGMENTINPUT_STRUCT%%
%%FRAGMENTOUTPUT_STRUCT%%
%%C3PARAMS_STRUCT%%
%%C3_UTILITY_FUNCTIONS%%

%%SAMPLERFRONT_BINDING%% var samplerFront: sampler;
%%TEXTUREFRONT_BINDING%% var textureFront: texture_2d<f32>;
%%SAMPLERBACK_BINDING%% var samplerBack: sampler;
%%TEXTUREBACK_BINDING%% var textureBack: texture_2d<f32>;

struct ShaderParams {
    mouseX: f32,
    mouseY: f32,
    angleDeg: f32,
    focusSize: f32,
    transitionSize: f32,
    blurRadius: f32,
    intensity: f32,
    mode: f32,
    ellipseAspect: f32
};
%%SHADERPARAMS_BINDING%% var<uniform> shaderParams: ShaderParams;

fn sat(x: f32) -> f32 { return clamp(x, 0.0, 1.0); }
fn smooth01(a: f32, b: f32, x: f32) -> f32 {
    let t = sat((x - a) / max(b - a, 1e-6));
    return t * t * (3.0 - 2.0 * t);
}
fn sampleBase(uvFront: vec2<f32>, uvBack: vec2<f32>) -> vec4<f32> {
    let front = textureSampleLevel(textureFront, samplerFront, uvFront, 0.0);
    let back = textureSampleLevel(textureBack, samplerBack, uvBack, 0.0);
    return front + back * (1.0 - front.a);
}

@fragment
fn main(input: FragmentInput) -> FragmentOutput {
    let layoutPos = c3_getLayoutPos(input.fragUV);
    let focusPos = vec2<f32>(shaderParams.mouseX, shaderParams.mouseY);
    let delta = layoutPos - focusPos;

    let ang = radians(shaderParams.angleDeg);
    let dir = vec2<f32>(cos(ang), sin(ang));
    let distBand = abs(dot(delta, vec2<f32>(-dir.y, dir.x)));
    let distRadial = length(delta);
    let asp = max(abs(shaderParams.ellipseAspect), 0.01);
    let distEllipse = length(vec2<f32>(delta.x / asp, delta.y));
    let m = sat(shaderParams.mode);
    let dist = mix(mix(distBand, distEllipse, sat(m * 2.0)), distRadial, sat((m - 0.5) * 2.0));

    let blurFactor = smooth01(shaderParams.focusSize, shaderParams.focusSize + shaderParams.transitionSize, dist) * shaderParams.intensity;
    let r = shaderParams.blurRadius * blurFactor;
    let uv = input.fragUV;
    // The background texture has its own co-ordinate space.
    let backUV = c3_getBackUV(input.fragPos.xy, textureBack);
    let center = sampleBase(uv, backUV);
    var output: FragmentOutput;
    if (r <= 0.0001) {
        output.color = center;
        return output;
    }
    // Texel sizes are only needed on the blur path.
    let o = r / vec2<f32>(textureDimensions(textureFront));
    let ob = r / vec2<f32>(textureDimensions(textureBack));
    var s = center * 0.40;
    s = s + sampleBase(uv + vec2<f32>(o.x, 0.0), backUV + vec2<f32>(ob.x, 0.0)) * 0.15;
    s = s + sampleBase(uv - vec2<f32>(o.x, 0.0), backUV - vec2<f32>(ob.x, 0.0)) * 0.15;
    s = s + sampleBase(uv + vec2<f32>(0.0, o.y), backUV + vec2<f32>(0.0, ob.y)) * 0.15;
    s = s + sampleBase(uv - vec2<f32>(0.0, o.y), backUV - vec2<f32>(0.0, ob.y)) * 0.15;
    output.color = s;
    return output;
}
