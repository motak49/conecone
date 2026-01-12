import json
import numpy as np
from PIL import Image

import torch
from torchvision import models, transforms

def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    return float(
        np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
    )


class ImageSearchService:
    def __init__(self, device: str | None = None):
        self.device = torch.device(
            device if device else (
                "cuda" if torch.cuda.is_available() else "cpu"
            )
        )

        # モデル
        self.model = models.resnet50(
            weights=models.ResNet50_Weights.DEFAULT
        )
        self.model.fc = torch.nn.Identity()
        self.model = self.model.to(self.device)
        self.model.eval()

        # 前処理
        self.transform = transforms.Compose([
            transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225],
            ),
        ])

        # データロード
        self.embeddings = np.load(EMBEDDINGS_PATH)

        with open(IMAGE_IDS_PATH, encoding="utf-8") as f:
            self.image_ids = json.load(f)

        with open(PRODUCTS_JSON_PATH, encoding="utf-8") as f:
            self.products = json.load(f)

    # -------------------------
    def _extract_embedding(self, image_path: str) -> np.ndarray:
        img = Image.open(image_path).convert("RGB")
        tensor = self.transform(img).unsqueeze(0).to(self.device)

        with torch.no_grad():
            emb = self.model(tensor)

        return emb.cpu().numpy().flatten()

    @staticmethod
    def _cosine_similarity(a, b) -> float:
        return float(
            np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
        )

    # -------------------------
    def search(self, image_path: str, top_k: int = 3) -> list[dict]:
        query_emb = self._extract_embedding(image_path)

        scores = []
        for idx, emb in enumerate(self.embeddings):
            score = self._cosine_similarity(query_emb, emb)
            scores.append((idx, score))

        scores.sort(key=lambda x: x[1], reverse=True)
        top_results = scores[:top_k]

        results = []
        for rank, (idx, score) in enumerate(top_results, start=1):
            image_id = self.image_ids[idx]
            product = next(
                p for p in self.products
                if p["image"].endswith(image_id)
            )

            results.append({
                "rank": rank,
                "similarity": round(score, 3),
                "brand": product["brand"],
                "model": f"{product['series']} {product['model']}",
                "image": image_id
            })

        return results
