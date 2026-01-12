import os
from PIL import Image, ImageEnhance

# =========================
# 設定
# =========================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

RAW_DIR = os.path.join(BASE_DIR, "data", "raw")
OUTPUT_DIR = os.path.join(BASE_DIR, "data", "processed")

IMAGE_SIZE = 224
BRIGHTNESS = 1.1     # 明るさ補正
CONTRAST = 1.2       # コントラスト補正

SUPPORTED_EXT = (".jpg", ".jpeg", ".png", ".webp")

# =========================
# 準備
# =========================
os.makedirs(OUTPUT_DIR, exist_ok=True)


def center_crop(img: Image.Image) -> Image.Image:
    w, h = img.size
    side = min(w, h)

    left = (w - side) // 2
    top = (h - side) // 2
    right = left + side
    bottom = top + side

    return img.crop((left, top, right, bottom))


def preprocess_image(src_path: str, dst_path: str):
    img = Image.open(src_path).convert("RGB")

    # 中央トリミング
    img = center_crop(img)

    # リサイズ
    img = img.resize((IMAGE_SIZE, IMAGE_SIZE), Image.BILINEAR)

    # 明度調整
    img = ImageEnhance.Brightness(img).enhance(BRIGHTNESS)

    # コントラスト調整
    img = ImageEnhance.Contrast(img).enhance(CONTRAST)

    img.save(dst_path, quality=95)


def main():
    files = sorted(os.listdir(RAW_DIR))

    count = 0
    for filename in files:
        if not filename.lower().endswith(SUPPORTED_EXT):
            continue

        src_path = os.path.join(RAW_DIR, filename)
        dst_path = os.path.join(OUTPUT_DIR, filename)

        try:
            preprocess_image(src_path, dst_path)
            count += 1
            print(f"[OK] {filename}")

        except Exception as e:
            print(f"[ERROR] {filename}")
            print(f"        {e}")

    print(f"\n✅ 前処理完了：{count} 枚")


if __name__ == "__main__":
    main()
