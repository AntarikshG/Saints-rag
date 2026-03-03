# Quote of the Day Video Export Feature

## Overview
The Quote of the Day page now supports exporting quotes as 10-second MP4 video files. The video combines a screenshot of the quote card with background audio.

## How It Works

1. **Capture Screenshot**: The app captures a high-resolution screenshot of the quote card (at 3x pixel ratio)
2. **Load Audio**: 
   - First tries to load `assets/audio/quote_background.mp3` from the app's assets
   - If no audio file is found, it creates 10 seconds of silent audio automatically
3. **Create Video**: Uses FFmpeg to combine the image and audio into a 10-second MP4 video (1080x1920 resolution)
4. **Share**: Opens the system share dialog to share the video

## Adding Background Audio

To add background audio to your quote videos:

1. Prepare a 10-second audio file in MP3 format
2. Name it `quote_background.mp3`
3. Place it in the `assets/audio/` directory
4. The audio will be automatically used when exporting videos

### Recommended Audio Specifications
- **Format**: MP3, M4A, or WAV
- **Duration**: 10 seconds (exactly)
- **Sample Rate**: 44.1 kHz
- **Bit Rate**: 128 kbps or higher
- **Content**: Calm, meditative, or inspirational background music

## Using the Feature

1. Open the Quote of the Day page from the main menu
2. Tap the purple "Export Video" button at the bottom right
3. Wait for the video to be created (takes a few seconds)
4. Share the video using the system share dialog

## Technical Details

### Dependencies
- `ffmpeg_kit_flutter: ^6.0.3` - For video creation and audio/image processing
- `screenshot: ^3.0.0` - For capturing the quote card as an image
- `share_plus: ^10.0.2` - For sharing the generated video
- `path_provider: ^2.1.4` - For accessing temporary storage

### Video Specifications
- **Resolution**: 1080x1920 (vertical/portrait)
- **Duration**: 10 seconds
- **Video Codec**: H.264 (libx264)
- **Audio Codec**: AAC (192 kbps)
- **Pixel Format**: yuv420p (for maximum compatibility)

### FFmpeg Command Used
```bash
-loop 1 -i [image] -i [audio] -c:v libx264 -tune stillimage -c:a aac -b:a 192k -pix_fmt yuv420p -shortest -t 10 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=white" [output]
```

## Troubleshooting

### Video creation fails
- Make sure the app has storage permissions
- Check that there's enough free space on the device
- Verify FFmpeg is properly initialized

### No audio in video
- If you haven't added `quote_background.mp3`, the video will have silent audio (this is normal)
- To add audio, follow the steps in "Adding Background Audio" section above

### Video won't share
- Check that the app has permission to access storage
- Try exporting again if the first attempt fails
- Some devices may take longer to process the video

## Implementation Notes

The implementation includes:
- Automatic fallback to silent audio if no audio file is provided
- Loading dialog while video is being created
- Success/error notifications
- Automatic cleanup of temporary files after 30 seconds
- High-quality screenshot capture at 3x resolution
- Proper error handling and user feedback
