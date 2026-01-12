import os
import json
import numpy as np
from PIL import Image

import torch
from torchvision import models, transforms

# =========================
# 設定
# =========================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

IMAGE_DIR = os.path.join(BASE_DIR, "data", "processed")
OUTPUT_DIR = os.path.join(BASE_DIR, "data", "embeddings")

IMAGE_SIZE = 224
SUPPORTED_EXT = (".jpg", ".jpeg", ".png", ".webp")

# =========================
# 準備
# =========================
os.makedirs(OUTPUT_DIR, exist_ok=True)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ResNet50（分類層を除去）
model = models.resnet50(weights=models.ResNet50_Weights.DEFAULT)
model.fc = torch.nn.Identity()
model = model.to(device)
model.eval()

# ImageNet 正規化
transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225],
    ),
])


def extract_embedding(image_path: str) -> np.ndarray:
    img = Image.open(image_path).convert("RGB")
    tensor = transform(img).unsqueeze(0).to(device)

    with torch.no_grad():
        embedding = model(tensor)

    return embedding.cpu().numpy().flatten()


def main():
    embeddings = []
    image_ids = []

    files = sorted(os.listdir(IMAGE_DIR))

    for filename in files:
        if not filename.lower().endswith(SUPPORTED_EXT):
            continue

        image_path = os.path.join(IMAGE_DIR, filename)

        try:
            emb = extract_embedding(image_path)
            embeddings.append(emb)
            image_ids.append(filename)

            print(f"[OK] {filename}")

        except Exception as e:
            print(f"[ERROR] {filename}")
            print(f"        {e}")

    embeddings = np.vstack(embeddings)

    # 保存
    np.save(os.path.join(OUTPUT_DIR, "embeddings.npy"), embeddings)

    with open(os.path.join(OUTPUT_DIR, "image_ids.json"), "w", encoding="utf-8") as f:
        json.dump(image_ids, f, ensure_ascii=False, indent=2)

    print(f"\n✅ Embedding 抽出完了：{len(image_ids)} 件")
    print(f"   次元数：{embeddings.shape[1]}")


if __name__ == "__main__":
    main()
