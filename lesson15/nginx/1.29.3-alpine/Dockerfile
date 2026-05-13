FROM nginx:1.29.3-alpine

COPY ./nginx.conf /etc/nginx/nginx.conf

RUN chown -R nginx:nginx /etc/nginx/conf.d && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    mkdir -p /run/nginx && \
    chown -R nginx:nginx /run/nginx

USER nginx

CMD ["nginx", "-g", "daemon off;"]
