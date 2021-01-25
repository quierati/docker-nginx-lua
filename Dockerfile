# Based on manual compile instructions at http://wiki.nginx.org/HttpLuaModule#Installation
FROM ubuntu:latest

ENV VER_NGINX_DEVEL_KIT=0.2.19
ENV VER_LUA_NGINX_MODULE=0.9.16
ENV VER_NGINX=1.18.0
ENV VER_LUAJIT=2.0.5

ENV NGINX_DEVEL_KIT ngx_devel_kit-${VER_NGINX_DEVEL_KIT}
ENV LUA_NGINX_MODULE lua-nginx-module-${VER_LUA_NGINX_MODULE}

ENV NGINX_ROOT=/usr/share/nginx
ENV NGINX_CONF=/etc/nginx/nginx.conf
ENV NGINX_MODULES=/usr/lib/nginx/modules
ENV WEB_DIR /var/www/html

ENV LUAJIT_LIB /usr/local/lib
ENV LUAJIT_INC /usr/local/include/luajit-2.0

RUN apt-get -qq update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends wget make gcc ca-certificates tzdata bash \
# Nginx dependencies
        libpcre3 \
	libpcre3-dev \
	zlib1g-dev \
	libssl-dev \
# Nginx webp dependencies 
	libwebp-dev \
	webp \
	libgd-dev 

# Download
RUN wget http://nginx.org/download/nginx-${VER_NGINX}.tar.gz \
&& wget http://luajit.org/download/LuaJIT-${VER_LUAJIT}.tar.gz \
&& wget https://github.com/simpl/ngx_devel_kit/archive/v${VER_NGINX_DEVEL_KIT}.tar.gz -O ${NGINX_DEVEL_KIT}.tar.gz \
&& wget https://github.com/openresty/lua-nginx-module/archive/v${VER_LUA_NGINX_MODULE}.tar.gz -O ${LUA_NGINX_MODULE}.tar.gz

# Untar
RUN tar -xzvf nginx-${VER_NGINX}.tar.gz && rm nginx-${VER_NGINX}.tar.gz \
	&& tar -xzvf LuaJIT-${VER_LUAJIT}.tar.gz && rm LuaJIT-${VER_LUAJIT}.tar.gz \
	&& tar -xzvf ${NGINX_DEVEL_KIT}.tar.gz && rm ${NGINX_DEVEL_KIT}.tar.gz \
	&& tar -xzvf ${LUA_NGINX_MODULE}.tar.gz && rm ${LUA_NGINX_MODULE}.tar.gz


# LuaJIT
WORKDIR /LuaJIT-${VER_LUAJIT}
RUN make && make install

# Nginx with LuaJIT
WORKDIR /nginx-${VER_NGINX}
RUN ./configure --prefix=${NGINX_ROOT} --conf-path=${NGINX_CONF} --modules-path=${NGINX_MODULES} --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" --add-module=/${NGINX_DEVEL_KIT} --add-module=/${LUA_NGINX_MODULE} --with-http_image_filter_module=dynamic 
RUN make -j2 && make install && ln -s ${NGINX_ROOT}/sbin/nginx /usr/local/sbin/nginx

# ***** MISC *****
WORKDIR ${WEB_DIR}
EXPOSE 80
EXPOSE 443

# ***** CLEANUP *****
RUN rm -rf /nginx-${VER_NGINX}
RUN rm -rf /LuaJIT-${VER_LUAJIT}
RUN rm -rf /${NGINX_DEVEL_KIT}
RUN rm -rf /${LUA_NGINX_MODULE}
# TODO: Uninstall build only dependencies?
# TODO: Remove env vars used only for build?

CMD ["nginx", "-g", "daemon off;"]
