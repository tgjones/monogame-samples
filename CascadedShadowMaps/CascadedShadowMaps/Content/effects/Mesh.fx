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

Texture2DArray ShadowMap : register(t0);

SamplerComparisonState ShadowSampler : register(s0);

// Structures.

struct VSInput
{
    float3 PositionOS : SV_POSITION;
    float3 NormalOS   : NORMAL;
    float3 Uv         : TEXCOORD0;
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

float SampleShadowMap(
    float2 baseUv, float u, float v, float2 shadowMapSizeInv,
    uint cascadeIdx, float depth)
{
    float2 uv = baseUv + float2(u, v) * shadowMapSizeInv;
    float z = depth;

    return ShadowMap.SampleCmpLevelZero(ShadowSampler, float3(uv, cascadeIdx), z);
}

float SampleShadowMapOptimizedPCF(float3 shadowPos,
    float3 shadowPosDX, float3 shadowPosDY,
    uint cascadeIdx, uint filterSize)
{
    float2 shadowMapSize;
    float numSlices;
    ShadowMap.GetDimensions(shadowMapSize.x, shadowMapSize.y, numSlices);

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
        return ShadowMap.SampleCmpLevelZero(ShadowSampler, float3(shadowPos.xy, cascadeIdx), lightDepth);
    }
    else if (filterSize == 3)
    {
        float uw0 = (3 - 2 * s);
        float uw1 = (1 + 2 * s);

        float u0 = (2 - s) / uw0 - 1;
        float u1 = s / uw1 + 1;

        float vw0 = (3 - 2 * t);
        float vw1 = (1 + 2 * t);

        float v0 = (2 - t) / vw0 - 1;
        float v1 = t / vw1 + 1;

        sum += uw0 * vw0 * SampleShadowMap(baseUv, u0, v0, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw1 * vw0 * SampleShadowMap(baseUv, u1, v0, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw0 * vw1 * SampleShadowMap(baseUv, u0, v1, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw1 * vw1 * SampleShadowMap(baseUv, u1, v1, shadowMapSizeInv, cascadeIdx, lightDepth);

        return sum * 1.0f / 16;
    }
    else if (filterSize == 5)
    {
        float uw0 = (4 - 3 * s);
        float uw1 = 7;
        float uw2 = (1 + 3 * s);

        float u0 = (3 - 2 * s) / uw0 - 2;
        float u1 = (3 + s) / uw1;
        float u2 = s / uw2 + 2;

        float vw0 = (4 - 3 * t);
        float vw1 = 7;
        float vw2 = (1 + 3 * t);

        float v0 = (3 - 2 * t) / vw0 - 2;
        float v1 = (3 + t) / vw1;
        float v2 = t / vw2 + 2;

        sum += uw0 * vw0 * SampleShadowMap(baseUv, u0, v0, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw1 * vw0 * SampleShadowMap(baseUv, u1, v0, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw2 * vw0 * SampleShadowMap(baseUv, u2, v0, shadowMapSizeInv, cascadeIdx, lightDepth);

        sum += uw0 * vw1 * SampleShadowMap(baseUv, u0, v1, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw1 * vw1 * SampleShadowMap(baseUv, u1, v1, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw2 * vw1 * SampleShadowMap(baseUv, u2, v1, shadowMapSizeInv, cascadeIdx, lightDepth);

        sum += uw0 * vw2 * SampleShadowMap(baseUv, u0, v2, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw1 * vw2 * SampleShadowMap(baseUv, u1, v2, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw2 * vw2 * SampleShadowMap(baseUv, u2, v2, shadowMapSizeInv, cascadeIdx, lightDepth);

        return sum * 1.0f / 144;
    }
    else // filterSize == 7
    {
        float uw0 = (5 * s - 6);
        float uw1 = (11 * s - 28);
        float uw2 = -(11 * s + 17);
        float uw3 = -(5 * s + 1);

        float u0 = (4 * s - 5) / uw0 - 3;
        float u1 = (4 * s - 16) / uw1 - 1;
        float u2 = -(7 * s + 5) / uw2 + 1;
        float u3 = -s / uw3 + 3;

        float vw0 = (5 * t - 6);
        float vw1 = (11 * t - 28);
        float vw2 = -(11 * t + 17);
        float vw3 = -(5 * t + 1);

        float v0 = (4 * t - 5) / vw0 - 3;
        float v1 = (4 * t - 16) / vw1 - 1;
        float v2 = -(7 * t + 5) / vw2 + 1;
        float v3 = -t / vw3 + 3;

        sum += uw0 * vw0 * SampleShadowMap(baseUv, u0, v0, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw1 * vw0 * SampleShadowMap(baseUv, u1, v0, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw2 * vw0 * SampleShadowMap(baseUv, u2, v0, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw3 * vw0 * SampleShadowMap(baseUv, u3, v0, shadowMapSizeInv, cascadeIdx, lightDepth);

        sum += uw0 * vw1 * SampleShadowMap(baseUv, u0, v1, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw1 * vw1 * SampleShadowMap(baseUv, u1, v1, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw2 * vw1 * SampleShadowMap(baseUv, u2, v1, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw3 * vw1 * SampleShadowMap(baseUv, u3, v1, shadowMapSizeInv, cascadeIdx, lightDepth);

        sum += uw0 * vw2 * SampleShadowMap(baseUv, u0, v2, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw1 * vw2 * SampleShadowMap(baseUv, u1, v2, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw2 * vw2 * SampleShadowMap(baseUv, u2, v2, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw3 * vw2 * SampleShadowMap(baseUv, u3, v2, shadowMapSizeInv, cascadeIdx, lightDepth);

        sum += uw0 * vw3 * SampleShadowMap(baseUv, u0, v3, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw1 * vw3 * SampleShadowMap(baseUv, u1, v3, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw2 * vw3 * SampleShadowMap(baseUv, u2, v3, shadowMapSizeInv, cascadeIdx, lightDepth);
        sum += uw3 * vw3 * SampleShadowMap(baseUv, u3, v3, shadowMapSizeInv, cascadeIdx, lightDepth);

        return sum * 1.0f / 2704;
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
    float numSlices;
    ShadowMap.GetDimensions(shadowMapSize.x, shadowMapSize.y, numSlices);

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

float4 PSMeshVisualizeTrueFilterFalseFilterSizeFilter2x2(PSInput input) : COLOR
{
    return PSMesh(input, true, false, 2);
}

float4 PSMeshVisualizeFalseFilterFalseFilterSizeFilter3x3(PSInput input) : COLOR
{
    return PSMesh(input, false, false, 3);
}

float4 PSMeshVisualizeTrueFilterFalseFilterSizeFilter3x3(PSInput input) : COLOR
{
    return PSMesh(input, true, false, 3);
}

float4 PSMeshVisualizeFalseFilterFalseFilterSizeFilter5x5(PSInput input) : COLOR
{
    return PSMesh(input, false, false, 5);
}

float4 PSMeshVisualizeTrueFilterFalseFilterSizeFilter5x5(PSInput input) : COLOR
{
    return PSMesh(input, true, false, 5);
}

float4 PSMeshVisualizeFalseFilterFalseFilterSizeFilter7x7(PSInput input) : COLOR
{
    return PSMesh(input, false, false, 7);
}

float4 PSMeshVisualizeTrueFilterFalseFilterSizeFilter7x7(PSInput input) : COLOR
{
    return PSMesh(input, true, false, 7);
}

float4 PSMeshVisualizeFalseFilterTrueFilterSizeFilter2x2(PSInput input) : COLOR
{
    return PSMesh(input, false, true, 2);
}

float4 PSMeshVisualizeTrueFilterTrueFilterSizeFilter2x2(PSInput input) : COLOR
{
    return PSMesh(input, true, true, 2);
}

float4 PSMeshVisualizeFalseFilterTrueFilterSizeFilter3x3(PSInput input) : COLOR
{
    return PSMesh(input, false, true, 3);
}

float4 PSMeshVisualizeTrueFilterTrueFilterSizeFilter3x3(PSInput input) : COLOR
{
    return PSMesh(input, true, true, 3);
}

float4 PSMeshVisualizeFalseFilterTrueFilterSizeFilter5x5(PSInput input) : COLOR
{
    return PSMesh(input, false, true, 5);
}

float4 PSMeshVisualizeTrueFilterTrueFilterSizeFilter5x5(PSInput input) : COLOR
{
    return PSMesh(input, true, true, 5);
}

float4 PSMeshVisualizeFalseFilterTrueFilterSizeFilter7x7(PSInput input) : COLOR
{
    return PSMesh(input, false, true, 7);
}

float4 PSMeshVisualizeTrueFilterTrueFilterSizeFilter7x7(PSInput input) : COLOR
{
    return PSMesh(input, true, true, 7);
}

// Techniques.

#define VS_PROFILE vs_5_0
#define PS_PROFILE ps_5_0

technique VisualizeFalseFilterFalseFilterSizeFilter2x2
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeFalseFilterFalseFilterSizeFilter2x2();
    }
}

technique VisualizeTrueFilterFalseFilterSizeFilter2x2
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeTrueFilterFalseFilterSizeFilter2x2();
    }
}

technique VisualizeFalseFilterFalseFilterSizeFilter3x3
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeFalseFilterFalseFilterSizeFilter3x3();
    }
}

technique VisualizeTrueFilterFalseFilterSizeFilter3x3
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeTrueFilterFalseFilterSizeFilter3x3();
    }
}

technique VisualizeFalseFilterFalseFilterSizeFilter5x5
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeFalseFilterFalseFilterSizeFilter5x5();
    }
}

technique VisualizeTrueFilterFalseFilterSizeFilter5x5
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeTrueFilterFalseFilterSizeFilter5x5();
    }
}

technique VisualizeFalseFilterFalseFilterSizeFilter7x7
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeFalseFilterFalseFilterSizeFilter7x7();
    }
}

technique VisualizeTrueFilterFalseFilterSizeFilter7x7
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeTrueFilterFalseFilterSizeFilter7x7();
    }
}

technique VisualizeFalseFilterTrueFilterSizeFilter2x2
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeFalseFilterTrueFilterSizeFilter2x2();
    }
}

technique VisualizeTrueFilterTrueFilterSizeFilter2x2
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeTrueFilterTrueFilterSizeFilter2x2();
    }
}

technique VisualizeFalseFilterTrueFilterSizeFilter3x3
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeFalseFilterTrueFilterSizeFilter3x3();
    }
}

technique VisualizeTrueFilterTrueFilterSizeFilter3x3
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeTrueFilterTrueFilterSizeFilter3x3();
    }
}

technique VisualizeFalseFilterTrueFilterSizeFilter5x5
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeFalseFilterTrueFilterSizeFilter5x5();
    }
}

technique VisualizeTrueFilterTrueFilterSizeFilter5x5
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeTrueFilterTrueFilterSizeFilter5x5();
    }
}

technique VisualizeFalseFilterTrueFilterSizeFilter7x7
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeFalseFilterTrueFilterSizeFilter7x7();
    }
}

technique VisualizeTrueFilterTrueFilterSizeFilter7x7
{
    pass
    {
        VertexShader = compile VS_PROFILE VSMesh();
        PixelShader = compile PS_PROFILE PSMeshVisualizeTrueFilterTrueFilterSizeFilter7x7();
    }
}
