#FROM registry.cn-qingdao.aliyuncs.com/x-lab/kvm-base:v1.0.0 
FROM registry.cn-qingdao.aliyuncs.com/x-lab/kvm:v1.7.1

RUN apt-get install -y jq

COPY ./scripts /

COPY startup.sh /startapp.sh
