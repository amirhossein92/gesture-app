#ifndef CMULTITOUCH_H
#define CMULTITOUCH_H

// Minimal declarations for Apple's private MultitouchSupport.framework.
// This framework exposes raw per-finger positions on the trackpad, which the
// public NSTouch API cannot provide for a global (background) listener.
// Private API => personal use only, not App Store safe.

typedef struct {
    float x;
    float y;
} MTPoint;

typedef struct {
    MTPoint position;
    MTPoint velocity;
} MTVector;

// One tracked finger in a touch frame. Field layout is the well-known
// reverse-engineered shape; we only read `fingerID` and `normalized.position`.
typedef struct {
    int frame;
    double timestamp;
    int pathIndex;
    int state;
    int fingerID;
    int handID;
    MTVector normalized;   // position/velocity in 0..1 (x: left->right, y: bottom->top)
    float zTotal;
    int field9;
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absolute;
    int field14;
    int field15;
    float zDensity;
} MTTouch;

typedef void *MTDeviceRef;

typedef int (*MTContactCallbackFunction)(MTDeviceRef device,
                                         MTTouch *touches,
                                         int numTouches,
                                         double timestamp,
                                         int frame);

MTDeviceRef MTDeviceCreateDefault(void);
void MTRegisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
int MTDeviceStart(MTDeviceRef device, int mode);
void MTDeviceStop(MTDeviceRef device);

#endif /* CMULTITOUCH_H */
