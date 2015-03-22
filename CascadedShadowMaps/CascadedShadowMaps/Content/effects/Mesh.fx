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

float Bias;
float OffsetScale;

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

float SampleShadowMapOptimizedPCF(float3 shadowPos, 
    float3 shadowPosDX, float3 shadowPosDY,
    uint cascadeIdx, uint filterSize)
{
    float2 shadowMapSize;
    ShadowMap.GetDimensions(shadowMapSize.x, shadowMapSize.y);

    // Shadow maps are packed into a single, "wide", texture.
    shadowMapSize.x /= NumCascades;

    float lightDepth = shadowPos.z;

    const float bias = Bias;

    lightDepth -= bias;

    float2 uv = shadowPos.xy * shadowMapSize; // 1 unit - 1 texel

    float2 shadowMapSizeInv = 1.0 / shadowMapSize;

    float2 baseUv;
    baseUv.x = floor(uv.x + 0.5);
    baseUv.y = floor(uv.y + 0.5);

    float s = (uv.x + 0.5 - baseUv.x);
    float t = (uv.y + 0.5 - baseUv.y);

    baseUv -= float2(0.5, 0.5);
    baseUv *= shadowMapSizeInv;

    float sum = 0;

    if (filterSize == 2)
    {
        return ShadowMap.SampleCmpLevelZero(ShadowSampler, shadowPos.xy, lightDepth);
    }
    else
    {
        // TODO
        return 0.5f;
    }
}

float3 SampleShadowCascade(
    float3 shadowPosition, 
    float3 shadowPosDX, float3 shadowPosDY,
    uint cascadeIdx, uint2 screenPos,
    bool visualizeCascades,
    uint filterSize)
{
    shadowPosition += CascadeOffsets[cascadeIdx].xyz;
    shadowPosition *= CascadeScales[cascadeIdx].xyz;

    shadowPosDX *= CascadeScales[cascadeIdx].xyz;
    shadowPosDY *= CascadeScales[cascadeIdx].xyz;

    float3 cascadeColor = float3(1.0f, 1.0f, 1.0f);

    if (visualizeCascades)
    {
        const float3 CascadeColors[NumCascades] =
        {
            float3(1.0f, 0.0f, 0.0f),
            float3(0.0f, 1.0f, 0.0f),
            float3(0.0f, 0.0f, 1.0f),
            float3(1.0f, 1.0f, 0.0f)
        };

        cascadeColor = CascadeColors[cascadeIdx];
    }

    // TODO: Other shadow map modes.

    float shadow = SampleShadowMapOptimizedPCF(shadowPosition, shadowPosDX, shadowPosDY, cascadeIdx, filterSize);

    return shadow * cascadeColor;
}

float3 GetShadowPosOffset(float nDotL, float3 normal)
{
    float2 shadowMapSize;
    ShadowMap.GetDimensions(shadowMapSize.x, shadowMapSize.y);
    float texelSize = 2.0f / shadowMapSize.x;
    float nmlOffsetScale = saturate(1.0f - nDotL);
    return texelSize * OffsetScale * nmlOffsetScale * normal;
}

float3 ShadowVisibility(
    float3 positionWS, float depthVS, float nDotL, 
    float3 normal, uint2 screenPos, 
    bool filterAcrossCascades,
    bool visualizeCascades,
    uint filterSize)
{
    float3 shadowVisibility = 1.0f;
    uint cascadeIdx = 0;

    // Figure out which cascade to sample from.
    [unroll]
    for (uint i = 0; i < NumCascades - 1; ++i)
    {
        [flatten]
        if (depthVS > CascadeSplits[i])
            cascadeIdx = i + 1;
    }

    // Apply offset
    float3 offset = GetShadowPosOffset(nDotL, normal) / abs(CascadeScales[cascadeIdx].z);

    // Project into shadow space
    float3 samplePos = positionWS + offset;
    float3 shadowPosition = mul(float4(samplePos, 1.0f), ShadowMatrix).xyz;
    float3 shadowPosDX = ddx_fine(shadowPosition);
    float3 shadowPosDY = ddy_fine(shadowPosition);

    shadowVisibility = SampleShadowCascade(shadowPosition, 
        shadowPosDX, shadowPosDY, cascadeIdx, screenPos,
        visualizeCascades, filterSize);

    if (filterAcrossCascades)
    {
        // Sample the next cascade, and blend between the two results to
        // smooth the transition
        const float BlendThreshold = 0.1f;
        float nextSplit = CascadeSplits[cascadeIdx];
        float splitSize = cascadeIdx == 0 ? nextSplit : nextSplit - CascadeSplits[cascadeIdx - 1];
        float splitDist = (nextSplit - depthVS) / splitSize;

        [branch]
        if (splitDist <= BlendThreshold && cascadeIdx != NumCascades - 1)
        {
            float3 nextSplitVisibility = SampleShadowCascade(shadowPosition,
                shadowPosDX, shadowPosDY, cascadeIdx + 1, screenPos,
                visualizeCascades, filterSize);
            float lerpAmt = smoothstep(0.0f, BlendThreshold, splitDist);
            shadowVisibility = lerp(nextSplitVisibility, shadowVisibility, lerpAmt);
        }
    }

    return shadowVisibility;
}

float4 PSMesh(PSInput input,
    bool visualizeCascades, bool filterAcrossCascades, 
    uint filterSize)
{
    // Normalize after interpolation.
    float3 normalWS = normalize(input.NormalWS);

    // Convert color to grayscale, just beacuse it looks nicer.
    float diffuseValue = 0.299 * DiffuseColor.r + 0.587 * DiffuseColor.g + 0.114 * DiffuseColor.b;
    float3 diffuseAlbedo = float3(diffuseValue, diffuseValue, diffuseValue);

    float nDotL = saturate(dot(normalWS, LightDirection));
    uint2 screenPos = uint2(input.PositionSS.xy);
    float3 shadowVisibility = ShadowVisibility(
        input.PositionWS, input.DepthVS, nDotL, normalWS, screenPos, 
        filterAcrossCascades, visualizeCascades, filterSize);

    float3 lighting = 0.0f;

    // Add the directional light.
    lighting += nDotL * LightColor * diffuseAlbedo * (1.0f / 3.14159f) * shadowVisibility;

    // Ambient light.
    lighting += float3(0.2f, 0.2f, 0.2f) * 1.0f * diffuseAlbedo;

    return float4(max(lighting, 0.0001f), 1);
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