FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY server ./server
RUN useradd --create-home truco && chown -R truco:truco /app
USER truco
# The application uses PORT from the environment and falls back to 8080.
EXPOSE 8080
CMD ["python", "/app/server/server.py"]
