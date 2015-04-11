using Microsoft.Xna.Framework;

namespace ShadowsSample.Components
{
    public class FramesPerSecondComponent : GuiComponent
    {
        private double _accumulatedTime;
        private int _frames;
        private double _timeLeft;

        private string _fpsString = string.Empty;
        private string _frameTimeString = string.Empty;

        public FramesPerSecondComponent(Game game)
            : base(game, 10, Color.FromNonPremultiplied(0, 0, 0, 150))
        {
            _timeLeft = 1.0;
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
            DrawLabels(new[]
            {
                new LabelData { Name = "Frames per second", Value = _fpsString }, 
                new LabelData { Name = "Frame time", Value = _frameTimeString }
            });
        }
    }
}