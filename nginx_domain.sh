#!/bin/bash

# Info
# ---
# script can run with the domain as a command line input
# `sudo ./nginx_domain.sh my_domain.com` or without and
# the script will prompt the user for input

#config
web_root='/var/www'
config_dir='/etc/nginx'

if [ -z "$1" ]
then

        #user input
        echo -e "Enter domain name:"
        read DOMAIN
        echo "Creating Nginx domain settings for: $DOMAIN"

        if [ -z "$DOMAIN" ]
        then
                echo "Domain required"
                exit 1
        fi
fi

if [ -z "$DOMAIN" ]
then
        DOMAIN=$1
fi

(
cat <<EOF
server {
        listen   80; ## listen for ipv4; this line is default and implied
        #listen   [::]:80 default_server ipv6only=on; ## listen for ipv6

        root $web_root/$DOMAIN/public;
        index index.php  index.html index.htm;

        # Make site accessible from http://localhost/
        server_name $DOMAIN www.$DOMAIN;

        charset utf-8;

        location / {try_files $uri $uri/ /index.html /index.php?\$query_string;}

        location ~ \.php$ {
                try_files \$uri =404;

                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini

                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
                include fastcgi.conf;
                fastcgi_param HTTPS off;
        }
        location ~ /\.ht {
                deny all;
        }
            access_log /var/log/nginx/$DOMAIN/access_log;
            error_log /var/log/nginx/$DOMAIN/error_log.txt error;
}
EOF
) >  $config_dir/sites-available/$DOMAIN.conf

echo "Making web directories"
mkdir -p $web_root/"$DOMAIN"
mkdir -p $web_root/"$DOMAIN"/{public,private,log,backup}
ln -s $config_dir/sites-available/"$DOMAIN".conf $config_dir/sites-enabled/"$DOMAIN".conf
service nginx reload
echo "Nginx - reload"
chown -R www-data:www-data $web_root/"$DOMAIN"
chmod 755 $web_root/"$DOMAIN"/public
echo "Permissions have been set"
echo "$DOMAIN has been setup"
