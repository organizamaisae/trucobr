FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY server ./server
RUN useradd --create-home truco && chown -R truco:truco /app
USER truco
EXPOSE 8000
CMD ["python", "server/server.py", "--host", "0.0.0.0", "--port", "8000"]
