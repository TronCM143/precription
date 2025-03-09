FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
    
    # Copy application
COPY . .
    
    # Set proper permissions for uploads folder
RUN mkdir -p /app/uploads && \
    chmod 777 /app/uploads
    
    # Use explicit Gunicorn configuration
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--timeout", "120", "translator:app"]