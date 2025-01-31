#!/bin/bash
# transcription stream transcription and diarization example script - 12/2023
## moved to diarize_parallel.py and added ollama gpt endpoint api and summary option

## 1/2024
## removed date from folder names
## migrated the llm summary being called from this script to ts-control.sh. This lets
##  the next transcription kickoff without waiting for the summary to finish. Summaries
##  will be automatically created for transcriptions missing them.

# Define the root directory and subdirectories
root_dir="/transcriptionstream/incoming/"
transcribed_dir="/transcriptionstream/transcribed/"
sub_dirs=("diarize")

# Define supported audio file extensions
audio_extensions=("wav" "mp3" "flac" "ogg")

# Define supported video file extensions
video_extensions=("mkv" "mp4" "avi" "mov" "wmv")

# Function to check if a file is a video
is_video_file() {
    local filename="$1"
    local extension="${filename##*.}"
    for ext in "${video_extensions[@]}"; do
        if [[ "$extension" == "$ext" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to extract audio from video
extract_audio() {
    local input_file="$1"
    local output_file="$2"
    ffmpeg -i "$input_file" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$output_file"
}

# Function to process video for attendees
process_video_for_attendees() {
    local video_path="$1"
    local output_path="$2"
    # Call python meeting_attendee_detection.py with the video path and output file as arguments
    python3 /root/scripts/meeting_attendee_detection.py "$video_path" "$output_path"
}


# Loop over each subdirectory
for sub_dir in "${sub_dirs[@]}"; do
    incoming_dir="$root_dir$sub_dir/"

    # Loop over each audio and video file extension
    for ext in "${audio_extensions[@]}" "${video_extensions[@]}"; do
        # Loop over the files in the incoming directory with the current extension
        for file in "$incoming_dir"*."$ext"; do
            # If this file does not exist, skip to the next iteration
            if [ ! -f "$file" ]; then
                continue
            fi

            # Get the base name of the file (without the extension)
            base_name=$(basename "$file" ."$ext")

            # Create a new subdirectory in the transcribed directory
            new_dir="$transcribed_dir$base_name"
            mkdir -p "$new_dir"

            # Check if the file is a video
            if is_video_file "$file"; then
                echo "--- processing video file $file..." >> /proc/1/fd/1
                audio_file="$new_dir/$base_name.wav"
                extract_audio "$file" "$audio_file"
                process_video_for_attendees "$file" "$new_dir"
                file="$audio_file"  # Set file to the extracted audio for further processing
            else
                audio_file="$file"
            fi

            # Check which subdirectory we are in and run the appropriate command
            if [ "$sub_dir" == "diarize" ]; then
                echo "--- diarizing $audio_file..." >> /proc/1/fd/1
                diarize_start_time=$(date +%s)
                python3 diarize.py --batch-size 16 --whisper-model $DIARIZATION_MODEL --language en -a "$audio_file"
                diarize_end_time=$(date +%s)
                run_time=$((diarize_end_time - diarize_start_time))
            elif [ "$sub_dir" == "transcribe" ]; then
                echo "--- transcribing $audio_file..." >> /proc/1/fd/1
                whisper_start_time=$(date +%s)
                whisperx --batch_size 12 --model $TRANSCRIPTION_MODEL --language en --output_dir "$new_dir" > "$new_dir/$base_name.txt" "$audio_file"
                whisper_end_time=$(date +%s)
                run_time=$((whisper_end_time - whisper_start_time))
            fi

            # Modify $new_dir/$base_name.txt to remove lines that start with the following strings
            sed -i '/^Model was trained with pyannote\.audio/d' "$new_dir/$base_name.txt"
            sed -i '/^Model was trained with torch/d' "$new_dir/$base_name.txt"
            sed -i '/^\[NeMo\]/d' "$new_dir/$base_name.txt"
            sed -i '/^torchvision is not available/d' "$new_dir/$base_name.txt"

            # Move all files with the same base_name to the new subdirectory
            mv "$incoming_dir$base_name"* "$new_dir/"

            # Change the owner of the files to the user transcriptionstream
            chown -R transcriptionstream:transcriptionstream "$new_dir"

            # Drop messages to the console
            echo "--- done processing $file - output placed in $new_dir" >> /proc/1/fd/1
            if [[ -f "$new_dir/$base_name.txt" ]]; then
                echo "transcription: $(cat "$new_dir/$base_name.txt") " >> /proc/1/fd/1
                echo "Runtime for processing $file = $run_time" >> /proc/1/fd/1
                echo "------------------------------------"
            fi
        done
    done
done
