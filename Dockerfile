FROM node:23-alpine3.22 AS frontend-builder
WORKDIR /workspace

RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk upgrade --update

RUN corepack enable pnpm \
 && corepack prepare pnpm@10.33.0 --activate

COPY package.json pnpm-workspace.yaml pnpm-lock.yaml /workspace/
COPY app /workspace/app
COPY docs /workspace/docs

RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile \
 && pnpm --filter nginx-ui-app-next run build


FROM golang:1.26-alpine3.22 AS backend-builder
WORKDIR /nginx-ui
COPY . /nginx-ui
COPY --from=frontend-builder /workspace/app/dist /nginx-ui/app/dist

RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk upgrade --update

RUN apk add --no-cache git gcc g++ make

ENV CGO_ENABLED=1

RUN mkdir -p /build
RUN go generate ./...
RUN go build \
    -tags=jsoniter \
    -ldflags "-X 'github.com/0xJacky/Nginx-UI/settings.buildTime=0'" \
    -o /build/nginx-ui -v main.go


FROM nginx:alpine3.22 AS runner
COPY --from=backend-builder /build/nginx-ui /usr/local/bin/nginx-ui
COPY ./nginx_ui-entrypoint.sh /nginx_ui-entrypoint.sh

COPY resources/docker/nginx.conf /usr/local/etc/nginx/nginx.conf
COPY resources/docker/nginx-ui.conf /usr/local/etc/nginx/conf.d/nginx-ui.conf

RUN chmod +x /nginx_ui-entrypoint.sh

RUN mkdir -p /etc/nginx/sites-enabled \
             /etc/nginx/sites-available \
             /etc/nginx/streams-enabled \
             /etc/nginx/streams-available

RUN cp -r /etc/nginx/ /etc/nginx-default/

RUN rm -f /var/log/nginx/access.log && \
    touch /var/log/nginx/access.log && \
    rm -f /var/log/nginx/error.log && \
    touch /var/log/nginx/error.log

WORKDIR /etc/nginx-ui

ENTRYPOINT ["/nginx_ui-entrypoint.sh"]
