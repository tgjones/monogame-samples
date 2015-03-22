static const uint NumCascades = 4;

// Parameters.

matrix World;
matrix ViewProjection;

float3 CameraPosWS;
matrix ShadowMatrix;
float4 CascadeSplits;
float4 CascadeOffsets[NumCascades];
float4 CascadeScales[NumCascades];

float3 LightDirection;
float3 LightColor;
float3 DiffuseColor;

// Resources.

Texture2D ShadowMap : register(t0);

SamplerComparisonState ShadowSampler : register(s0);

// Structures.

struct VSInput
{
    float3 PositionOS : SV_POSITION;
    float3 Color      : COLOR;
    float3 NormalOS   : NORMAL;
};

struct VSOutput
{
    float4 PositionCS : SV_Position;
    float3 PositionWS : POSITIONWS;
    float3 NormalWS   : NORMALWS;
    float DepthVS     : DEPTHVS;
};

struct PSInput
{
    float4 PositionSS : SV_Position;
    float3 PositionWS : POSITIONWS;
    float3 NormalWS   : NORMALWS;
    float DepthVS     : DEPTHVS;
};

// Vertex shader.

VSOutput VSMesh(VSInput input)
{
    VSOutput output;

    // Calculate the world space position.
    output.PositionWS = mul(float4(input.PositionOS, 1), World).xyz;

    // Calculate the clip space position.
    output.PositionCS = mul(float4(output.PositionWS, 1), ViewProjection);

    output.DepthVS = output.PositionCS.w;

    // Rotate the normal into world space.
    output.NormalWS = normalize(mul(input.NormalOS, (float3x3) World));

    return output;
}

// Pixel shader.

float4 PSMesh(PSInput input,
    bool visualizeCascades, bool filterAcrossCascades, 
    int filterSize)
{
    float4 r = ShadowMap.SampleCmpLevelZero(ShadowSampler, float2(0, 0), 0.0) * 0.0001;

    // Normalize after interpolation.
    float3 normalWS = normalize(input.NormalWS);

    // Convert color to grayscale, just beacuse it looks nicer.
    float diffuseValue = 0.299 * DiffuseColor.r + 0.587 * DiffuseColor.g + 0.114 * DiffuseColor.b;
    float3 diffuseAlbedo = float3(diffuseValue, diffuseValue, diffuseValue);

    float nDotL = saturate(dot(normalWS, LightDirection));
    uint2 screenPos = uint2(input.PositionSS.xy);
    float3 shadowVisibility = 1.0f; // TODO

    float3 lighting = 0.0f;

    // Add the directional light.
    lighting += nDotL * LightColor * diffuseAlbedo * (1.0f / 3.14159f) * shadowVisibility;

    // Ambient light.
    lighting += float3(0.2f, 0.2f, 0.2f) * 1.0f * diffuseAlbedo;

    lighting += r.rgb; // TODO: REMOVE ME.

    return float4(max(lighting, 0.0001f), 1) + r;
}

float4 PSMeshVisualizeFalseFilterFalseFilterSizeFilter2x2(PSInput input) : COLOR
{
    return PSMesh(input, false, false, 2);
}

// Techniques.

technique VisualizeFalseFilterFalseFilterSizeFilter2x2
{
    pass
    {
        VertexShader = compile vs_4_0 VSMesh();
        PixelShader = compile ps_4_0 PSMeshVisualizeFalseFilterFalseFilterSizeFilter2x2();
    }
}