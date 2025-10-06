# Use Ubuntu 24.04 (Noble Numbat) as the base image
FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_BIN=/usr/local/bundle/bin \
    GEM_HOME=/usr/local/bundle

# Add bundle bin to PATH
ENV PATH="${BUNDLE_BIN}:${PATH}"

# Install system dependencies and Ruby
RUN apt-get update && apt-get install -y \
    ruby \
    ruby-dev \
    ruby-bundler \
    build-essential \
    git \
    curl \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    software-properties-common \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock (if exists) and install dependencies
COPY Gemfile* ./
# Configure both bundler and gem to handle SSL issues in build environment
RUN echo ":ssl_verify_mode: 0" >> /root/.gemrc && \
    bundle config set ssl_verify_mode 0 && \
    bundle config set --local without 'development test' && \
    bundle install --retry 3

# Copy application files
COPY . .

# Make main.rb executable
RUN chmod +x main.rb

# Set the entry point - use bundle exec to ensure gems are loaded
CMD ["bundle", "exec", "ruby", "main.rb"]
