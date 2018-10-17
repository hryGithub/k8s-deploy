###  1.服务器信息
    k8s-m   192.168.9.230   centos7
    k8s-n1  192.168.9.231   centos7

###  2.环境初始化
* 2.1 设置主机名称,添加hosts记录
>
    hostnamectl set-hostname k8s-m
    hostnmaectl set-hostname k8s-n1

    cat <<EOF > /etc/hosts
    127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
    ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
    192.168.9.230 k8s-m
    192.168.9.231 k8s-n1
    EOF

* 2.2 防火墙 selinux k8s的yum源
>
    systemctl stop firewalld
    systemctl disable firewalld

    swapoff -a 
    sed -i 's/.*swap.*/#&/' /etc/fstab

    setenforce  0 
    sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux 
    sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config 
    sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux 
    sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config  

    modprobe br_netfilter
    cat <<EOF >  /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    sysctl -p /etc/sysctl.d/k8s.conf
    ls /proc/sys/net/bridge

    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
    EOF

    yum install -y epel-release

    systemctl enable ntpdate.service
    echo '*/30 * * * * /usr/sbin/ntpdate time7.aliyun.com >/dev/null 2>&1' > /tmp/crontab2.tmp
    crontab /tmp/crontab2.tmp
    systemctl start ntpdate.service
    
    echo "* soft nofile 65536" >> /etc/security/limits.conf
    echo "* hard nofile 65536" >> /etc/security/limits.conf
    echo "* soft nproc 65536"  >> /etc/security/limits.conf
    echo "* hard nproc 65536"  >> /etc/security/limits.conf
    echo "* soft  memlock  unlimited"  >> /etc/security/limits.conf
    echo "* hard memlock  unlimited"  >> /etc/security/limits.conf
### 3.安装
>
    master服务器:
    yum  -y install docker-ce kubeadm kubelet kubectl
    systemctl enable docker kubelet
    systemctl start docker 
    节点服务器:
    yum  -y install docker-ce kubeadm kubelet 
    systemctl enable docker kubelet
    systemctl start docker 

### 4.配置
* 4.1 master服务器
>
    #获取k8s images
    sh pill_k8s_images_from_aliyun.sh
    #初始化k8s集群
    kubeadm init --apiserver-advertise-address=192.168.9.230 --pod-network-cidr=10.244.0.0/16
    执行成功以后会生产一个kubeadm -join 的命令
    #
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config

    #安装flannel
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

* 4.2 节点服务器
>
    #获取k8s images
    sh pill_k8s_images_from_aliyun.sh

    #加入集群
    kubeadm join --token odkg67.o602mvwb0q6eese0 --discovery-token-ca-cert-hash sha256:5eaa142249a77b55feed16a0c1a03579c94d4d34f7dd0d455d8b462966f3bcce 192.168.9.230:6443


### 5.遇到的问题
    kubeadm join 命令忘记的话，两种解决办法
    1.重新生成(token过期同法)
        kubeadm token create --print-join-command
    2.找回
        sh forget_kubeadm_join.sh