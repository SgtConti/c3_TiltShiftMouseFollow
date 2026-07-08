%%FRAGMENTINPUT_STRUCT%%
%%FRAGMENTOUTPUT_STRUCT%%
%%C3PARAMS_STRUCT%%
%%C3_UTILITY_FUNCTIONS%%

%%SAMPLERFRONT_BINDING%% var samplerFront : sampler;
%%TEXTUREFRONT_BINDING%% var textureFront : texture_2d<f32>;

struct ShaderParams {
	mouseX : f32,
	mouseY : f32,
	angleDeg : f32,
	focusSize : f32,
	transitionSize : f32,
	blurRadius : f32,
	intensity : f32,
	mode : f32,
	ellipseAspect : f32
};
%%SHADERPARAMS_BINDING%% var<uniform> shaderParams : ShaderParams;

fn sat(x: f32) -> f32 { return clamp(x, 0.0, 1.0); }

fn smooth01(a: f32, b: f32, x: f32) -> f32 {
	let t: f32 = sat((x - a) / (b - a));
	return t * t * (3.0 - 2.0 * t);
}

fn sample0(uv: vec2<f32>) -> vec4<f32> {
	return textureSampleLevel(textureFront, samplerFront, uv, 0.0);
}

@fragment
fn main(input: FragmentInput) -> FragmentOutput
{
	let texDimU: vec2<u32> = textureDimensions(textureFront);
	let texDim: vec2<f32> = max(vec2<f32>(f32(texDimU.x), f32(texDimU.y)), vec2<f32>(1.0, 1.0));
	let pixelSize: vec2<f32> = 1.0 / texDim;

	let layoutPos: vec2<f32> = c3_getLayoutPos(input.fragUV);
	let focusPos: vec2<f32> = vec2<f32>(shaderParams.mouseX, shaderParams.mouseY);

	let ang: f32 = radians(shaderParams.angleDeg);
	let dir: vec2<f32> = vec2<f32>(cos(ang), sin(ang));
	let n: vec2<f32> = vec2<f32>(-dir.y, dir.x);
	let distBand: f32 = abs(dot(layoutPos - focusPos, n));

	let delta: vec2<f32> = layoutPos - focusPos;
	let distRadial: f32 = length(delta);

	let asp: f32 = max(abs(shaderParams.ellipseAspect), 0.01);
	let distEllipse: f32 = length(vec2<f32>(delta.x / asp, delta.y));

	let m: f32 = sat(shaderParams.mode);
	let t1: f32 = sat(m * 2.0);
	let t2: f32 = sat((m - 0.5) * 2.0);

	let distBE: f32 = distBand + (distEllipse - distBand) * t1;
	let dist: f32 = distBE + (distRadial - distBE) * t2;

	let blurFactor: f32 = smooth01(shaderParams.focusSize, shaderParams.focusSize + shaderParams.transitionSize, dist) * shaderParams.intensity;
	let r: f32 = shaderParams.blurRadius * blurFactor;

	let uv: vec2<f32> = input.fragUV;
	let center: vec4<f32> = sample0(uv);

	var output: FragmentOutput;

	if (r <= 0.0001) {
		output.color = center;
		return output;
	}

	let o: vec2<f32> = pixelSize * r;

	var s: vec4<f32> = center;
	s += sample0(uv + vec2<f32>(o.x, 0.0));
	s += sample0(uv - vec2<f32>(o.x, 0.0));
	s += sample0(uv + vec2<f32>(0.0, o.y));
	s += sample0(uv - vec2<f32>(0.0, o.y));
	s += sample0(uv + vec2<f32>(o.x, o.y));
	s += sample0(uv - vec2<f32>(o.x, o.y));
	s += sample0(uv + vec2<f32>(o.x, -o.y));
	s += sample0(uv + vec2<f32>(-o.x, o.y));

	output.color = s / 9.0;
	return output;
}