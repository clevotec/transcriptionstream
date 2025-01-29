# going to cuda image 12/23
# transcription stream ts-gpu image
#
# Start from a smaller base image, such as Ubuntu slim or Alpine if possible
FROM nvidia/cuda:12.0.1-cudnn8-runtime-ubuntu22.04


# Set environment variables to reduce interaction during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages in a single RUN command and clean up in the same layer
RUN apt-get update && apt-get install -y \
    python3.9 \
    ssh \
    openssh-server \
    ffmpeg \
    python3-pip \
    build-essential \
    cython3 \
    git \
    python3-wheel \
#    nvidia-cuda-toolkit \
#    nvidia-cuda-toolkit-gcc \
    tesseract-ocr \
    tesseract-ocr-eng \
    tzdata \
    sox \
 && rm -rf /var/lib/apt/lists/*

# added to fix sox/numpy error while installing whisper-diarization 03/24/2024
RUN pip install typing_extensions && pip install numpy

# Clone only the necessary branch or commit of whisper-diarization to reduce size
RUN git clone --depth 1 https://github.com/clevotec/whisper-diarization.git

# Install whisper-diarization requirements
WORKDIR /whisper-diarization
RUN pip install huggingface-hub==0.23.2 typing-extensions &&\
    pip install -r requirements.txt &&\
    pip install meilisearch ffmpeg-python opencv-python pytesseract moviepy


# Copy the required files
COPY transcriptionstream /root/scripts
COPY test.wav /home/transcriptionstream/

# Create a new user and setup the environment
RUN useradd -m -p $(openssl passwd -1 nomoresaastax) transcriptionstream \
 && mkdir -p /home/transcriptionstream/incoming \
 && mkdir -p /home/transcriptionstream/transcribed \
 && chown -R transcriptionstream:transcriptionstream /home/transcriptionstream/ \
 && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config

RUN pip uninstall huggingface_hub; pip install huggingface-hub==0.20.3

# Run the necessary scripts so we have our transcription models IN the image. Adds to build time for download.
# RUN python3 diarize.py -a /home/transcriptionstream/test.wav
# RUN whisperx --model large-v3 --language en /home/transcriptionstream/test.wav --compute_type int8
#RUN python3 -m pytorch_lightning.utilities.upgrade_checkpoint ../root/.cache/torch/whisperx-vad-segmentation.bin

# Expose the SSH port
# EXPOSE 22

# Start ssh and run the control script
# CMD service ssh start && while true; do bash /root/scripts/ts-control.sh; sleep 5; done
CMD service ssh start && while true; do echo 'tick'; sleep 30; done

