# Use an official Python runtime as a base image
FROM alpine:latest as builder
RUN apk add --no-cache python3 py3-pip git

# Set the maintainer label
#LABEL maintainer="your_email@example.com"

# Set the working directory inside the container
WORKDIR /app

# Install required packages
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the current directory contents into the container at /app
COPY repo_generator.py /app/

FROM builder AS test
COPY requirements-dev.txt requirements-dev.txt
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY repo_generator_test.py repo_generator_test.py

ENTRYPOINT [ "pytest" ]

CMD [ "--cov=repo_generator", "--cov-report=xml:/coverage/coverage.xml" ]


FROM builder AS artifact
# Add a non-root user and group
RUN addgroup --system nonroot && \
    adduser --system --ingroup nonroot nonroot

# Set the home directory for the nonroot user
ENV HOME=/home/nonroot

# Create the home directory and set proper permissions
RUN mkdir -p $HOME && \
    chown -R nonroot:nonroot $HOME && \
    chown -R nonroot:nonroot /tmp && \
    chown -R nonroot:nonroot /app

# Switch to the nonroot user
USER nonroot

ENTRYPOINT ["python", "/app/repo_generator.py"]

CMD ["--help"]