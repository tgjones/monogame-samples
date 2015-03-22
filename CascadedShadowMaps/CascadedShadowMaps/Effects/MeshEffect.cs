using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using ShadowsSample.Components;

namespace ShadowsSample.Effects
{
    public class MeshEffect
    {
        private readonly Effect _innerEffect;

        private readonly EffectParameter _cameraPosWSParameter;
        private readonly EffectParameter _shadowMatrixParameter;
        private readonly EffectParameter _cascadeSplitsParameter;
        private readonly EffectParameter _cascadeOffsetsParameter;
        private readonly EffectParameter _cascadeScalesParameter;
        private readonly EffectParameter _lightDirectionParameter;
        private readonly EffectParameter _lightColorParameter;
        private readonly EffectParameter _diffuseColorParameter;
        private readonly EffectParameter _worldParameter;
        private readonly EffectParameter _viewProjectionParameter;
        private readonly EffectParameter _shadowMapParameter;

        public bool VisualizeCascades { get; set; }
        public bool FilterAcrossCascades { get; set; }
        public FixedFilterSize FilterSize { get; set; }

        public Vector3 CameraPosWS { get; set; }
        public Matrix ShadowMatrix { get; set; }
        public float[] CascadeSplits { get; private set; }
        public Vector4[] CascadeOffsets { get; private set; }
        public Vector4[] CascadeScales { get; private set; }
        public Vector3 LightDirection { get; set; }
        public Vector3 LightColor { get; set; }
        public Vector3 DiffuseColor { get; set; }
        public Matrix World { get; set; }
        public Matrix ViewProjection { get; set; }
        public Texture2D ShadowMap { get; set; }

        public MeshEffect(GraphicsDevice graphicsDevice, Effect innerEffect) 
        {
            _innerEffect = innerEffect;

            _cameraPosWSParameter = _innerEffect.Parameters["CameraPosWS"];
            _shadowMatrixParameter = _innerEffect.Parameters["ShadowMatrix"];
            _cascadeSplitsParameter = _innerEffect.Parameters["CascadeSplits"];
            _cascadeOffsetsParameter = _innerEffect.Parameters["CascadeOffsets"];
            _cascadeScalesParameter = _innerEffect.Parameters["CascadeScales"];
            _lightDirectionParameter = _innerEffect.Parameters["LightDirection"];
            _lightColorParameter = _innerEffect.Parameters["LightColor"];
            _diffuseColorParameter = _innerEffect.Parameters["DiffuseColor"];
            _worldParameter = _innerEffect.Parameters["World"];
            _viewProjectionParameter = _innerEffect.Parameters["ViewProjection"];
            _shadowMapParameter = _innerEffect.Parameters["ShadowMap"];

            CascadeSplits = new float[MeshRenderer.NumCascades];
            CascadeOffsets = new Vector4[MeshRenderer.NumCascades];
            CascadeScales = new Vector4[MeshRenderer.NumCascades];
        }

        public void Apply()
        {
            var techniqueName = "Visualize" + VisualizeCascades
                                + "Filter" + FilterAcrossCascades
                                + "FilterSize" + FilterSize;
            _innerEffect.CurrentTechnique = _innerEffect.Techniques[techniqueName];

            _cameraPosWSParameter.SetValue(CameraPosWS);
            _shadowMatrixParameter.SetValue(ShadowMatrix);
            _cascadeSplitsParameter.SetValue(new Vector4(CascadeSplits[0], CascadeSplits[1], CascadeSplits[2], CascadeSplits[3]));
            _cascadeOffsetsParameter.SetValue(CascadeOffsets);
            _cascadeScalesParameter.SetValue(CascadeScales);
            _lightDirectionParameter.SetValue(LightDirection);
            _lightColorParameter.SetValue(LightColor);
            _diffuseColorParameter.SetValue(DiffuseColor);
            _worldParameter.SetValue(World);
            _viewProjectionParameter.SetValue(ViewProjection);
            _shadowMapParameter.SetValue(ShadowMap);

            _innerEffect.CurrentTechnique.Passes[0].Apply();
        } 
    }
}