import json
import numpy as np
from app.services.embedding_service import create_embedding
from app.services.image_search_service import cosine_similarity
from app.config import TOP_K, EMBEDDINGS_JSON_PATH

def search_similar(query_embedding: np.ndarray):
    """
    query_embedding と保存済み embeddings を比較して
    類似度 TOP_K を返す
    """

    # embeddings.json を読み込む
    with open(EMBEDDINGS_JSON_PATH, "r", encoding="utf-8") as f:
        embeddings_data = json.load(f)
        # ↑ これは list[dict] である前提

    results = []

    for item in embeddings_data:
        db_embedding = np.array(item["embedding"])

        score = cosine_similarity(query_embedding, db_embedding)

        results.append({
            "score": float(score),
            "brand": item.get("brand"),
            "model": item.get("model"),
            "image": item.get("image")
        })

    # 類似度で降順ソート
    results.sort(key=lambda x: x["score"], reverse=True)

    # rank を付与して TOP_K 件返す
    ranked_results = []
    for i, r in enumerate(results[:TOP_K], start=1):
        r["rank"] = i
        ranked_results.append(r)

    return ranked_results
