from fastapi import FastAPI, UploadFile, File
from pathlib import Path
import shutil

from lib.backend.app.services.embedding_service import create_embedding
from lib.backend.app.services.search_service import search_similar
from lib.backend.app.config import INFERENCE_TMP_DIR

app = FastAPI()


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    print("=== predict called ===")
    print("filename:", file.filename)

    # 1️⃣ 保存
    INFERENCE_TMP_DIR.mkdir(parents=True, exist_ok=True)
    save_path = INFERENCE_TMP_DIR / file.filename

    with save_path.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # 2️⃣ embedding 作成
    query_embedding = create_embedding(str(save_path))

    # 3️⃣ 類似検索
    results = search_similar(query_embedding)

    # 4️⃣ 結果を返す
    return {
        "results": results
    }
