#!/usr/bin/env bash

install_ext() {
    local ext=$1
    local reason=${2:-}
    local custom_url=${3:-}
    local ext_ini="$bp_dir/conf/php/conf.d/ext-$ext.ini"
    local ext_so=
    export ext_dir=$(basename $(php-config --extension-dir))
    if [[ -f "$ext_ini" ]]; then
        ext_so=$(php -r '$ini=parse_ini_file("'$ext_ini'"); echo $ext=$ini["zend_extension"]?$ini["extension"]; exit((int)empty($ext));')
        if [[ ! -f "${ext_dir}/${ext_so}" ]]; then
            if [[ -z "$custom_url" ]]; then
                curl --silent --location "${S3_URL}/extensions/${ext_dir}/${ext}.tar.gz" | tar xz -C $BUILD_DIR/.heroku/php
            else
                curl --silent --location "$custom_url" | tar xz -C $BUILD_DIR/.heroku/php
            fi
            echo "- ${ext} (${reason}; downloaded)" | indent
        else
            echo "- ${ext} (${reason}; bundled)" | indent
        fi
        cp "${ext_ini}" "${BUILD_DIR}/.heroku/php/etc/php/conf.d"
    elif [[ -f "${ext_dir}/${ext}.so" ]]; then
        echo "extension = ${ext}.so" > "${BUILD_DIR}/.heroku/php/etc/php/conf.d/ext-${ext}.ini"
        echo "- ${ext} (${reason}; bundled)" | indent
    elif echo -n ${ext} | php -r 'exit((int)!extension_loaded(file_get_contents("php://stdin")));'; then
        : # echo "- ${ext} (${reason}; enabled by default)" | indent
    else
        warning_inline "Unknown extension ${ext} (${reason}), install may fail!"
    fi
}

install_ioncube_ext() {
    local PHP_VERSION=$(php -r "echo explode('.', PHP_VERSION)[0] . '.' . explode('.', PHP_VERSION)[1];")
    install_ext "ioncube" "automatic" "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
    ln -s $ext_dir/ioncube_loader_lin_${PHP_VERSION}.so $ext_dir/ioncube.so
}
