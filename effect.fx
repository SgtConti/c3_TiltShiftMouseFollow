#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

varying vec2 vTex;
uniform lowp sampler2D samplerFront;

// Construct 3 provides these in layout/world units and UVs.
// We avoid doing subtracts on large layout coordinates in mediump by
// working in normalized layout space first (tt) and only then scaling.
uniform highp vec2 srcOriginStart;
uniform highp vec2 srcOriginEnd;
uniform highp vec2 layoutStart;
uniform highp vec2 layoutEnd;
uniform highp vec2 pixelSize;

uniform highp float mouseX;
uniform highp float mouseY;
uniform highp float angleDeg;
uniform highp float focusSize;
uniform highp float transitionSize;
uniform highp float blurRadius;
uniform highp float intensity;
uniform highp float mode;
uniform highp float ellipseAspect;

highp float sat(highp float x){ return clamp(x, 0.0, 1.0); }
highp float smooth01(highp float a, highp float b, highp float x){
    highp float t = sat((x - a) / max(b - a, 1e-6));
    return t * t * (3.0 - 2.0 * t);
}

void main(){
    // tt is the normalized position in the source rect (0..1-ish), which is stable even for huge layouts.
    highp vec2 denom = max(srcOriginEnd - srcOriginStart, vec2(1e-6, 1e-6));
    highp vec2 tt = (vTex - srcOriginStart) / denom;

    // Convert focus point to the same normalized space, then compute delta there.
    highp vec2 layoutSize = max(layoutEnd - layoutStart, vec2(1e-6, 1e-6));
    highp vec2 focusPos = vec2(mouseX, mouseY);
    highp vec2 focusT = (focusPos - layoutStart) / layoutSize;

    // Delta in layout units, but without catastrophic cancellation from large coordinates.
    highp vec2 delta = (tt - focusT) * layoutSize;

    highp float ang = radians(angleDeg);
    highp vec2 dir = vec2(cos(ang), sin(ang));
    highp vec2 n = vec2(-dir.y, dir.x);
    highp float distBand = abs(dot(delta, n));

    highp float distRadial = length(delta);

    highp float asp = max(abs(ellipseAspect), 0.01);
    highp float distEllipse = length(vec2(delta.x / asp, delta.y));

    highp float m = sat(mode);
    highp float t1 = sat(m * 2.0);
    highp float t2 = sat((m - 0.5) * 2.0);

    highp float distBE = mix(distBand, distEllipse, t1);
    highp float dist = mix(distBE, distRadial, t2);

    highp float blurFactor = smooth01(focusSize, focusSize + transitionSize, dist) * intensity;
    highp float r = blurRadius * blurFactor;

    lowp vec4 center = texture2D(samplerFront, vTex);
    if (r <= 0.0001){
        gl_FragColor = center;
        return;
    }

    highp vec2 o = pixelSize * r;

    lowp vec4 s = center;
    s += texture2D(samplerFront, vTex + vec2(o.x, 0.0));
    s += texture2D(samplerFront, vTex - vec2(o.x, 0.0));
    s += texture2D(samplerFront, vTex + vec2(0.0, o.y));
    s += texture2D(samplerFront, vTex - vec2(0.0, o.y));
    s += texture2D(samplerFront, vTex + vec2(o.x, o.y));
    s += texture2D(samplerFront, vTex - vec2(o.x, o.y));
    s += texture2D(samplerFront, vTex + vec2(o.x, -o.y));
    s += texture2D(samplerFront, vTex + vec2(-o.x, o.y));

    gl_FragColor = s / 9.0;
}
