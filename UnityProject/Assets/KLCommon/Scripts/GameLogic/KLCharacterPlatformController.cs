using UnityEngine;
using System.Collections;

[RequireComponent(typeof(CharacterController))]
public class KLCharacterPlatformController : MonoBehaviour
{

    Transform activePlatform;
    Vector3 activeLocalPlatformPoint;
    Vector3 activeGlobalPlatformPoint;
    Quaternion activeGlobalPlatformRotation;
    Quaternion activeLocalPlatformRotation;
    CharacterController characterController;

    // Use this for initializa2tion
    void Start()
    {
        this.characterController = this.GetComponent<CharacterController>();
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        // Moving platform support
        if (activePlatform != null)
        {
            var newGlobalPlatformPoint = activePlatform.TransformPoint(activeLocalPlatformPoint);
            var moveDistance = (newGlobalPlatformPoint - activeGlobalPlatformPoint);
            if (moveDistance != Vector3.zero)
            {
                //this.transform.Translate(moveDistance);
                this.characterController.Move(moveDistance);
            }

            // If you want to support moving platform rotation as well:
            var newGlobalPlatformRotation = activePlatform.rotation * activeLocalPlatformRotation;
            var rotationDiff = newGlobalPlatformRotation * Quaternion.Inverse(activeGlobalPlatformRotation);

            // Prevent rotation of the local up vector
            rotationDiff = Quaternion.FromToRotation(rotationDiff * transform.up, transform.up) * rotationDiff;

            transform.rotation = rotationDiff * transform.rotation;

            activeGlobalPlatformPoint = transform.position;
            activeLocalPlatformPoint = activePlatform.InverseTransformPoint(transform.position);

            // If you want to support moving platform rotation as well:
            activeGlobalPlatformRotation = transform.rotation;
            activeLocalPlatformRotation = Quaternion.Inverse(activePlatform.rotation) * transform.rotation;
        }
    }

    void OnControllerColliderHit(ControllerColliderHit hitCollider)
    {
        if (activePlatform != hitCollider.collider.transform && hitCollider.collider.tag == "KLMovingPlatform")
        {
            activePlatform = hitCollider.collider.transform;
            
            activeGlobalPlatformPoint = transform.position;
            activeLocalPlatformPoint = activePlatform.InverseTransformPoint(transform.position);

            // If you want to support moving platform rotation as well:
            activeGlobalPlatformRotation = transform.rotation;
            activeLocalPlatformRotation = Quaternion.Inverse(activePlatform.rotation) * transform.rotation;
        }
    }
}
