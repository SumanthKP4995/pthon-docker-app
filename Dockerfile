FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

HEALTHCHECK CMD curl --fail http://localhost:5000 || exit 1

CMD ["python", "app.py"]
