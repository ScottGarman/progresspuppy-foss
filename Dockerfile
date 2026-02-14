FROM ruby:4.0-slim

ENV APP_HOME "/var/opt/progresspuppy-foss"
ENV APP_USER progresspuppy
ENV RAILS_ENV development

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

# Install package dependencies
RUN apt update -y && apt install -y build-essential curl git libsqlite3-dev sqlite3

# Install bundler and app gems
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install -j $(nproc)
COPY . ./

# Cleanup build tools and apt cache to minimize image size
RUN apt purge -y --auto-remove build-essential && \
rm -rf /var/lib/apt/lists/*

# Add the progresspuppy user and group
RUN groupadd $APP_USER && \
useradd -g $APP_USER -s /sbin/nologin -c "ProgressPuppy" $APP_USER && \
chown -R $APP_USER:$APP_USER $APP_HOME

USER $APP_USER

# Install db seeds for default admin account
RUN bin/rails db:migrate && bin/rails db:seed

EXPOSE 3000
CMD [ "bin/rails", "server", "--binding=0.0.0.0" ]
