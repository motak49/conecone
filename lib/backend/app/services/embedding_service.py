import torch
from torchvision import models, transforms
from PIL import Image
import numpy as np

# ==========================================
# 1. モデルと前処理の準備（起動時に一度だけ実行）
# ==========================================
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ResNet50の読み込み（保存時と同じ設定にする必要がある）
model = models.resnet50(weights=models.ResNet50_Weights.DEFAULT)
model.fc = torch.nn.Identity()  # 最後の分類層を削除して特徴量(2048次元)を取り出す
model = model.to(device)
model.eval()

# 画像の前処理（保存時と同じ設定）
IMAGE_SIZE = 224
transform = transforms.Compose([
    transforms.Resize((IMAGE_SIZE, IMAGE_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225],
    ),
])

# ==========================================
# 2. 関数定義
# ==========================================
def create_embedding(image_path: str) -> np.ndarray:
    """
    画像パスを受け取り、ResNet50で特徴量(2048次元)に変換して返す
    """
    try:
        # 画像を開く
        img = Image.open(image_path).convert("RGB")
        
        # 前処理とTensor化
        tensor = transform(img).unsqueeze(0).to(device)

        # 推論実行（勾配計算なし）
        with torch.no_grad():
            embedding = model(tensor)

        # Numpy配列に変換して1次元(フラット)にする
        return embedding.cpu().numpy().flatten()

    except Exception as e:
        print(f"Error in create_embedding: {e}")
        # エラー時はゼロ埋めの配列を返して落ちないようにする（または例外を投げる）
        return np.zeros(2048)