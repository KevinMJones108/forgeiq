# ForgeIQ Deploy to Device Checklist

## Prerequisites
- [x] Xcode 26.4 installed (supports iOS 26.x)
- [x] iPhone connected via USB
- [ ] Developer Mode enabled on iPhone (Settings → Privacy & Security)

## Build Command
```bash
cd ~/qbo/forgeiq
xcodebuild -project ForgeIQ.xcodeproj -scheme ForgeIQ \
  -destination 'platform=iOS,id=00008150-001628DC0A02401C' \
  -configuration Debug clean build
```

## After Successful Build
App auto-installs to iPhone. Launch from home screen.

## Battle Test Sequence
1. **VoiceCore:** Record 30-second test → verify .m4a saves
2. **Transcription:** Apple STT → verify .txt appears
3. **AI Summary:** Verify call summary + blown past detection
4. **Pipedrive:** Verify auto-log creates activity

## Known Device Info
- UDID: 00008150-001628DC0A02401C
- iOS: 26.5
- Name: iPhone
