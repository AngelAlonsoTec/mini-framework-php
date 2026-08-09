FROM php:8.2-apache

RUN a2enmod rewrite

# Instalar dependencias del sistema requeridas para ciertas extensiones (como GD)
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Instalar extensiones de base de datos (PDO y PDO MySQL)
RUN docker-php-ext-install pdo pdo_mysql

# Servir el proyecto desde /public como hacen la mayoría de apps PHP
RUN sed -ri 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf /etc/apache2/apache2.conf


# Reescritura directa en Apache para evitar depender de .htaccess en el volumen montado
RUN printf '%s\n' '<Directory /var/www/html/public>' '    Require all granted' '    RewriteEngine On' '    RewriteCond %{REQUEST_FILENAME} !-f' '    RewriteCond %{REQUEST_FILENAME} !-d' '    RewriteRule ^ index.php [L]' '</Directory>' > /etc/apache2/conf-available/public-rewrite.conf \
    && a2enconf public-rewrite

# 1. Copia los archivos de tu proyecto al directorio por defecto de Apache
COPY ./src /var/www/html