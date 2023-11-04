# Use an official Python runtime as a base image
FROM python:3.9-slim

# Set the maintainer label
#LABEL maintainer="your_email@example.com"

# Set the working directory inside the container
WORKDIR /app

# Install required packages
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install Git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Copy the current directory contents into the container at /app
COPY repo_generator.py /app/

ENTRYPOINT ["python", "/app/repo_generator.py"]

CMD ["--help"]