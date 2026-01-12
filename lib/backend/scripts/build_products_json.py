import csv
import json
import os
from urllib.parse import urlparse

# =========================
# 設定
# =========================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CSV_PATH = os.path.join(BASE_DIR, "data", "products.csv")
IMAGE_DIR = os.path.join(BASE_DIR, "data", "raw")
OUTPUT_JSON = os.path.join(BASE_DIR, "data", "products.json")


def get_extension(url: str) -> str:
    path = urlparse(url).path
    ext = os.path.splitext(path)[1].lower()
    return ext if ext else ".jpg"


# =========================
# メイン処理
# =========================
def main():
    if not os.path.exists(CSV_PATH):
        raise FileNotFoundError(f"CSV が見つかりません: {CSV_PATH}")

    products = []

    with open(CSV_PATH, newline="", encoding="utf-8") as csvfile:
        reader = csv.reader(csvfile)

        header = next(reader, None)
        if not header:
            raise ValueError("CSV が空です")

        for index, row in enumerate(reader, start=1):
            if not row:
                continue

            # CSVの最後の列が product_url
            product_url = row[-1].strip()

            if not product_url.startswith("http"):
                print(f"[SKIP] URL不正（行 {index + 1}）")
                continue

            ext = get_extension(product_url)
            image_filename = f"{index:05d}{ext}"
            image_path = os.path.join("data", "raw", image_filename)

            # 画像存在チェック
            if not os.path.exists(os.path.join(BASE_DIR, image_path)):
                print(f"[WARN] 画像が存在しません: {image_filename}")

            product = {
                "id": index,
                "brand": row[0],
                "series": row[1],
                "model": row[2],
                "year": row[3] if len(row) > 4 else None,
                "image": image_path,
                "source_url": product_url
            }

            products.append(product)

    # JSON 出力
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(products, f, ensure_ascii=False, indent=2)

    print(f"✅ products.json を生成しました（{len(products)} 件）")


if __name__ == "__main__":
    main()
