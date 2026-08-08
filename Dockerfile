FROM php:8.2-apache

# Instalar dependencias del sistema requeridas para ciertas extensiones (como GD)
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Instalar extensiones de base de datos (PDO y PDO MySQL)
RUN docker-php-ext-install pdo pdo_mysql

# 1. Copia los archivos de tu proyecto al directorio por defecto de Apache
COPY ./src /var/www/html

# 2. Cambia el propietario de los archivos al usuario de Apache (www-data)
RUN chown -R www-data:www-data /var/www/html