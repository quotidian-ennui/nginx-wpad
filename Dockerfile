FROM nginx:1.26.0-alpine

COPY default.conf /etc/nginx/conf.d/
COPY html /usr/share/nginx/html
