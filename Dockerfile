# ==========================================
# Stage 1: Build Stage
# ==========================================
FROM python:3.11-slim AS builder

# Install build dependencies: 
# - make & zip: required to compile yt-dlp
# - curl & unzip: required to download and install Deno
RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    zip \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install the latest Deno binary
# The installer places the binary at /root/.deno/bin/deno
RUN curl -fsSL https://deno.land/x/install/install.sh | sh

# Set working directory for yt-dlp
WORKDIR /src

# Copy the local repository files into the build container
COPY . .

# Compile the standalone python executable from source
RUN make yt-dlp

# ==========================================
# Stage 2: Runtime Stage
# ==========================================
FROM python:3.11-slim

# Install system runtime dependencies:
# - ffmpeg: Required for merging video/audio streams and post-processing
# Notice we completely removed nodejs!
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install highly recommended Python dependencies
RUN pip install --no-cache-dir \
    curl_cffi \
    mutagen \
    websockets \
    requests \
    yt-dlp-ejs

# Copy the compiled yt-dlp binary from the builder stage
COPY --from=builder /src/yt-dlp /usr/local/bin/yt-dlp

# Copy the Deno binary from the builder stage
COPY --from=builder /root/.deno/bin/deno /usr/local/bin/deno

# Ensure both binaries are executable
RUN chmod +x /usr/local/bin/yt-dlp /usr/local/bin/deno

# Set up the download directory inside the container
WORKDIR /downloads

# Make yt-dlp the entrypoint
ENTRYPOINT ["yt-dlp"]

# Show the help menu if no arguments are passed
CMD ["--help"]