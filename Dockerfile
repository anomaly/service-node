# While optional this tells the Docker builder of the version
# syntax=docker/dockerfile:1
#
ARG BASE_IMAGE=24.04

# This Dockerfile uses a multi stage build to slim down the image
# https://docs.docker.com/develop/develop-images/multistage-build/
#
# Portion of this is adapted from
# https://bit.ly/3Vw9B2m
#
# Base image for Python applications
# This image is particularly for a web server using uvicorn
FROM --platform=linux/amd64 ubuntu:${BASE_IMAGE} as requirements-stage

# Update the based image to latest versions of packages
# python 3.10 seems to want python3-tk installed
RUN apt update \
    && apt -y upgrade \
    && apt install -y --no-install-recommends gcc python3-dev build-essential libpq-dev python3-tk \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Work in the temporary directory for the build phase
WORKDIR /tmp

# requirements.txt is used to install the python packages
COPY requirements.txt requirements.txt
# Copy the production Taskfile so it ends up on the container
COPY Taskfile.prod.yml Taskfile.yml

### Stage 2

FROM ubuntu:${BASE_IMAGE}

# Update the based image to latest versions of packages
# python 3.10 seems to want python3-tk installed
RUN apt update \
    && apt -y upgrade \
    && apt install -y --no-install-recommends libpq-dev \
    python3-tk postgresql-client curl \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Work in the temporary directory for the build phase
WORKDIR /opt

COPY --from=requirements-stage /tmp/Taskfile.yml /opt/Taskfile.yml
COPY --from=requirements-stage /tmp/requirements.txt /opt/requirements.txt

# Install python package we need
RUN pip install --no-cache-dir --upgrade -r /opt/requirements.txt

CMD ["bash"]

# Labels are used to identify the image
LABEL org.opencontainers.image.source="https://github.com/anomaly/${PROJ_NAME}"
LABEL org.opencontainers.image.description="Service node for Anomaly apps"
LABEL org.opencontainers.image.licenses="MIT"