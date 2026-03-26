FROM python:3.9-slim

WORKDIR /app

# Copy single file
COPY app.py .

RUN pip install flask boto3

CMD ["python", "app.py"]