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
              xmlreader
              xmlwriter
              xsl
              zip
              zlib
            ]);
        };
        mysql = pkgs.mysql84;
        seed-data = pkgs.runCommand "seed-data" {
          nativeBuildInputs = [pkgs.python3];
        } ''
          cp ${./data}/* .
          mkdir -p $out
          cat <<EOF > pre.sql

          CREATE USER 'bmb0136'@'%' IDENTIFIED BY 'secret';
          GRANT ALL PRIVILEGES ON bmb0136db.* TO 'bmb0136'@'%' WITH GRANT OPTION;
          FLUSH PRIVILEGES;


          START TRANSACTION;
          CREATE DATABASE bmb0136db;
          USE bmb0136db;
          EOF

          python3 converter.py Book.csv Customer.csv Employee.csv Order.csv -w Order_Detail.csv Shipper.csv Subject.csv Supplier.csv > data.sql

          cat <<EOF > post.sql
          COMMIT;
          EOF

          cat pre.sql data.sql post.sql > $out/data.sql
        '';
      in {
        packages.default = pkgs.writeShellApplication {
          name = "db-project";
          runtimeInputs = [php mysql];
          text = ''
            TMP=$(mktemp -d)

            mkdir "$TMP/db"
            mkdir "$TMP/db_tmp"
            cd "$TMP"
            mysqld -h "$TMP/db" -t "$TMP/db_tmp" --socket "$TMP/db.sock" --initialize --init-file ${seed-data}/data.sql
            mysqld -h "$TMP/db" -t "$TMP/db_tmp" --socket "$TMP/db.sock" --port 3307 &
            DB=$!

            mkdir "$TMP/www"
            cp -r ${./src}/* "$TMP/www/"
            cd "$TMP/www"
            php -S 0.0.0.0:8080 &
            WS=$!

            read -r
            kill -9 $WS $DB

            rm -rf "$TMP"
          '';
        };
        devShells.default = pkgs.mkShell {
          packages = [php mysql];
        };
        packages.submission = pkgs.stdenv.mkDerivation {
          name = "submission";
          src = ./.;
          nativeBuildInputs = [pkgs.zip];
          buildPhase = ''
            mkdir -p $out
            echo "https://webhome.auburn.edu/~bmb0136/" > url.txt
            cp data/query.txt sql.txt
            zip -r $out/submission.zip url.txt sql.txt src/
          '';
        };
      };
    };
}
