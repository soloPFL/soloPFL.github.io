#! /bin/bash
#User input test script
read -p 'Input a shared secret aka password : ' pwdinput
read -p 'Input you hostname aka realm : ' hostinput
password=$pwdinput
host=$hostinput

echo "listening-port=3478" >> ./testresult1
echo "fingerprint" >> ./testresult1
echo "lt-cred-mech" >> ./testresult1
echo "use-auth-secret" >> ./testresult1
echo "static-auth-secret=$password" >> ./testresult1
echo "realm=$host" >> ./testresult1
echo "no-tls" >> ./testresult1
echo "no-dtls" >> ./testresult1
echo "syslog" >> ./testresult1