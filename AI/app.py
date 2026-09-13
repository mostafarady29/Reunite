import os
import shutil
import tempfile
import zipfile
from pathlib import Path
from urllib.request import Request, urlopen

import gradio as gr
import numpy as np
import spaces
import torch
import torch.nn as nn
import torch.nn.functional as F
from dotenv import load_dotenv
from PIL import Image
from torchvision import models, transforms

load_dotenv()
EMBEDDING_DIM = 512
MODEL_PATH = Path(os.getenv("MODEL_PATH", "/tmp/encoder.pth"))
MODEL_URL = os.getenv("MODEL_URL", "https://www.kaggle.com/api/v1/datasets/download/mhmdelshoraky/best-encoder-model?datasetVersionNumber=1")

class Siamese(nn.Module):
    def __init__(self):
        super().__init__()
        self.backbone = models.resnet50(weights=None)
        self.backbone.fc = nn.Identity()
        self.head = nn.Sequential(nn.Linear(2048, 1024), nn.ReLU(), nn.Linear(1024, EMBEDDING_DIM))

    def forward(self, image):
        return F.normalize(self.head(self.backbone(image)), p=2, dim=1)

def download_model():
    if MODEL_PATH.is_file():
        return
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temp_dir:
        archive = Path(temp_dir) / "model.zip"
        request = Request(MODEL_URL, headers={"User-Agent": "Reunite AI"})
        with urlopen(request, timeout=300) as response, archive.open("wb") as output:
            shutil.copyfileobj(response, output)
        with zipfile.ZipFile(archive) as zipped:
            candidates = [entry for entry in zipped.infolist() if not entry.is_dir() and Path(entry.filename).suffix.lower() in {".pt", ".pth", ".ckpt"}]
            if not candidates:
                raise RuntimeError("Model checkpoint was not found.")
            with zipped.open(candidates[0]) as source, MODEL_PATH.open("wb") as output:
                shutil.copyfileobj(source, output)

def load_model():
    download_model()
    checkpoint = torch.load(MODEL_PATH, map_location="cpu")
    if isinstance(checkpoint, dict):
        checkpoint = checkpoint.get("state_dict", checkpoint.get("model_state_dict", checkpoint))
    model = Siamese()
    model.load_state_dict(checkpoint)
    model.eval()
    return model

model = load_model()
preprocess = transforms.Compose([transforms.Resize((224, 224)), transforms.ToTensor()])

@spaces.GPU
def embed(image):
    if image is None:
        raise gr.Error("Image data is required.")
    if not isinstance(image, Image.Image):
        image = Image.fromarray(np.asarray(image))
    image = image.convert("RGB")
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model.to(device)
    tensor = preprocess(image).unsqueeze(0).to(device)
    with torch.inference_mode():
        vector = model(tensor).squeeze(0).cpu().numpy().astype(np.float32)
    if vector.size != EMBEDDING_DIM or not np.isfinite(vector).all():
        raise gr.Error("The model produced an invalid embedding.")
    return vector.tolist()

demo = gr.Interface(fn=embed, inputs=gr.Image(type="pil"), outputs=gr.JSON(), api_name="embed")
demo.launch(server_name=os.getenv("HOST", "0.0.0.0"), server_port=int(os.getenv("PORT", "7860")))