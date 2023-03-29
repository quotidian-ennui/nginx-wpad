FROM nginx:1.23.4-alpine

COPY default.conf /etc/nginx/conf.d/
COPY html /usr/share/nginx/html
