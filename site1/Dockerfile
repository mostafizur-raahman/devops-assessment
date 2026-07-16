FROM nginx:1.31.3-alpine-slim

RUN rm -rf /usr/share/nginx/html/*

COPY . /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ >/dev/null 2>&1 || exit 1

EXPOSE 80