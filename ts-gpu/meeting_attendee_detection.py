import argparse
import cv2
import pytesseract
from moviepy.editor import VideoFileClip
import re
import os

def find_attendee_frame(video_path, interval=2):
    """Find the frame with the most potential attendee names."""
    video = VideoFileClip(video_path)
    max_names = 0
    best_frame = None
    best_names = set()

    for t in range(0, int(video.duration), interval):
        frame = video.get_frame(t)
        text = process_frame(frame)
        names = extract_names(text)

        if len(names) > max_names:
            max_names = len(names)
            best_frame = frame
            best_names = set(names)

        # If we haven't found any names in the first minute, break
        if t > 5*60 and max_names == 0:
            break

    video.close()
    return best_frame, best_names

def process_frame(frame):
    """Process a single frame using Tesseract OCR."""
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    text = pytesseract.image_to_string(gray)
    return text

def extract_names(text):
    """Extract potential names from the OCR text."""
    # Adjust this regex pattern based on the naming conventions in your meetings
    name_pattern = r'\b[A-Z][a-z]+(?:\s[A-Z][a-z]+)+\b'
    names = re.findall(name_pattern, text)
    return names

def main(video_path, output_path):
    print("Searching for the frame with attendee names...")
    best_frame, attendees = find_attendee_frame(video_path)

    if not attendees:
        print("No attendees found. The script might need adjusting for this particular video format.")
        return

    # print(f"\nFound {len(attendees)} attendees:")
    for name in sorted(attendees):
        print(name)

    # Write attendees to the output file
    attendees_file = os.path.join(output_path, "attendees.txt")
    with open(attendees_file, 'w') as f:
        for name in sorted(attendees):
            f.write(f"{name}\n")
    
    print(f"\nAttendee names have been written to {attendees_file}")


    # Optionally, save the frame with attendee names
    cv2.imwrite(os.path.join(output_path, "attendees_frame.jpg"), cv2.cvtColor(best_frame, cv2.COLOR_RGB2BGR))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract attendee names from a video file.")
    parser.add_argument("video_path", help="Path to the video file")
    parser.add_argument("output_path", help="Path to the output file for attendee names")
    args = parser.parse_args()

    main(args.video_path, args.output_path)
