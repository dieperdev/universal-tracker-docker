FROM ubuntu:14.04

# Expose necessary ports
EXPOSE 80

# https://stackoverflow.com/a/25423366
# Make docker use only `bash` not `sh`
SHELL ["/bin/bash", "-c"]

# Update & upgrade + install deps
RUN apt-get update && apt-get upgrade -y && \
    apt install -y --no-install-recommends wget curl make gcc g++ pkg-config git libcurl4-openssl-dev

##
## Nginx Phusion Passenger
##

# Dedicated account to run the tracker
RUN adduser --system --group --shell /bin/bash tracker

# Log into tracker user
RUN su tracker

# Install Ruby libraries with RVM
# `source` command is required from now on when using RVM
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && \
    curl -L get.rvm.io | bash -s stable && \
    source /usr/local/rvm/scripts/rvm && \
    echo $(rvm requirements)

# Install Ruby and Bundler
# `bundler` version must manually be specified or
# `gem install` will throw an error about the last
# supported `bundler` version for Ruby being 1.17.3
RUN source /usr/local/rvm/scripts/rvm && \
    rvm install 2.2.2 && \
    rvm use 2.2.2 && \
    rvm rubygems current && \
    gem install bundler -v 1.17.3

# Install Passenger and last supported `rack` version
RUN source /usr/local/rvm/scripts/rvm && \
    gem install rack -v 2.1.4.4 && \
    gem install passenger -v 6.0.22

# Install Nginx
RUN source /usr/local/rvm/scripts/rvm && \
    passenger-install-nginx-module --auto --auto-download --prefix=/home/tracker/nginx/

# Change location of tracker software (installed later in the Dockerfile)
RUN cd /home/tracker/nginx/conf && \
    touch nginx.conf.tmp && \
    head -n 43 nginx.conf > nginx.conf.tmp && \
    echo "        location / {" >> nginx.conf.tmp && \
    echo "            root /home/tracker/universal-tracker-public;" >> nginx.conf.tmp && \
    echo "            passenger_enabled on;" >> nginx.conf.tmp && \
    echo "            client_max_body_size 15M;" >> nginx.conf.tmp && \
    echo "        }" >> nginx.conf.tmp && \
    tail -n 71 nginx.conf >> nginx.conf.tmp && \
    rm nginx.conf && \
    mv nginx.conf.tmp nginx.conf && \
    cd /

# Add tracker logrotate config
RUN echo "/home/tracker/nginx/logs/error.log" >> /home/tracker/logrotate.conf && \
    echo "/home/tracker/nginx/logs/access.log {" >> /home/tracker/logrotate.conf && \
    echo "     daily" >> /home/tracker/logrotate.conf && \
    echo "     rotate 10" >> /home/tracker/logrotate.conf && \
    echo "     copytruncate" >> /home/tracker/logrotate.conf && \
    echo "     delaycompress" >> /home/tracker/logrotate.conf && \
    echo "     compress" >> /home/tracker/logrotate.conf && \
    echo "     notifempty" >> /home/tracker/logrotate.conf && \
    echo "     missingok" >> /home/tracker/logrotate.conf && \
    echo "     size 10M" >> /home/tracker/logrotate.conf && \
    echo "}" >> /home/tracker/logrotate.conf

# Add crontab to call logrotate
RUN touch logrotate_cron.txt && \
    echo "@daily /usr/sbin/logrotate --state /home/tracker/.logrotate.state /home/tracker/logrotate.conf" > logrotate_cron.txt && \
    crontab logrotate_cron.txt && \
    rm logrotate_cron.txt

# Log out of tracker account
RUN su root

# Create Upstart configuration file for Nginx
# This isn't used but it's not harmful to add either
RUN echo "description \"nginx http daemon\"" > /etc/init/nginx-tracker.conf && \
    echo "" >> /etc/init/nginx-tracker.conf && \
    echo "start on runlevel [2]" >> /etc/init/nginx-tracker.conf && \
    echo "stop on runlevel [016]" >> /etc/init/nginx-tracker.conf && \
    echo "" >> /etc/init/nginx-tracker.conf && \
    echo "setuid tracker" >> /etc/init/nginx-tracker.conf && \
    echo "setgid tracker" >> /etc/init/nginx-tracker.conf && \
    echo "" >> /etc/init/nginx-tracker.conf && \
    echo "console output" >> /etc/init/nginx-tracker.conf && \
    echo "" >> /etc/init/nginx-tracker.conf && \
    echo "exec /home/tracker/nginx/sbin/nginx -c /home/tracker/nginx/conf/nginx.conf -g \"daemon off;\"" >> /etc/init/nginx-tracker.conf

# Download tracker software
RUN su tracker && \
    git clone https://github.com/ArchiveTeam/universal-tracker.git && \
    cp universal-tracker/config/redis.json.example universal-tracker/config/redis.json && \
    touch universal-tracker/config/redis.json.tmp && \
    head -n 10 universal-tracker/config/redis.json >> universal-tracker/config/redis.json.tmp && \
    echo "  }," >> universal-tracker/config/redis.json.tmp && \
    echo "  \"production\": {" >> universal-tracker/config/redis.json.tmp && \
    echo "    \"host\":\"redis\"," >> universal-tracker/config/redis.json.tmp && \
    echo "    \"port\":6379," >> universal-tracker/config/redis.json.tmp && \
    echo "    \"db\": 1" >> universal-tracker/config/redis.json.tmp && \
    echo "  }" >> universal-tracker/config/redis.json.tmp && \
    echo "}" >> universal-tracker/config/redis.json.tmp && \
    sed -i -e 's/127.0.0.1/redis/g' universal-tracker/config/redis.json.tmp && \
    rm universal-tracker/config/redis.json && \
    mv universal-tracker/config/redis.json.tmp universal-tracker/config/redis.json

# Log out of tracker account
RUN su root

# Install necessary gems
RUN source /usr/local/rvm/scripts/rvm && \
    cd universal-tracker && \
    bundle install --binstubs --force

##
## Self
##

# All `RUN` commands below are not in the ArchiveTeam
# tracker documentation, they were manually added by me

# Clean up after installation of tracker
RUN apt remove -y wget curl make gcc g++ pkg-config git libcurl4-openssl-dev && \
    apt-get clean -y && \
    apt-get autoremove -y && \
    rm -rf /var/apt/lists/*

RUN cd universal-tracker/
WORKDIR universal-tracker/

CMD [ "bash", "-lc", "bin/bundle exec rackup --port 80 --host 0.0.0.0" ]
