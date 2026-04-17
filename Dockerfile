FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt ./
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY app.py ./
RUN mkdir -p /app/logs

EXPOSE 8000

CMD ["python", "app.py"]
