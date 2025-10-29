FROM nginx:1.29.3-alpine

COPY default.conf /etc/nginx/conf.d/
COPY html /usr/share/nginx/html
