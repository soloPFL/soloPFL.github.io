#! /bin/bash

read -p 'Input the tar.gz download link from https://github.com/DNSCrypt/dnscrypt-proxy/releases :' input1

dl=input1

wget $dl -P /opt

filename=$(ls dnscrypt* /opt)

tar xzvf /opt/$filename -C /opt

