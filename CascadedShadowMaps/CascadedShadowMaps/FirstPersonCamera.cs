using System;
using Microsoft.Xna.Framework;

namespace ShadowsSample
{
    public class FirstPersonCamera
    {
        private readonly Matrix _projection;
        private Matrix _world, _view, _viewProjection;
        private Vector3 _position;
        private float _xRotation, _yRotation;
        private readonly float _nearZ, _farZ;

        public Matrix View
        {
            get { return _view; }
        }

        public Matrix Projection
        {
            get { return _projection; }
        }

        public Vector3 Position
        {
            get { return _position; }
            set
            {
                _position = value;
                _world.Translation = value;
                OnWorldMatrixChanged();
            }
        }

        public Vector3 Up
        {
            get { return _world.Up; }
        }

        public Vector3 Down
        {
            get { return _world.Down; }
        }

        public Vector3 Left
        {
            get { return _world.Left; }
        }

        public Vector3 Right
        {
            get { return _world.Right; }
        }

        public Vector3 Forward
        {
            get { return _world.Forward; }
        }

        public Vector3 Backward
        {
            get { return _world.Backward; }
        }

        public float XRotation
        {
            get { return _xRotation; }
            set
            {
                _xRotation = MathHelper.Clamp(value, -MathHelper.PiOver2, MathHelper.PiOver2);
                SetOrientation(Quaternion.CreateFromYawPitchRoll(_yRotation, _xRotation, 0));
            }
        }

        public float YRotation
        {
            get { return _yRotation; }
            set
            {
                _yRotation = value;
                SetOrientation(Quaternion.CreateFromYawPitchRoll(_yRotation, _xRotation, 0));
            }
        }

        public FirstPersonCamera(float fieldOfView, float aspectRatio, float nearZ, float farZ)
        {
            _projection = Matrix.CreatePerspectiveFieldOfView(fieldOfView, aspectRatio, nearZ, farZ);

            _nearZ = nearZ;
            _farZ = farZ;

            _world = Matrix.Identity;
            _view = Matrix.Identity;
        }

        public void SetLookAt(Vector3 cameraPosition, Vector3 cameraTarget, Vector3 up)
        {
            _view = Matrix.CreateLookAt(cameraPosition, cameraTarget, up);
            _world = Matrix.Invert(_view);
            _position = cameraPosition;
            OnWorldMatrixChanged();
        }

        private void SetOrientation(Quaternion orientation)
        {
            _world = Matrix.CreateFromQuaternion(orientation);
            _world.Translation = _position;
            OnWorldMatrixChanged();
        }

        private void OnWorldMatrixChanged()
        {
            _view = Matrix.Invert(_world);
            _viewProjection = _view * _projection;
        }
    }
}