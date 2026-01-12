from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse

from app.config import INFERENCE_TMP_DIR, TOP_K
from app.services.embedding_service import create_embedding
from app.services.search_service import search_similar

app = FastAPI()

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    print("=== predict called ===")
    print("filename:", file.filename)

    # ① 画像を一時保存
    INFERENCE_TMP_DIR.mkdir(parents=True, exist_ok=True)
    image_path = INFERENCE_TMP_DIR / file.filename

    with open(image_path, "wb") as f:
        f.write(await file.read())

    # ② embedding を作る
    query_embedding = create_embedding(str(image_path))

    # ③ 類似検索を実行（← ここが本体）
    results = search_similar(query_embedding)

    # ④ JSONで返す
    return {
        "results": results
    }