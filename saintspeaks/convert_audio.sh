#!/bin/bash

# Script to convert audio files to the proper format for Quote of the Day videos
# Usage: ./convert_audio.sh input_audio_file.mp3

INPUT_FILE="$1"
OUTPUT_FILE="assets/audio/quote_background.mp3"

# Check if input file is provided
if [ -z "$INPUT_FILE" ]; then
    echo "Usage: ./convert_audio.sh <input_audio_file>"
    echo "Example: ./convert_audio.sh my_music.mp3"
    exit 1
fi

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed"
    echo "Please install ffmpeg:"
    echo "  macOS: brew install ffmpeg"
    echo "  Linux: sudo apt-get install ffmpeg"
    exit 1
fi

# Create assets/audio directory if it doesn't exist
mkdir -p assets/audio

echo "Converting and trimming audio file to 10 seconds..."
ffmpeg -i "$INPUT_FILE" -t 10 -codec:a libmp3lame -b:a 192k -ar 44100 -ac 2 "$OUTPUT_FILE" -y

if [ $? -eq 0 ]; then
    echo "✅ Success! Audio file created at: $OUTPUT_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Run 'flutter pub get' to update assets"
    echo "2. Rebuild your app"
    echo "3. Test the 'Export Video' feature in Quote of the Day"
else
    echo "❌ Error: Failed to convert audio file"
    exit 1
fi
