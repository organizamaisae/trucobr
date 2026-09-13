FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY server ./server
RUN useradd --create-home truco && chown -R truco:truco /app
USER truco
# Railway injects PORT at runtime. The application uses 8080 only when PORT is absent.
EXPOSE 8080
CMD ["python", "/app/server/server.py"]
