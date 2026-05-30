FROM python:3.10.16-slim

RUN apt-get update && apt-get install -y --no-install-recommends     libgl1 libglib2.0-0 libsm6 libxrender1 libxext6     libjpeg62-turbo libpng16-16 libtiff6 libwebp7     libgomp1 build-essential git curl     && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt     && pip uninstall -y opencv-python opencv-python-headless || true     && pip install --no-cache-dir --force-reinstall --no-deps "opencv-contrib-python>=4.9"

COPY . .

RUN python -c "from transformers import AutoModel; AutoModel.from_pretrained('facebook/dinov2-base')" 2>&1 || true

EXPOSE 5057

HEALTHCHECK --interval=30s --timeout=5s --retries=3     CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5057/')" || exit 1

CMD ["python", "app.py", "--port", "5057", "--no-browser"]
