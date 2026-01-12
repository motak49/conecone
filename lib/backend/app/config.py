from pathlib import Path

# プロジェクト内パス定義
BASE_DIR = Path(__file__).resolve().parent

DATA_DIR = BASE_DIR / "data"
EMBEDDINGS_DIR = DATA_DIR / "embeddings"

# embeddings.json のパス（←これを正とする）
EMBEDDINGS_JSON_PATH = EMBEDDINGS_DIR / "embeddings.json"

# 推論関連
INFERENCE_TMP_DIR = DATA_DIR / "inference" / "tmp"

# 検索設定
TOP_K = 3

print("config loaded:", EMBEDDINGS_JSON_PATH)