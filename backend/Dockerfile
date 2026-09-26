FROM python:3.10-slim

WORKDIR /app

# Prevent Python from writing .pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

# Install dependencies
RUN pip install --no-cache-dir pipenv

COPY Pipfile Pipfile.lock* ./
RUN pipenv install --system --deploy || pipenv install --system --skip-lock

# Copy application code
COPY movies/ ./movies/
COPY tests/ ./tests/
COPY .flake8 ./

EXPOSE 5000

CMD ["python", "movies/app.py"]
