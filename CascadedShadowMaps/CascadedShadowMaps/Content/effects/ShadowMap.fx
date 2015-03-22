matrix WorldViewProjection;

struct VSOutput
{
    float4 position : SV_Position;
    float2 depth : TEXCOORD0;
};

VSOutput VSShadowMap(float3 position : SV_Position)
{
    VSOutput output;
    output.position = mul(float4(position, 1), WorldViewProjection);
    output.depth = output.position.zw;
    return output;
}

float4 PSShadowMap(VSOutput input) : COLOR
{
    return float4(input.depth.x / input.depth.y, 0, 0, 1);
}

technique ShadowMap
{
    pass
    {
        VertexShader = compile vs_4_0 VSShadowMap();
        PixelShader = compile ps_4_0 PSShadowMap();
    }
}