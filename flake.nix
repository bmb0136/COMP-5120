{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {pkgs, ...}: let
        php = pkgs.php83.buildEnv {
          extensions = {
            enabled,
            all,
          }:
            enabled
            ++ (with all; [
              bz2
              calendar
              ctype
              curl
              dba
              dom
              exif
              fileinfo
              filter
              ftp
              gd
              gettext
              gmp
              iconv
              mbstring
              mysqli
              mysqlnd
              openssl
              pdo_mysql
              pdo_odbc
              pdo_sqlite
              pdo_sqlsrv
              posix
              session
              shmop
              soap
              sockets
              sodium
              sqlite3
              sqlsrv
              sysvmsg
              sysvsem
              sysvshm
              tokenizer
              xml
              xmlreader
              xmlwriter
              xsl
              zip
              zlib
            ]);
        };
        mysql = pkgs.mysql84;
      in {
        packages.default = pkgs.writeShellApplication {
          name = "db-project";
          runtimeInputs = [php mysql];
          text = ''
            TMP=$(mktemp -d)

            mkdir "$TMP/www"
            cp -r ${./src}/* "$TMP/www/"
            cd "$TMP/www"
            php -S localhost:8080 &
            WS=$!

            mkdir "$TMP/db"
            mkdir "$TMP/db_tmp"
            cd "$TMP"
            export MYSQL_USER=bmb0136
            export MYSQL_PASSWORD=secret
            mysqld -h "$TMP/db" -t "$TMP/db_tmp" --socket "$TMP/db.sock" --initialize-insecure --port 3307
            mysqld -h "$TMP/db" -t "$TMP/db_tmp" --socket "$TMP/db.sock" --port 3307 &
            DB=$!

            read -r
            kill -9 $WS $DB

            rm -rf "$TMP"
          '';
        };
        devShells.default = pkgs.mkShell {
          packages = [php mysql];
        };
      };
    };
}
