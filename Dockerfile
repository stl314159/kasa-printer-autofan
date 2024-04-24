# Use an official Rust runtime as the base image for the build stage
FROM rust:latest as builder

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

# Copy the requirements.txt file to the working directory
COPY ./src/requirements.txt .

# Upgrade pip
RUN pip install --upgrade pip

# Set default rust compiler
RUN rustup default stable

# Install the package specified in requirements.txt
RUN pip install -r requirements.txt

# Copy the Python script to the working directory
COPY src/app.py .

# Run the Python script when the container starts
CMD ["python", "app.py"]
