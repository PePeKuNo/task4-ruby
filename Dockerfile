# Dockerfile for Rails 8 application on Render.com
# Multi-stage build for smaller production image

# =============================================================================
# Stage 1: Build stage - install dependencies and compile assets
# =============================================================================
FROM ruby:3.3-slim AS builder

# NOTE: Install system dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    && rm -rf /var/lib/apt/lists/*

# NOTE: Set working directory
WORKDIR /app

# NOTE: Install bundler
RUN gem install bundler -v 2.5.0

# NOTE: Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' \
    && bundle config set --local without 'development test' \
    && bundle install -j4

# NOTE: Copy package.json and install JS dependencies
COPY package.json package-lock.json* ./
RUN npm ci

# NOTE: Copy application code
COPY . .

# NOTE: Precompile assets
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE=dummy_for_asset_precompile
RUN bundle exec rails assets:precompile

# =============================================================================
# Stage 2: Production stage - minimal runtime image
# =============================================================================
FROM ruby:3.3-slim

# NOTE: Install runtime dependencies only
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    libpq5 \
    libvips \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# NOTE: Create non-root user for security
RUN groupadd -r rails && useradd -r -g rails rails

# NOTE: Set working directory
WORKDIR /app

# NOTE: Copy gems from builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

# NOTE: Change ownership to rails user
RUN chown -R rails:rails /app

# NOTE: Switch to non-root user
USER rails

# NOTE: Expose port
EXPOSE 3000

# NOTE: Set environment variables
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true
ENV PORT=3000

# NOTE: Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3000/up || exit 1

# NOTE: Start the application
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]