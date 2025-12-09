FROM node:6

# Expose necessary port
EXPOSE 8080

# https://stackoverflow.com/a/25423366
# Make docker use only `bash` not `sh`
SHELL ["/bin/bash", "-c"]

# Dedicated account to run the broadcaster
RUN adduser --system --group --shell /bin/bash tracker

##
## Node.js
##

# Log into tracker account
RUN su tracker

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

# Edit Node.js program "because it has problems"
# Do NOT add `redis_port` to `env` or `server.js` will error
RUN cp -R universal-tracker/broadcaster . && \
    touch broadcaster/server.js.tmp && \
    head -n 7 broadcaster/server.js > broadcaster/server.js.tmp && \
    echo "var env = {" >> broadcaster/server.js.tmp && \
    echo "    tracker_config: {" >> broadcaster/server.js.tmp && \
    echo "        redis_pubsub_channel: \"tracker-log\"" >> broadcaster/server.js.tmp && \
    echo "    }," >> broadcaster/server.js.tmp && \
    echo "    redis_host: \"redis\"," >> broadcaster/server.js.tmp && \
    echo "    redis_db: \"redis\"," >> broadcaster/server.js.tmp && \
    echo "};" >> broadcaster/server.js.tmp && \
    tail -n 98 broadcaster/server.js >> broadcaster/server.js.tmp && \
    rm broadcaster/server.js && \
    mv broadcaster/server.js.tmp broadcaster/server.js

# Install required Node.js libraries
# Also replace `{package,environment.example}.json` because
# they don't work with the repo out of the box
RUN cd broadcaster/ && \
    rm package.json && \
    curl -fsSL "https://github.com/marked/universal-tracker/raw/refs/heads/docker-redisgem2/broadcaster/environment.json" -o environment.json && \
    curl -fsSL "https://github.com/marked/universal-tracker/raw/refs/heads/docker-redisgem2/broadcaster/package.json" -o package.json && \
    npm install

# Log out of tracker account
RUN su root

# Create an Upstart file for the Node.js tracker
# This isn't used but it's not harmful to add either
RUN touch "/etc/init.d/nodejs-tracker.conf" && \
    echo "description \"tracker nodejs daemon\"" > /etc/init.d/nodejs-tracker.conf && \
    echo "" >> /etc/init.d/nodejs-tracker.conf && \
    echo "start on runlevel [2]" >> /etc/init.d/nodejs-tracker.conf && \
    echo "stop on runlevel [016]" >> /etc/init.d/nodejs-tracker.conf && \
    echo "" >> /etc/init.d/nodejs-tracker.conf && \
    echo "setuid tracker" >> /etc/init.d/nodejs-tracker.conf && \
    echo "setgid tracker" >> /etc/init.d/nodejs-tracker.conf && \
    echo "" >> /etc/init.d/nodejs-tracker.conf && \
    echo "exec node /home/tracker/broadcaster/server.js" >> /etc/init.d/nodejs-tracker.conf

CMD [ "node", "broadcaster/server.js", "environment.json" ]
