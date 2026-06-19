FROM nginx:1.31.2-alpine

COPY default.conf /etc/nginx/conf.d/
COPY html /usr/share/nginx/html
