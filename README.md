## Webtor Self-Hosted (ARM64 / Aarch64)

This is a custom build of Webtor.io Self-Hosted designed specifically for ARM64 architectures.

It is fully compatible with:
```
Oracle Cloud Ampere Instances
Raspberry Pi 4 / 5 (64-bit OS)
Apple Silicon (M1/M2/M3)
```
### Why this fork?

The official Webtor image currently supports only amd64 (Intel/AMD). Attempting to run it on ARM devices results in exec format error or broken video playback due to incompatible FFmpeg binaries.

This build fixes those issues by:
```
Integrating static FFmpeg binaries (via mwader/static-ffmpeg) to ensure full codec support for transcoding on ARM.
Using the correct s6-overlay for aarch64.
Updating core dependencies to Go 1.25+ and Alpine 3.22.
```
### Usage

You can pull the pre-built image directly from Docker Hub:
```
docker pull akhil850/webtor
```
### Quick Start

Important: You must set the DOMAIN variable to your public IP or domain name, otherwise video playback will fail with localhost errors.
```
docker run -d \
  --name webtor \
  --restart=always \
  -p 8080:8080 \
  -p 5432:5432 \
  -v /data:/data \
  -e DOMAIN=http://YOUR_PUBLIC_IP_OR_DOMAIN:8080 \
  akhil850/webtor:latest
```
