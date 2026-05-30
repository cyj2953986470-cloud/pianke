FROM python:3.10-slim

# 系统依赖：OpenCV / RAW / HEIF / 人脸识别
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 libsm6 libxrender1 libxext6 \
    libjpeg62-turbo libpng16-16 libtiff6 libwebp7 \
    libgomp1 build-essential git curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 先装 Python 依赖（利用 Docker 缓存）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && pip uninstall -y opencv-python opencv-python-headless || true \
    && pip install --no-cache-dir --force-reinstall --no-deps "opencv-contrib-python>=4.9" \
    && pip install --no-cache-dir gunicorn

COPY . .

# 预下载 DINOv2 模型（专家模式首次需要）
RUN python -c "from transformers import AutoModel; AutoModel.from_pretrained('facebook/dinov2-base', trust_remote_code=True)" 2>/dev/null || true

EXPOSE 5057

# 照片目录挂载点
VOLUME ["/photos"]

CMD ["python", "app.py", "--port", "5057", "--no-browser"]
