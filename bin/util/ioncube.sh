#!/usr/bin/env bash

install_ext() {
    local ext=$1
    local reason=${2:-}
    local custom_url=${3:-}
    local ext_ini="$BP_DIR/conf/php/conf.d/ext-$ext.ini"
    local ext_so=
    local ext_dir=$(basename $(php-config --extension-dir))
    if [[ -f "$ext_ini" ]]; then
        ext_so=$(php -r '$ini=parse_ini_file("'$ext_ini'"); echo $ext=$ini["zend_extension"]?$ini["extension"]; exit((int)empty($ext));')
        if [[ ! -f "$PHP_EXT_DIR/$ext_so" ]]; then
            if [[ "$custom_url" ]]; then
                curl --silent --location "${S3_URL}/extensions/${ext_dir}/${ext}.tar.gz" | tar xz -C $BUILD_DIR/.heroku/php
            else
                curl --silent --location "$custom_url" | tar xz -C $BUILD_DIR/.heroku/php
            fi
            echo "- ${ext} (${reason}; downloaded)" | indent
        else
            echo "- ${ext} (${reason}; bundled)" | indent
        fi
        cp "${ext_ini}" "${BUILD_DIR}/.heroku/php/etc/php/conf.d"
    elif [[ -f "${PHP_EXT_DIR}/${ext}.so" ]]; then
        echo "extension = ${ext}.so" > "${BUILD_DIR}/.heroku/php/etc/php/conf.d/ext-${ext}.ini"
        echo "- ${ext} (${reason}; bundled)" | indent
    elif echo -n ${ext} | php -r 'exit((int)!extension_loaded(file_get_contents("php://stdin")));'; then
        : # echo "- ${ext} (${reason}; enabled by default)" | indent
    else
        warning_inline "Unknown extension ${ext} (${reason}), install may fail!"
    fi
}

install_ioncube_ext() {
    if [[ ( ${#exts[@]} -eq 0 || ! ${exts[*]} =~ "ioncube" ) ]]; then
        install_ext "ioncub" "automatic" "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
        exts+=("ioncube")
        ln -s $PHP_EXT_DIR/ioncube_loader_lin_${PHP_VERSION%.*}.so $PHP_EXT_DIR/ioncube.so
    fi
}
