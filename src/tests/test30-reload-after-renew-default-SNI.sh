#!/bin/sh

. hitch_test.sh

cp ${CERTSDIR}/site1.example.net $PWD/site1.cert

cat >$PWD/hitch30.cfg <<EOF
backend = "[hitch-tls.org]:80"
pem-file = ""
sni-nomatch-abort = off
workers = 1
backlog = 100
keepalive = 3600

frontend = {
       host = "localhost"
       port = "12345"

       pem-file = "${CERTSDIR}/wildcard.example.com"
}


frontend = {
       host = "localhost"
       port = "$LISTENPORT"

       pem-file = "${CERTSDIR}/wildcard.example.com"
       pem-file = "${CERTSDIR}/default.example.com"
       pem-file = "${PWD}/site1.cert"
       pem-file = "${CERTSDIR}/site1.example.com"
       pem-file = "${CERTSDIR}/site2.example.com"
}

EOF

# XXX: reload doesn't work with a relative config file
start_hitch --config=$PWD/hitch30.cfg

s_client -connect localhost:$LISTENPORT >s_client1.dump

#cat s_client1.dump

grep -q "CN=\*.example.com" s_client1.dump

s_client -servername site1.example.net -connect localhost:$LISTENPORT | tee s_client2.dump

cat s_client2.dump

grep -q "CN=site1.example.net" s_client2.dump
grep -q 'TH5FUsG+30DBskCpAbmSCoYD82x1bBfz7M3jrNJP46pgOZWCgCrxVfvKS9A+VB0x' s_client2.dump

s_client -servername unknown.example.net -connect localhost:$LISTENPORT | tee s_client3.dump

#cat s_client2.dump

grep -q "CN=\*.example.com" s_client3.dump

#echo "hitch.log"
#cat hitch.log

cp ${CERTSDIR}/site1.example.net.renew $PWD/site1.cert

echo "kill -HUP $(hitch_pid)"
kill -HUP $(hitch_pid)
sleep 2

s_client -connect localhost:$LISTENPORT | tee s_client4.dump

#cat s_client4.dump

grep -q "CN=\*.example.com" s_client4.dump

# site1 has been removed, should now match the wildcard
s_client -servername site1.example.net -connect localhost:$LISTENPORT | tee s_client5.dump

cat s_client5.dump

grep -q "CN=site1.example.net" s_client5.dump
grep -q 'R1FMr7ebQQ1wJD1dyo95JA4YLpT1aT9hv0p3uaWxQOY6IwUJPm+mhWmbrURe7GW/' s_client5.dump

s_client -servername unknown.example.net -connect localhost:$LISTENPORT | tee s_client6.dump

#cat s_client6.dump

grep -q "CN=\*.example.com" s_client6.dump

