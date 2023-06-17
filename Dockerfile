# === Base Image ===
# 注意此處的 AS
FROM ruby:2.5.9-slim AS passenger_ruby
MAINTAINER white <a500667337@gmail.com>

# Default Environment
# 在這邊設定 相關軟體的版本
ENV NGINX_VERSION 1.12.2
ENV PASSENGER_VERSION 6.0.2
RUN apt-get update && apt-get install -y gnupg2
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
RUN apt-get update && apt-get install -y libmariadbclient-dev libmariadb3  default-libmysqlclient-dev curl apt-transport-https wget


# シェルスクリプトとしてbashを利用
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
# # yarnパッケージ管理ツールインストール
# RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 648ACFD622F3D138 0E98404D386FA1D9 DCC9EFBF77E11517
# RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 112695A0E562B32A 54404762BBB6E853

# # # # Node.jsをインストール
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y nodejs 

# # # # 中文字型
RUN apt-get install -y xfonts-wqy ttf-wqy-zenhei fonts-arphic-ukai build-essential
# # # # 以指定的安裝 Passenger Gem
RUN gem install passenger -v $PASSENGER_VERSION
# # # 指定 Passenger 編譯 Nginx Extension
# # # 在這邊使用 passenger-config about root 取得 Passenger 的 root 目錄
RUN apt-get install -y libcurl4-openssl-dev libpcre3-dev
RUN cd `passenger-config about root` && rake nginx
# # # 以前述變數指定版本 Checkout Nginx Source Code
RUN cd /tmp && wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && tar -zxvf nginx-$NGINX_VERSION.tar.gz
# # 編譯 Nginx 並加入 Passenger 與 upload module extension
RUN cd /tmp/nginx-$NGINX_VERSION && ./configure --with-http_v2_module --with-http_ssl_module --add-module="`passenger-config about root`/src/nginx_module" --with-http_gzip_static_module --with-cc-opt="-Wno-error" && make && make install

# === Rails Application ===
# 使用 multi-stage 方式
# From 剛才的 AS
FROM passenger_ruby

# 重要！
ENV LC_ALL C.UTF-8
# 指定時區，否則會用 GMT
ENV TZ Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# 設定一個程式起始的目錄
ENV APP_HOME /usr/src/app
RUN mkdir -p $APP_HOME

ENV RAILS_ENV production
ENV RAKE_ENV production
ENV BUNDLE_JOBS=30