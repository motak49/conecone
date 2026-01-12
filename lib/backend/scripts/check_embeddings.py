import json
import numpy as np
from app.config import EMBEDDINGS_JSON_PATH

with open(EMBEDDINGS_JSON_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

print("type(data):", type(data))
print("len(data):", len(data))

first = data[0]
print("keys:", first.keys())

emb = np.array(first["embedding"])
print("embedding shape:", emb.shape)
print("embedding dtype:", emb.dtype)
