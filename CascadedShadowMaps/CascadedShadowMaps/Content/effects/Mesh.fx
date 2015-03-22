static const uint NumCascades = 4;

// Parameters.

matrix World;
matrix ViewProjection;

float3 CameraPosWS;
matrix ShadowMatrix;
float4 CascadeSplits;
float4 CascadeOffsets[NumCascades];
float4 CascadeScales[NumCascades];

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
    float3 Color      : COLOR;
    float DepthVS     : DEPTHVS;
};

struct PSInput
{
    float4 PositionSS : SV_Position;
    float3 PositionWS : POSITIONWS;
    float3 NormalWS   : NORMALWS;
    float3 Color      : COLOR;
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

    output.Color = input.Color;

    return output;
}

// Pixel shader.

float4 PSMesh(VSOutput input, 
    bool visualizeCascades, bool filterAcrossCascades, 
    int filterSize)
{
    float4 r = ShadowMap.SampleCmpLevelZero(ShadowSampler, float2(0, 0), 0.0) * 0.0001;
    return float4(DiffuseColor, 1) + r;
}

float4 PSMeshVisualizeFalseFilterFalseFilterSizeFilter2x2(VSOutput input) : COLOR
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