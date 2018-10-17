#/bin/bash
#此脚本用于找回kubeadm join命令

token=$(kubeadm token list |grep -v "TOKEN"|awk '{print $1}')
cert=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')

echo "kubeadm join --token $token --discovery-token-ca-cert-hash sha256:$cert 192.168.9.230:6443"