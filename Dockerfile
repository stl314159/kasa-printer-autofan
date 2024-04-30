# Use an official Rust runtime as the base image for the build stage
FROM rust:latest as builder

# Set default rust compiler
RUN rustup default stable

# Create a dummy project and build it to cache the Rust dependencies
RUN cargo new --bin dummy
WORKDIR /dummy
RUN cargo build --release
RUN rm src/*.rs

# Use an official Python runtime as the base image for the final stage
FROM python:3.9

# Set the working directory in the container
WORKDIR /app

# Copy the compiled Rust artifacts from the build stage
COPY --from=builder /usr/local/cargo /usr/local/cargo
COPY --from=builder /usr/local/rustup /usr/local/rustup

# Update PATH to include Rust binaries
ENV PATH="/usr/local/cargo/bin:${PATH}"

# apt install dependencies
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements.txt file to the working directory
COPY ./src/requirements.txt .

# Upgrade pip
RUN pip install --upgrade pip

# Install the package specified in requirements.txt
RUN pip install -r requirements.txt

# Copy the Python script to the working directory
COPY src/app.sh .

# Run the Python script when the container starts
CMD ["./app.sh"]
