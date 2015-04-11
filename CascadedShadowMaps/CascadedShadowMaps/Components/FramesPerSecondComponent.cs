using Microsoft.Xna.Framework;

namespace ShadowsSample.Components
{
    public class FramesPerSecondComponent : DrawableGameComponent
    {
        private double _accumulatedTime;
        private int _frames;
        private double _timeLeft;

        private string _fpsString = string.Empty;
        private string _frameTimeString = string.Empty;

        private IGuiService _guiService;

        public FramesPerSecondComponent(Game game)
            : base(game)
        {
            _timeLeft = 1.0;
        }

        public override void Initialize()
        {
            _guiService = Game.Services.GetService<IGuiService>();
            base.Initialize();
        }

        public override void Update(GameTime gameTime)
        {
            _timeLeft -= gameTime.ElapsedGameTime.TotalSeconds;
            _accumulatedTime += gameTime.ElapsedGameTime.TotalSeconds;
            ++_frames;

            if (_timeLeft <= 0.0)
            {
                var fps = _frames / _accumulatedTime;
                _fpsString = string.Format("{0:F0} FPS", fps);
                _frameTimeString = string.Format("{0:F1} ms", gameTime.ElapsedGameTime.TotalMilliseconds);

                _timeLeft = 1.0;
                _accumulatedTime = 0.0;
                _frames = 0;
            }
        }

        public override void Draw(GameTime gameTime)
        {
            _guiService.DrawLabels(new[]
            {
                new GuiComponent.GuiLabelData { Name = "Frames per second", Value = _fpsString }, 
                new GuiComponent.GuiLabelData { Name = "Frame time", Value = _frameTimeString }
            }, Color.FromNonPremultiplied(0, 0, 100, 150));
        }
    }
}