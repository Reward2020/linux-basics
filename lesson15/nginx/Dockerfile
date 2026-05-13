# Format: FROM    repository[:version]
FROM med/centos7


ARG DOCKER_HOST_URL=192.168.99.100
ENV DOCKER_HOST_URL=$DOCKER_HOST_URL

WORKDIR /

RUN yum install -y initscripts  # for old "service"
ENV container=docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# named (dns server) service
RUN yum install -y bind bind-utils
RUN systemctl enable named.service

# webserver service
RUN yum install -y nginx
RUN systemctl enable nginx.service

# Without this, init won't start the enabled services and exec'ing and starting
# them reports "Failed to get D-Bus connection: Operation not permitted".
VOLUME /run /tmp

RUN mkdir -p /opt/bundled-payments-app

ADD app /opt/bundled-payments-app/app/
ADD tests /opt/bundled-payments-app/tests/
ADD assets /opt/bundled-payments-app/assets/
ADD *.json /opt/bundled-payments-app/
ADD *.js /opt/bundled-payments-app/

WORKDIR /opt/bundled-payments-app

RUN sed -i -- 's/bower install/'""'/g' package.json

# CSS MIN must be upgraded in package.json... after that is done remove this line.
RUN sed -i -- 's/0.14.0/'"1.0.2"'/g' package.json

RUN npm install
RUN bower install --allow-root
RUN npm install typings --global
RUN typings install


# Bake the correct URLS into the image based on development machine environment variables. These lines can be dropped from the Dockerfile after these config files are designed to work with linux environment variables. 
# the string 'localhost' is used as both KEY and VALUE in  gruntfile.js. This creates some interesting challenges when trying to do solid search and replace logic using sed.
# Ultimately any javascript file can be written to abstract these references through linux env variables for a cleaner approach. Much harder to do that if the URLs are in JSON files though.
RUN sed -i -- 's/localhost/'"$DOCKER_HOST_URL"'/g' *.js
RUN sed -i -- 's/8887/'"templocalport"'/' *.js
RUN sed -i -- 's/8887/'"80"'/g' *.js
RUN sed -i -- 's/8888/'"80"'/g' *.js
RUN sed -i -- 's/8080/'"80"'/g' *.js
RUN sed -i -- 's/templocalport/'"8887"'/' *.js



WORKDIR /opt/bundled-payments-app

RUN grunt buildDev
RUN cp -a ./dist/. /usr/share/nginx/html/

EXPOSE 80

ENTRYPOINT ["/usr/sbin/init"]
