using System;
using Microsoft.Xna.Framework;

namespace ShadowsSample.Util
{
    public static class Vector4Utility
    {
        public static Vector4 Round(Vector4 value)
        {
            return new Vector4(
                (float) Math.Round(value.X),
                (float) Math.Round(value.Y),
                (float) Math.Round(value.Z),
                (float) Math.Round(value.W));
        }
    }
}