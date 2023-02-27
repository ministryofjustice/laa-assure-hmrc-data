# This template builds three images, to optimise caching:
# base: runtime and build-time dependencies
# builder: builds runtime dependencies (gems and js packages)
# production: final build and run of the app
#

###############################################################
# base - dependencies required both at runtime and build time #
###############################################################
FROM ruby:3.2.1-alpine3.17 as base
MAINTAINER LAA Apply for civil legal aid team

# postgresql-dev: postgres driver and libraries
# yarn: node package manager
RUN apk add --update --no-cache \
  postgresql-dev \
  yarn

# tzdata: timezone builder
# as it's not configured by default in Alpine
RUN apk add --update --no-cache tzdata && \
    cp /usr/share/zoneinfo/Europe/London /etc/localtime && \
    echo "Europe/London" > /etc/timezone

#################################################################
# builder - build dependencies using build-time os dependencies #
#################################################################
FROM base as builder

WORKDIR /app

# system dependencies required to build some gems
# build-base: dependencies for bundle
# git: for bundler
RUN apk add --update \
  build-base \
  git

# install gems and remove gem cache
COPY Gemfile* .ruby-version ./
RUN gem install bundler -v $(cat Gemfile.lock | tail -1 | tr -d " ") && \
    bundler -v && \
    bundle config set frozen 'true' && \
    bundle config set no-cache 'true' && \
    bundle config set no-binstubs 'true' && \
    bundle config set without test:development && \
    bundle install --jobs 5 --retry 5 && \
    rm -rf /usr/local/bundle/cache

# install npm packages
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --check-files --ignore-scripts

# copy remaining files to /app (except what is defined in .dockerignore)
COPY . .

# precompile assets
RUN RAILS_ENV=production \
    SECRET_KEY_BASE=required-to-run-but-not-used \
    bundle exec rails assets:precompile

# cleanup to save space in the production image
RUN rm -rf node_modules log/* tmp/* /tmp && \
    rm -rf /usr/local/bundle/cache && \
    rm -rf .env && \
    find /usr/local/bundle/gems -name "*.c" -delete && \
    find /usr/local/bundle/gems -name "*.h" -delete && \
    find /usr/local/bundle/gems -name "*.o" -delete && \
    find /usr/local/bundle/gems -name "*.html" -delete

############################################
# production - build and use runtime image #
############################################
FROM base as production

# add non-root user and group with alpine first available uid, 1000
ENV APPUID 1000
RUN addgroup -g $APPUID -S appgroup && \
    adduser -u $APPUID -S appuser -G appgroup

# create some required directories in conventional alpine location
RUN mkdir -p /usr/src/app && \
    mkdir -p /usr/src/app/log && \
    mkdir -p /usr/src/app/tmp && \
    mkdir -p /usr/src/app/tmp/pids

# work in conventional alpine directory
WORKDIR /usr/src/app

# libpq: required to run postgres
RUN apk add --no-cache libpq

# copy over files generated in the builder image
COPY --from=builder /app /usr/src/app
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# non-root user should own these directories
# log: for log file writing
# tmp: for pids and other things
# db: for schema migration being run on entry, at least
RUN chown -R appuser:appgroup log tmp db

# add env vars for use by ping endpoints in app
ARG APP_BUILD_DATE
ENV APP_BUILD_DATE ${APP_BUILD_DATE}
ARG APP_BUILD_TAG
ENV APP_BUILD_TAG ${APP_BUILD_TAG}
ARG APP_GIT_COMMIT
ENV APP_GIT_COMMIT ${APP_GIT_COMMIT}

# switch to non-root user
USER $APPUID

# set port env var used by puma
ENV PORT 3000
EXPOSE $PORT

ENTRYPOINT ["./docker-entrypoint"]
