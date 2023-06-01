static const float3 blood = float3(0.04, 0.0, 0.0);

float waterLevel = 0.0;

float fognearstart;
float fognearrange;
float3 fognearcol;

float3 eyepos;

float fov;
float2 rcpres;

float4x4 mview;
float4x4 mproj;

texture lastshader;
texture depthframe;
texture lastpass;

sampler s0 = sampler_state { texture = <lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler s1 = sampler_state { texture = <depthframe>; addressu = clamp; addressv = clamp; magfilter = linear; minfilter = linear; };


float4 sample(sampler2D s, float2 t) {
    return tex2Dlod(s, float4(t, 0, 0));
}

float3 toView(float2 tex, float depth) {
    static const float2 invproj =  2.0 * tan(0.5 * radians(fov)) * float2(1, rcpres.x / rcpres.y);
    float2 xy = depth * (tex - 0.5) * invproj;
    return float3(xy, depth);
}

float3 toWorld(float2 tex) {
    float3 v = float3(mview[0][2], mview[1][2], mview[2][2]);
    v += (1/mproj[0][0] * (2*tex.x-1)).xxx * float3(mview[0][0], mview[1][0], mview[2][0]);
    v += (-1/mproj[1][1] * (2*tex.y-1)).xxx * float3(mview[0][1], mview[1][1], mview[2][1]);
    return v;
}

float4 blendWaterLayer(float2 tex : TEXCOORD0) : COLOR {
    float3 color = tex2D(s0, tex);
    float depth = sample(s1, tex);

    float3 position = eyepos + toWorld(tex) * depth;
    if (position.z <= (waterLevel + 5)) {
        float dist = length(toView(tex, depth));
        float fog = saturate((fognearrange - dist) / (fognearrange - fognearstart));
        float3 bloodfog = lerp(fognearcol, blood, fog);
        color = lerp(color, bloodfog, fog * 0.8);
    }

    return float4(color, 1.0);
}

technique T0<string MGEinterface = "MGE XE 0";> {
    pass { PixelShader = compile ps_3_0 blendWaterLayer(); }
}
