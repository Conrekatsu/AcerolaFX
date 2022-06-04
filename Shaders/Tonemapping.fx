#include "ReShade.fxh"

uniform int _Tonemapper <
    ui_type = "combo";
    ui_label = "Tonemapper";
    ui_items = "Hill ACES\0"
               "Narkowicz ACES\0";
> = 0;

static const float3x3 ACESInputMat = float3x3(
    float3(0.59719, 0.35458, 0.04823),
    float3(0.07600, 0.90834, 0.01566),
    float3(0.02840, 0.13383, 0.83777)
);

static const float3x3 ACESOutputMat = float3x3(
    float3( 1.60475, -0.53108, -0.07367),
    float3(-0.10208,  1.10813, -0.00605),
    float3(-0.00327, -0.07276,  1.07602)
);

float3 RRTAndODTFit(float3 v) {
    float3 a = v * (v + 0.0245786f) - 0.000090537f;
    float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

float3 HillACES(float3 col) {
    col = mul(ACESInputMat, col);
    col = RRTAndODTFit(col);
    return mul(ACESOutputMat, col);
}

float3 NarkowiczACES(float3 col) {
    return (col * (2.51f * col + 0.03f)) / (col * (2.43f * col + 0.59f) + 0.14f);
}

float4 PS_Tonemap(float4 position : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
    float4 col = tex2D(ReShade::BackBuffer, uv).rgba;
    float UIMask = 1.0f - col.a;

    float3 output = col.rgb;

    if (_Tonemapper == 0)
        output = HillACES(output);
    else if (_Tonemapper == 1)
        output = NarkowiczACES(output);

    return float4(lerp(col.rgb, output, UIMask), col.a);
}

technique Tonemapping {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Tonemap;
    }
}