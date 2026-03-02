FROM nginx:alpine
# Copy the static HTML to Nginx's default public folder
COPY index.html /usr/share/nginx/html/index.html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80