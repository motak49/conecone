import csv
import os
import time
import requests
from urllib.parse import urlparse

# =========================
# 設定
# =========================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CSV_PATH = os.path.join(BASE_DIR, "data", "products.csv")
OUTPUT_DIR = os.path.join(BASE_DIR, "data", "raw")

TIMEOUT = 10
SLEEP_SEC = 0.2  # サーバ負荷軽減

# =========================
# 準備
# =========================
os.makedirs(OUTPUT_DIR, exist_ok=True)


def get_extension(url: str) -> str:
    path = urlparse(url).path
    ext = os.path.splitext(path)[1].lower()
    return ext if ext else ".jpg"


def download_image(url: str, save_path: str):
    response = requests.get(url, timeout=TIMEOUT)
    response.raise_for_status()
    with open(save_path, "wb") as f:
        f.write(response.content)


# =========================
# メイン処理
# =========================
def main():
    if not os.path.exists(CSV_PATH):
        raise FileNotFoundError(f"CSV が見つかりません: {CSV_PATH}")

    with open(CSV_PATH, newline="", encoding="utf-8") as csvfile:
        reader = csv.reader(csvfile)

        header = next(reader, None)  # 1行目（タイトル行）
        if not header:
            raise ValueError("CSV が空です")

        for index, row in enumerate(reader, start=1):
            if not row:
                print(f"[SKIP] 空行（行 {index + 1}）")
                continue

            url = row[-1].strip()  # ← 最後の列が product_url

            if not url.startswith("http"):
                print(f"[SKIP] URL不正（行 {index + 1}）: {url}")
                continue

            ext = get_extension(url)
            filename = f"{index:05d}{ext}"
            save_path = os.path.join(OUTPUT_DIR, filename)

            if os.path.exists(save_path):
                print(f"[SKIP] 既存ファイル: {filename}")
                continue

            try:
                download_image(url, save_path)
                print(f"[OK] {filename}")

            except Exception as e:
                print(f"[ERROR] 行 {index + 1}: {url}")
                print(f"        {e}")

            time.sleep(SLEEP_SEC)


if __name__ == "__main__":
    main()
    print("✅ 画像のダウンロードが完了しました")
