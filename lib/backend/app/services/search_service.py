import os
import json
import numpy as np
from lib.backend.app.services.image_search_service import cosine_similarity
from lib.backend.app.config import TOP_K, EMBEDDINGS_PATH, PRODUCTS_JSON_PATH, IMAGE_IDS_PATH, BASE_DIR

# products.json のパスを定義（configにない場合を想定して計算）
#PRODUCTS_JSON_PATH = os.path.join(BASE_DIR, "data", "products.json")

def search_similar(query_embedding: np.ndarray):
    """
    query_embedding と保存済み embeddings.npy を比較して
    詳細情報（ブランド、モデル等）付きの類似結果を返す
    """

    # 1. データ読み込み
    embeddings = np.load(EMBEDDINGS_PATH)

    # image_ids.json の読み込み
    base_dir = os.path.dirname(EMBEDDINGS_PATH)
    ids_path = os.path.join(base_dir, "image_ids.json")
    with open(ids_path, "r", encoding="utf-8") as f:
        image_ids = json.load(f)

    # products.json の読み込み（詳細情報取得用）
    with open(PRODUCTS_JSON_PATH, "r", encoding="utf-8") as f:
        products = json.load(f)

    results = []

    # 2. 全件比較
    for idx, db_embedding in enumerate(embeddings):
        score = cosine_similarity(
            query_embedding,
            db_embedding
        )
        results.append({
            "index": idx,
            "score": float(score)
        })

    # 3. ソート
    results.sort(key=lambda x: x["score"], reverse=True)

    # 4. 上位結果の構築
    ranked_results = []
    for i, r in enumerate(results[:TOP_K], start=1):
        idx = r["index"]
        
        # ファイル名の特定
        image_name = image_ids[idx] if idx < len(image_ids) else "unknown.jpg"
        
        # products.json から該当商品を検索
        # imageパスの末尾が image_name と一致するものを探す
        product_info = next(
            (p for p in products if p["image"].endswith(image_name)),
            None
        )

        # デフォルト値
        brand = "Unknown"
        model = "Unknown"
        
        if product_info:
            brand = product_info.get("brand", "Unknown")
            # series と model を結合して表示名にする
            series = product_info.get("series", "")
            model_name = product_info.get("model", "")
            model = f"{series} {model_name}".strip()

        ranked_results.append({
            "rank": i,
            "similarity": r["score"],  # Flutterに合わせて 'similarity' に変更
            "brand": brand,
            "model": model,
            "image": image_name
        })

    return ranked_results