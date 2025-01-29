# going to cuda image 12/23
# transcription stream ts-gpu image
#
# Start from ts-gpu image and dump own stuff in there
FROM transcriptionstream/ts-gpu:latest

# Copy the required files over stuff there
COPY transcriptionstream /root/scripts
COPY test.wav /home/transcriptionstream/

# Run the necessary scripts so we have our transcription models IN the image. Adds to build time for download.
RUN python3 diarize.py -a /home/transcriptionstream/test.wav
RUN whisperx --model large-v3 --language en /home/transcriptionstream/test.wav --compute_type int8
#RUN python3 -m pytorch_lightning.utilities.upgrade_checkpoint ../root/.cache/torch/whisperx-vad-segmentation.bin

# Start ssh and run the control script
CMD service ssh start && while true; do bash /root/scripts/ts-control.sh; sleep 5; done
