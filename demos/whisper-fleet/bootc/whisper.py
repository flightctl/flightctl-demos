import torch
from faster_whisper import WhisperModel

model = WhisperModel("large-v3")
segments, info = model.transcribe("recording.wav", beam_size = 5)

for segment in segments:
    print(segment.text)
