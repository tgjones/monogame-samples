using Microsoft.Xna.Framework.Graphics;

namespace ShadowsSample.Util
{
    public static class SamplerStateUtility
    {
        public static readonly SamplerState ShadowMap = new SamplerState
        {
            AddressU = TextureAddressMode.Clamp,
            AddressV = TextureAddressMode.Clamp,
            AddressW = TextureAddressMode.Clamp,
            Filter = TextureFilter.Linear,
            ComparisonFunction = CompareFunction.LessEqual,
            FilterMode = TextureFilterMode.Comparison
        };
    }
}
