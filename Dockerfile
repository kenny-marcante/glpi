FROM php:7.4-apache


LABEL summary="Imagem php-apache do GLPI" \
      io.k8s.description="GLPI é uma ferramenta de Administracao e servicedesk. Você pode usá-lo para construir um banco de dados com um inventário para sua empresa (computador, software, impressoras ...). Ele tem funções aprimoradas para tornar a vida diária para os administradores mais fácil, como um sistema de rastreamento de trabalho com notificação por e-mail e métodos para construir um banco de dados com informações básicas sobre sua topologia de rede " \
      name="Kllmkll/glpi" \
      version="9.5.5" \
      maintainer="Kenny Marcante <kenny.marcante@accesscontact.com.br>"

# Download do GLPI e seu permissionamento
WORKDIR /temp

RUN apt update --yes && apt upgrade --yes

RUN apt install wget --yes \
    && wget https://github.com/glpi-project/glpi/releases/download/9.5.5/glpi-9.5.5.tgz \
    && tar -xvzf glpi-9.5.5.tgz && cp -Rf glpi /var/www/html

WORKDIR /var/www/html

RUN chmod 775 /var/www/html/* -Rf \
    && chown www-data. /var/www/html/* -Rf

# Inclusao do .conf
COPY ./glpi.conf /etc/apache2/conf-available/glpi.conf
RUN a2enconf glpi.conf \
    && service apache2 restart
COPY ./docker-php-ext-glpiajust.ini /usr/local/etc/php/conf.d

# Inicio das Extencoes
ENV EXT_APCU_VERSION=5.1.17

RUN chmod +x /usr/local/bin/*

#APCU
RUN docker-php-source extract \
    && mkdir -p /usr/src/php/ext/apcu \
    && curl -fsSL https://github.com/krakjoe/apcu/archive/v$EXT_APCU_VERSION.tar.gz | tar xvz -C /usr/src/php/ext/apcu --strip 1 \
    && docker-php-ext-install apcu \
    && docker-php-source delete

#Instalacao das libs
RUN apt install --yes curl libcurl3-dev \
    libc-client-dev libkrb5-dev openssl \
    libxml2-dev libldb-dev libfreetype6-dev \
    libldap2-dev libsnmp-dev expat \
    libsqlite3-dev libpng-dev libonig-dev  \
    libzip-dev libbz2-dev libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

#Instalacao e ativacao das extencoes
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
	&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
	&& docker-php-ext-configure opcache \
	&& docker-php-ext-configure xmlrpc 

RUN docker-php-ext-install gd ldap mysqli imap \
    opcache xmlrpc intl exif zip bz2

COPY ./cas.tgz /var/www/html/
RUN pear install cas.tgz

USER root

#Liberacao de portas
EXPOSE 80 443 