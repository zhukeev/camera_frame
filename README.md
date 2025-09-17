# camera_frame — drop-in add-ons for `camera` (iOS + Android)

**What is this?**  
A set of small, practical extensions on top of the official `camera` plugin, kept in lockstep with upstream and **fully compatible** with it. If you don’t call the new APIs, behavior is identical to `camera`.

---

## What’s added (differences only)

### 1) Instant preview snapshot to JPEG (no camera pause)
- **API:** `capturePreviewFrameJpeg(String outputPath, {int rotationDegrees = 0, int quality = 92})`
- Captures the **current preview frame** and saves it to a file while preview/recording continues.
- `rotationDegrees`: `0 | 90 | 180 | 270` — **pixels are rotated**, no EXIF orientation.
- `quality`: `0–100` (default `92`).

**Why it helps**
- Fast UI snapshots without the overhead of `takePicture`.
- Deterministic orientation (no EXIF surprises).
- Simple “stream frame → JPEG file” pipeline for logging/ML.

### 2) iOS internals: low-overhead last-frame cache
- `LastFrameStore` keeps the **latest frame** tightly packed for fast export:
  - NV12: two planes (Y + interleaved UV), `bytesPerRow = width`.
  - 32BGRA: one plane, `bytesPerRow = width * 4`.
- Minimal copying; CI/CG pipeline for JPEG; **no EXIF** is written.

### 3) Android implementation
- Compatible `capturePreviewFrameJpeg` based on `ImageReader`.
- Upstream code style preserved to keep diffs clean.

> **Note — `frameFps` (Android & iOS):** optional global limit that controls  
> (a) how often the internal **last-frame cache is refreshed**, and  
> (b) how often frames are **delivered to `startListenFrames`**.  
> It **does not** change the live camera preview or video recording FPS.  
> Configure it before starting preview/streaming:
> - **Android:** `VideoCaptureSettings.frameFps` (`Integer?`, `null` = unlimited).
> - **iOS:** `mediaSettings.frameFps` (`NSNumber?`, `nil` = internal conservative default).

---

## Installation

```yaml
dependencies:
  camera_frame: ^<your-version>
```

This package is designed to be a **drop-in** alongside `camera`; existing code keeps working.

---

## Usage (new API only)

```dart
// Save the current preview frame as a JPEG.
// Rotates pixels (no EXIF), does not pause preview or recording.
final String saved = await cameraController.capturePreviewFrameJpeg(
  '/path/to/frame.jpg',
  rotationDegrees: 90, // optional
  quality: 85,         // optional
);
```

> Optional: set `frameFps` before opening/starting the camera to limit how often the **last-frame cache** refreshes and how often frames are **delivered to `startListenFrames`**.  
> Android: via `VideoCaptureSettings.frameFps`. iOS: via `mediaSettings.frameFps`.

---

## Added APIs (iOS & Android)

### `Future<CameraImageData> capturePreviewFrame()`
Captures **one** preview frame and returns it in-memory as `CameraImageData` (YUV/BGRA + dimensions/planes).  
Use when you need the pixels immediately in Dart (e.g. ML/inference) without touching the filesystem.

---

### `Future<XFile> capturePreviewFrameJpeg(String outputPath, [int rotation = 0, int quality = 100])`
Captures the **current preview frame** and saves it as a **JPEG** to `outputPath`.  
- `rotation` — pixel rotation in degrees: `0 | 90 | 180 | 270` (no EXIF tags).  
- `quality` — JPEG quality `0…100` (default `100`).  
Returns an `XFile` pointing to the saved JPEG. Preview/recording continue uninterrupted.

---

### `Future<XFile> saveAsJpeg(CameraImageData imageData, String outputPath, int rotation, int quality)`
Converts an existing `CameraImageData` (e.g. from `capturePreviewFrame` or your stream) to a **JPEG** on disk.  
- Applies pixel rotation (no EXIF).  
- Returns an `XFile` to the saved file.

---

### `Future<void> startListenFrames({ void Function(CameraImageData image)? frameCallback })`
Starts **preview frame streaming** to Dart.  
- If `frameCallback` is provided, it’s invoked for each frame (`CameraImageData`).  
- Designed for lightweight per-frame consumers (analytics/ML). Runs alongside preview/recording.  
- **Respects the configured `frameFps`** (limits delivery rate if set).

### `Future<void> stopListenFrames()`
Stops the stream started by `startListenFrames`.

---

## Notes

- JPEGs are written **without EXIF**; orientation is applied to pixels.
- Supported pixel formats:
  - iOS: `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange` (NV12), `kCVPixelFormatType_32BGRA`.
  - Android: standard `ImageReader` YUV/BGRA sources.
- Snapshot and streaming APIs do **not** pause preview or video recording.

---

## Performance & thermals

- Configure `frameFps` (e.g., 10–20) to reduce CPU/GPU load and device heat.  
- iOS uses `alwaysDiscardsLateVideoFrames = true` on the video data output.  
- Internally we avoid duplicate copies; the “last frame” cache is tightly packed (NV12/BGRA).  
- On Android we use `acquireLatestImage()` to avoid back-pressure buildup.

---

## Compatibility

- Flutter/Dart: same minimums as the upstream `camera` in this release.
- iOS 11+ (AVFoundation).
- Android: same min/compile SDK as upstream `camera_android`.

---

## Upstream policy

The codebase is regularly synced with the official `flutter/packages` camera implementations; changes are additive and documented in `CHANGELOG.md`.

---

## Acknowledgements

Based on the upstream `camera_android` and `camera_avfoundation` implementations from the Flutter team.
