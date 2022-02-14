FROM ezsystems/php:7.4-dev

ENV COMPOSER_HOME=~/.composer
RUN composer self-update
RUN chown 1000:1000 /usr/local/bin/composer

RUN cat /usr/local/etc/php/conf.d/php.ini >> /usr/local/etc/php/php.ini \
    && rm /usr/local/etc/php/conf.d/php.ini
RUN cp /usr/local/etc/php/php.ini /usr/local/etc/php/php-cli.ini \
    && echo 'memory_limit = -1' >> /usr/local/etc/php/php-cli.ini \
    && echo 'max_execution_time = -1' >> /usr/local/etc/php/php-cli.ini

RUN sed -i 's#zend_extension=xdebug.so#;zend_extension=xdebug.so#g' /usr/local/etc/php/conf.d/xdebug.ini
