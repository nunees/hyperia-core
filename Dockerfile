FROM python:3.12-slim

# Create application user
RUN useradd --create-home --shell /bin/bash hyperia  && echo 'hyperia:hyperia' | chpasswd && echo 'root:root' | chpasswd

WORKDIR /app

RUN apt-get update && apt-get install -y \
    pkg-config \
    libvirt-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Give the application user ownership
RUN chown -R hyperia:hyperia /app

# Run the application as hyperia
USER hyperia

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]