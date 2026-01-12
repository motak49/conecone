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

EMB_DIR = os.path.join(BASE_DIR, "data", "embeddings")
IMAGE_DIR = os.path.join(BASE_DIR, "data", "processed")
PRODUCTS_JSON = os.path.join(BASE_DIR, "data", "products.json")

IMAGE_SIZE = 224
TOP_K = 3

# =========================
# モデル準備（②と同一）
# =========================
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model = models.resnet50(weights=models.ResNet50_Weights.DEFAULT)
model.fc = torch.nn.Identity()
model = model.to(device)
model.eval()

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
        emb = model(tensor)

    return emb.cpu().numpy().flatten()


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


# =========================
# メイン検索処理
# =========================
def main(query_image_filename: str):
    # 既存データ読み込み
    embeddings = np.load(os.path.join(EMB_DIR, "embeddings.npy"))
    with open(os.path.join(EMB_DIR, "image_ids.json"), encoding="utf-8") as f:
        image_ids = json.load(f)

    with open(PRODUCTS_JSON, encoding="utf-8") as f:
        products = json.load(f)

    # クエリ画像 Embedding
    query_image_path = os.path.join(IMAGE_DIR, query_image_filename)
    query_emb = extract_embedding(query_image_path)

    # 類似度計算
    scores = []
    for idx, emb in enumerate(embeddings):
        score = cosine_similarity(query_emb, emb)
        scores.append((idx, score))

    # Top-K 抽出
    scores.sort(key=lambda x: x[1], reverse=True)
    top_results = scores[:TOP_K]

    print("\n🔍 検索結果")
    for rank, (idx, score) in enumerate(top_results, start=1):
        image_id = image_ids[idx]

        product = next(
            p for p in products if p["image"].endswith(image_id)
        )

        print(f"\n#{rank}")
        print(f" 類似度: {score:.3f}")
        print(f" ブランド: {product['brand']}")
        print(f" モデル: {product['series']} {product['model']}")
        print(f" 画像: {image_id}")


if __name__ == "__main__":
    # 例: processed/00001.jpg を検索クエリにする
    main("00001.jpg")
