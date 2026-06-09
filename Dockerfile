FROM python:3.11-slim
WORKDIR /app
COPY . .
CMD ["python", "-c", "from tools.validate_skill import validate_skill; print('Import OK')"]
