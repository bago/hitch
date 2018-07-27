#!/bin/sh

. hitch_test.sh

cat >$PWD/hitch29.cfg <<EOF
frontend = {
       host = "localhost"
       port = "$LISTENPORT"

       pem-file = "${CERTSDIR}/wildcard.example.com"
       pem-file = "${CERTSDIR}/default.example.com"
       pem-file = "${CERTSDIR}/site1.example.net"
       pem-file = "${CERTSDIR}/site1.example.com"
       pem-file = "${CERTSDIR}/site2.example.com"
}

backend = "[hitch-tls.org]:80"
EOF

# XXX: reload doesn't work with a relative config file
start_hitch --config=$PWD/hitch29.cfg

s_client >s_client1.dump

#cat s_client1.dump

grep -q "CN=\*.example.com" s_client1.dump

s_client -servername site1.example.net | tee s_client2.dump

#cat s_client2.dump

grep -q "CN=site1.example.net" s_client2.dump

s_client -servername unknown.example.net | tee s_client3.dump

#cat s_client2.dump

grep -q "CN=\*.example.com" s_client3.dump

#echo "hitch.log"
#cat hitch.log

# Add a new cert and restart

cat >$PWD/hitch29.cfg <<EOF
frontend = {
       host = "localhost"
       port = "$LISTENPORT"

       pem-file = "${CERTSDIR}/wildcard.example.com"
       pem-file = "${CERTSDIR}/default.example.com"
       pem-file = "${CERTSDIR}/site1.example.net"
       pem-file = "${CERTSDIR}/site1.example.com"
       pem-file = "${CERTSDIR}/site2.example.com"
       pem-file = "${CERTSDIR}/site3.example.com"
}

backend = "[hitch-tls.org]:80"
EOF

echo "kill -HUP $(hitch_pid)"
kill -HUP $(hitch_pid)
sleep 2

# restart hitch after removing one cert
cat >$PWD/hitch29.cfg <<EOF
frontend = {
       host = "localhost"
       port = "$LISTENPORT"

       pem-file = "${CERTSDIR}/wildcard.example.com"
       pem-file = "${CERTSDIR}/default.example.com"
       pem-file = "${CERTSDIR}/site3.example.com"
       pem-file = "${CERTSDIR}/site2.example.com"
}

backend = "[hitch-tls.org]:80"
EOF

echo "kill -HUP $(hitch_pid)"
kill -HUP $(hitch_pid)
sleep 2

s_client | tee s_client4.dump

cat s_client4.dump

grep -q "CN=\*.example.com" s_client4.dump

# site1 has been removed, should now match the wildcard
s_client -servername site1.example.net | tee s_client5.dump

cat s_client5.dump

grep -q "CN=\*.example.com" s_client5.dump

s_client -servername unknown.example.net | tee s_client6.dump

cat s_client6.dump

grep -q "CN=\*.example.com" s_client6.dump

