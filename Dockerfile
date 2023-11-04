# Use an official Python runtime as a base image
FROM python:3.9-slim AS base

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

FROM base AS test
COPY requirements-dev.txt requirements-dev.txt
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY repo_generator_test.py repo_generator_test.py

ENTRYPOINT [ "pytest" ]

CMD [ "--cov=repo_generator", "--cov-report=xml:/coverage/coverage.xml" ]


FROM base AS artifact
# Add a non-root user and group
RUN addgroup --system nonroot && \
    adduser --system --ingroup nonroot nonroot

# Set the home directory for the nonroot user
ENV HOME=/home/nonroot

# Create the home directory and set proper permissions
RUN mkdir -p $HOME && \
    chown -R nonroot:nonroot $HOME

# Change the ownership of the /app directory to the nonroot user
RUN chown -R nonroot:nonroot /app

# Switch to the nonroot user
USER nonroot

ENTRYPOINT ["python", "/app/repo_generator.py"]

CMD ["--help"]