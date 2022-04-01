FROM ubuntu as base

RUN apt-get update -y \
    && apt-get install -y curl git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --uid 1001 app
USER app

ENV NODE_OPTIONS "--max_old_space_size=8192"
ENV NVM_VERSION v0.38.0
ENV NODE_VERSION v12.20.1
ENV NPM_VERSION 7.15.1
ENV NVM_DIR /home/app/.nvm
ENV PATH $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/$NVM_VERSION/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && npm install -g npm@$NPM_VERSION

FROM base AS deps
RUN mkdir /home/app/src
WORKDIR /home/app/src
COPY --chown=app:app package.json package-lock.json ./
RUN npm install

FROM base AS builder
RUN mkdir /home/app/src
WORKDIR /home/app/src
COPY --chown=app:app . .
COPY --from=deps --chown=app:app /home/app/src/node_modules ./node_modules
RUN npm install --production

FROM base AS runner
RUN mkdir /home/app/src
WORKDIR /home/app/src
ENV NODE_ENV production
COPY --from=builder --chown=app:app /home/app/src/public ./public
COPY --from=builder --chown=app:app /home/app/src/.next ./.next
COPY --from=builder --chown=app:app /home/app/src/node_modules ./node_modules
COPY --from=builder --chown=app:app /home/app/src/package.json ./package.json
EXPOSE 3000
CMD npm run start






# we should probably make this a compose file?

# vercel deployment files are included in .gitignore :(