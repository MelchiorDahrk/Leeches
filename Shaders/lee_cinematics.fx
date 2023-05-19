float time;
float2 rcpres;

static const float BORDER_RATIO = 1.3;
static const float3 GRAIN_STRENGTH = float3(25.0, 25.0, 25.0);
static const float3 BLACK = float3(0.0, 0.0, 0.0);

texture lastshader;

sampler s0 = sampler_state { texture = <lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

float3 vignette(float2 coord, float3 color) {
    float2 resolution = 1.0 / rcpres;
    float aspect_ratio = resolution.x / resolution.y;

    float2 width;
    if (aspect_ratio < BORDER_RATIO)
        width = float2(0.0, (resolution.y - (resolution.x / BORDER_RATIO)) * 0.5);
    else
        width = float2((resolution.x - (resolution.y * BORDER_RATIO)) * 0.5, 0.0);

    float2 border = rcpres * width;
    float2 inside = saturate((-coord * coord + coord) - (-border * border + border));
    return all(inside) ? color : BLACK;
}

float3 grain(float2 texcoord, float3 color) {
    float x = (texcoord.x + 4.0) * (texcoord.y + 4.0) * (time * 10.0);
    float y = fmod((fmod(x, 13.0) + 1.0) * (fmod(x, 123.0) + 1.0), 0.01) - 0.005;
    return color + (GRAIN_STRENGTH * y);
}

float3 grayscale(float3 color) {
    float gray = dot(color, float3(0.299, 0.587, 0.114));
    return float3(gray, gray, gray);
}

float4 draw(float2 texcoord : TEXCOORD0) : COLOR {
    float3 color = tex2D(s0, texcoord);
    color = grayscale(color);
    color = grain(texcoord, color);
    color = vignette(texcoord, color);
    return float4(color, 1.0);
}

technique T0<string MGEinterface = "MGE XE 0";>
{
    pass { PixelShader = compile ps_3_0 draw(); }
}
