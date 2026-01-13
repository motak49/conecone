from pathlib import Path
import os

# 1. 自身のディレクトリ(app)を取得
_CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))

#BASE_DIR = Path(__file__).resolve().parent
# 2. その親ディレクトリ(backend)をBASE_DIRとする
BASE_DIR = os.path.dirname(_CURRENT_DIR)

DATA_DIR = os.path.join(BASE_DIR, "data")

# embeddings.json のパス（←これを正とする）
EMBEDDINGS_PATH = os.path.join(DATA_DIR, "embeddings", "embeddings.npy")
IMAGE_IDS_PATH = os.path.join(DATA_DIR, "embeddings", "image_ids.json")
PRODUCTS_JSON_PATH = os.path.join(DATA_DIR, "embeddings", "products.json")

# 推論関連
INFERENCE_TMP_DIR = os.path.join(DATA_DIR, "inference", "tmp")

# 検索設定
TOP_K = 10

print("config loaded:", EMBEDDINGS_PATH)