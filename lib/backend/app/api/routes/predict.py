import os
import uuid
from fastapi import APIRouter, UploadFile, File
from fastapi.responses import JSONResponse

from app.services.image_search_service import ImageSearchService
from app.config import TMP_DIR, TOP_K

router = APIRouter(
    prefix="/predict",
    tags=["Predict"]
)

# 起動時1回
search_service = ImageSearchService()


@router.post("")
async def predict(image: UploadFile = File(...)):
    ext = os.path.splitext(image.filename)[1]
    tmp_name = f"{uuid.uuid4()}{ext}"
    tmp_path = os.path.join(TMP_DIR, tmp_name)

    with open(tmp_path, "wb") as f:
        f.write(await image.read())

    results = search_service.search(tmp_path, top_k=TOP_K)

    return JSONResponse(content={"results": results})
