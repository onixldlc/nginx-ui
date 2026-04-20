FROM node:23-alpine3.21 AS frontend-builder
WORKDIR /app
COPY ./app /app

RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk upgrade --update

RUN corepack enable pnpm \
 && corepack prepare pnpm@10.7.1 --activate

RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile \
 && pnpm run build






 

FROM golang:1.24-alpine3.21 AS backend-builder
WORKDIR /nginx-ui
COPY . /nginx-ui
COPY --from=frontend-builder /app/dist /nginx-ui/app/dist

RUN --mount=type=cache,target=/var/cache/apk \
    apk update && apk upgrade --update

RUN apk add --no-cache git gcc g++ make

ENV CGO_ENABLED=1

RUN go generate
RUN go build \
    -work -tags=jsoniter \
    -ldflags "$LD_FLAGS -X 'github.com/0xJacky/Nginx-UI/settings.buildTime=0'" \
    -o /build/nginx-ui -v main.go


FROM alpine:3.21
COPY --from=backend-builder /build/nginx-ui /bin/nginx-ui