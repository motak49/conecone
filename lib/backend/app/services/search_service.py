import numpy as np
from lib.backend.app.services.image_search_service import cosine_similarity
from lib.backend.app.config import TOP_K, EMBEDDINGS_PATH


def search_similar(query_embedding: np.ndarray):
    """
    query_embedding と保存済み embeddings.npy を比較して
    類似度 TOP_K を返す
    """

    # embeddings.npy を読み込む
    embeddings = np.load(
        EMBEDDINGS_PATH,
        allow_pickle=True
    ).item()   # ← dict に戻す（超重要）

    results = []

    for image_name, db_embedding in embeddings.items():
        score = cosine_similarity(
            query_embedding,
            np.array(db_embedding)
        )

        results.append({
            "image": image_name,
            "score": float(score)
        })

    # 類似度で降順ソート
    results.sort(key=lambda x: x["score"], reverse=True)

    # rank を付与
    ranked_results = []
    for i, r in enumerate(results[:TOP_K], start=1):
        r["rank"] = i
        ranked_results.append(r)

    return ranked_results
