#!/usr/bin/env bash

configurar_extensoes_php() {
    info "Compilando extensões PHP (sqlsrv)..."
    pecl install sqlsrv pdo_sqlsrv </dev/null

    if [[ "$PKG_MGR" == "dnf" ]]; then
        echo "extension=sqlsrv.so" > /etc/php.d/20-sqlsrv.ini
        echo "extension=pdo_sqlsrv.so" > /etc/php.d/20-pdo_sqlsrv.ini
    else
        PHP_V=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
        printf "; priority=20\nextension=sqlsrv.so\n" > "/etc/php/$PHP_V/mods-available/sqlsrv.ini"
        printf "; priority=20\nextension=pdo_sqlsrv.so\n" > "/etc/php/$PHP_V/mods-available/pdo_sqlsrv.ini"
        phpenmod sqlsrv pdo_sqlsrv
    fi
    sucesso "Extensões PHP configuradas."
}

registrar_modulo "php_extensoes" "Extensões PHP (SQL Server)" \
    "Compila e habilita sqlsrv/pdo_sqlsrv via PECL" \
    "configurar_extensoes_php"
