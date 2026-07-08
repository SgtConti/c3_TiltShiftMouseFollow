// Tilt Shift Mouse Follow (WebGL)
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

varying vec2 vTex;
uniform sampler2D samplerFront;
uniform sampler2D samplerBack;
uniform vec2 srcOriginStart;
uniform vec2 srcOriginEnd;
uniform vec2 layoutStart;
uniform vec2 layoutEnd;
uniform vec2 pixelSize;

uniform float mouseX;
uniform float mouseY;
uniform float angleDeg;
uniform float focusSize;
uniform float transitionSize;
uniform float blurRadius;
uniform float intensity;
uniform float mode;
uniform float ellipseAspect;

float sat(float x){ return clamp(x, 0.0, 1.0); }
float smooth01(float a, float b, float x){
    float t = sat((x - a) / max(b - a, 1e-6));
    return t * t * (3.0 - 2.0 * t);
}
vec4 sampleBase(vec2 uv){
    vec4 front = texture2D(samplerFront, uv);
    vec4 back = texture2D(samplerBack, uv);
    return front + back * (1.0 - front.a);
}

void main(void){
    vec2 denom = max(srcOriginEnd - srcOriginStart, vec2(1e-6));
    vec2 tt = (vTex - srcOriginStart) / denom;
    vec2 layoutSize = max(layoutEnd - layoutStart, vec2(1e-6));
    vec2 focusT = (vec2(mouseX, mouseY) - layoutStart) / layoutSize;
    vec2 delta = (tt - focusT) * layoutSize;

    float ang = radians(angleDeg);
    vec2 dir = vec2(cos(ang), sin(ang));
    float distBand = abs(dot(delta, vec2(-dir.y, dir.x)));
    float distRadial = length(delta);
    float asp = max(abs(ellipseAspect), 0.01);
    float distEllipse = length(vec2(delta.x / asp, delta.y));
    float m = sat(mode);
    float dist = mix(mix(distBand, distEllipse, sat(m * 2.0)), distRadial, sat((m - 0.5) * 2.0));

    float blurFactor = smooth01(focusSize, focusSize + transitionSize, dist) * intensity;
    float r = blurRadius * blurFactor;
    vec4 center = sampleBase(vTex);
    if (r <= 0.0001){
        gl_FragColor = center;
        return;
    }
    vec2 o = pixelSize * r;
    vec4 s = center * 0.40;
    s += sampleBase(vTex + vec2(o.x, 0.0)) * 0.15;
    s += sampleBase(vTex - vec2(o.x, 0.0)) * 0.15;
    s += sampleBase(vTex + vec2(0.0, o.y)) * 0.15;
    s += sampleBase(vTex - vec2(0.0, o.y)) * 0.15;
    gl_FragColor = s;
}
