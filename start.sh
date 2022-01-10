#!/bin/sh

# configs
AUUID=24b4b1e1-7a89-45f6-858c-242cf53b5bdb
CADDYIndexPage=https://ja.xjqxz.top/myrailwayweb.zip
CONFIGCADDY=https://raw.githubusercontent.com/netcyabc/rwweb2/main/etc/Caddyfile
#CONFIGCADDY=https://raw.githubusercontent.com/Lbingyi/HerokuXray/master/etc/Caddyfile
CONFIGXRAY=https://raw.githubusercontent.com/Lbingyi/HerokuXray/master/etc/xray.json
ParameterSSENCYPT=chacha20-ietf-poly1305
StoreFiles=https://raw.githubusercontent.com/netcyabc/rwweb2/main/etc/StoreFiles
#StoreFiles=https://raw.githubusercontent.com/Lbingyi/HerokuXray/master/etc/StoreFiles
#PORT=4433
mkdir -p /etc/caddy/ /usr/share/caddy && echo -e "User-agent: *\nDisallow: /" >/usr/share/caddy/robots.txt
wget $CADDYIndexPage -O /usr/share/caddy/index.html && unzip -qo /usr/share/caddy/index.html -d /usr/share/caddy/ && mv /usr/share/caddy/*/* /usr/share/caddy/
wget -qO- $CONFIGCADDY | sed -e "1c :$PORT" -e "s/\$AUUID/$AUUID/g" -e "s/\$MYUUID-HASH/$(caddy hash-password --plaintext $AUUID)/g" >/etc/caddy/Caddyfile
wget -qO- $CONFIGXRAY | sed -e "s/\$AUUID/$AUUID/g" -e "s/\$ParameterSSENCYPT/$ParameterSSENCYPT/g" >/xray.json

# storefiles
mkdir -p /usr/share/caddy/$AUUID && wget -O /usr/share/caddy/$AUUID/StoreFiles $StoreFiles
#wget -P /usr/share/caddy/$AUUID -i /usr/share/caddy/$AUUID/StoreFiles

for file in $(ls /usr/share/caddy/$AUUID); do
    [[ "$file" != "StoreFiles" ]] && echo \<a href=\""$file"\" download\>$file\<\/a\>\<br\> >>/usr/share/caddy/$AUUID/ClickToDownloadStoreFiles.html
done

# start
tor &
echo --tor-----xray--
/xray -config /xray.json &
echo -----sshd
/usr/sbin/sshd &
echo -----wstunnel
wstunnel -s 0.0.0.0:8989 &
echo -----caddy
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
