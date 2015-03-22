using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using ShadowsSample.Cameras;
using ShadowsSample.Components;

namespace ShadowsSample
{
    public class ShadowsGame : Game
    {
        private readonly GraphicsDeviceManager graphics;
        private SpriteBatch _spriteBatch;

        private FirstPersonCamera _camera;
        private Model _model;
        private Matrix[] _modelTransforms;

        private GameSettingsComponent _gameSettings;

        private MeshRenderer _meshRenderer;

        public ShadowsGame()
            : base()
        {
            graphics = new GraphicsDeviceManager(this);
            graphics.PreferredBackBufferWidth = 1280;
            graphics.PreferredBackBufferHeight = 800;

            //graphics.SynchronizeWithVerticalRetrace = false;
            //IsFixedTimeStep = false;

            Content.RootDirectory = "Content";
        }

        protected override void Initialize()
        {
            _camera = new FirstPersonCamera(MathHelper.PiOver4 * 0.75f,
                Window.ClientBounds.Width / (float) Window.ClientBounds.Height,
                0.25f, 250.0f);

            _camera.Position = new Vector3(20.0f, 5.0f, 65.0f);
            _camera.YRotation = MathHelper.PiOver4;
            _camera.XRotation = 0;

            Mouse.SetPosition(Window.ClientBounds.Width / 2, Window.ClientBounds.Height / 2);

            Components.Add(new FramesPerSecondComponent(this));
            Components.Add(_gameSettings = new GameSettingsComponent(this));

            base.Initialize();
        }

        /// <summary>
        /// LoadContent will be called once per game and is the place to load
        /// all of your content.
        /// </summary>
        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);

            _model = Content.Load<Model>("models/village_house_obj");

            _modelTransforms = new Matrix[_model.Bones.Count];
            _model.CopyAbsoluteBoneTransformsTo(_modelTransforms);

            _meshRenderer = new MeshRenderer(
                GraphicsDevice, _gameSettings,
                Content, _model);
        }

        /// <summary>
        /// UnloadContent will be called once per game and is the place to unload
        /// all content.
        /// </summary>
        protected override void UnloadContent()
        {
            
        }

        /// <summary>
        /// Allows the game to run logic such as updating the world,
        /// checking for collisions, gathering input, and playing audio.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            base.Update(gameTime);

            // Apply keyboard input.

            var keyboardState = Keyboard.GetState();

            var deltaMilliseconds = (float) gameTime.ElapsedGameTime.TotalMilliseconds;
            float moveSpeed = 0.025f * deltaMilliseconds;

            if (keyboardState.IsKeyDown(Keys.LeftShift))
                moveSpeed *= 0.25f;

            var cameraPosition = _camera.Position;
            if (keyboardState.IsKeyDown(Keys.W))
                cameraPosition += _camera.Forward * moveSpeed;
            else if (keyboardState.IsKeyDown(Keys.S))
                cameraPosition += _camera.Backward * moveSpeed;
            if (keyboardState.IsKeyDown(Keys.A))
                cameraPosition += _camera.Left * moveSpeed;
            else if (keyboardState.IsKeyDown(Keys.D))
                cameraPosition += _camera.Right * moveSpeed;
            if (keyboardState.IsKeyDown(Keys.Q))
                cameraPosition += _camera.Up * moveSpeed;
            else if (keyboardState.IsKeyDown(Keys.E))
                cameraPosition += _camera.Down * moveSpeed;

            _camera.Position = cameraPosition;

            // Apply mouse input.

            var mouseState = Mouse.GetState();
            float rotationSpeed = 0.0003f * deltaMilliseconds;
            if (mouseState.RightButton == ButtonState.Pressed)
            {
                var xRot = _camera.XRotation;
                var yRot = _camera.YRotation;
                var deltaX = ((Window.ClientBounds.Height / 2) - mouseState.Y) * rotationSpeed;
                var deltaY = ((Window.ClientBounds.Width / 2) - mouseState.X) * rotationSpeed;
                xRot += deltaX;
                yRot += deltaY;
                _camera.XRotation = xRot;
                _camera.YRotation = yRot;
            }

            Mouse.SetPosition(Window.ClientBounds.Width / 2, Window.ClientBounds.Height / 2);

            // Animate light.

            if (_gameSettings.AnimateLight)
            {
                var rotationY = deltaMilliseconds * 0.00025f;
                var rotation = Quaternion.CreateFromAxisAngle(Vector3.UnitY, rotationY);
                var lightDirection = _gameSettings.LightDirection;
                lightDirection = Vector3.Transform(lightDirection, rotation);
                _gameSettings.LightDirection = lightDirection;
            }
        }

        /// <summary>
        /// This is called when the game should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            _meshRenderer.RenderShadowMap(GraphicsDevice, _camera, Matrix.Identity);

            GraphicsDevice.SetRenderTarget(null);
            GraphicsDevice.Clear(Color.CornflowerBlue);

            _meshRenderer.Render(GraphicsDevice, _camera, Matrix.Identity);

            _spriteBatch.Begin();
            _spriteBatch.Draw(_meshRenderer.ShadowMap,
                new Rectangle(Window.ClientBounds.Width - 10 - 400, 10, 400, 100),
                Color.White);
            _spriteBatch.End();

            base.Draw(gameTime);
        }
    }
}
