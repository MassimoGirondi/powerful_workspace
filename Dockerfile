FROM nvidia/cuda:12.1.0-base-ubuntu22.04
LABEL org.opencontainers.image.authors="girondi@kth.se"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt -y install iproute2 iputils-ping ethtool tcpdump nvtop  iperf iperf3 fping pciutils curl wget git cmake gdb vim
RUN apt -y install stress htop atop nload nethogs nvtop s-tui
RUN apt -y install python3 pkg-config libnl-3-dev libnl-route-3-dev
RUN apt -y install ibverbs-providers  rdma-core perftest ibverbs-utils ibverbs-utils
RUN wget https://raw.githubusercontent.com/Mellanox/container_scripts/master/ibdev2netdev -O /usr/bin/ibdev2netdev && chmod +x /usr/bin/ibdev2netdev

#RUN git clone https://github.com/linux-rdma/rdma-core && cd rdma-core && ./build.sh
COPY  --from=girondi/rdma_core /rdma-core /rdma-core

RUN apt -y install openssh-server supervisor
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/# *PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# We use supervisord to start ssh inside the container
# (which is not the proper way to do it but it's fine for us)
# See https://stackoverflow.com/questions/28134239/how-to-ssh-into-docker
# https://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#ENV SUPERVISOR_UID=123123
#ENV SUPERVISOR_GID=123123
#RUN groupadd -g $SUPERVISOR_GID supervisord && useradd -m -s /bin/bash  -d /home/supervisord -u $SUPERVISOR_UID supervisord -g supervisord
RUN mkdir -p /var/log/supervisor && chmod 777 -R /var/log/ 

RUN groupadd -g 999999 csd_23 && useradd -m -s /bin/bash  -d /home/csd_23 -u 999999 csd_23 -g csd_23
RUN echo 'csd_23:csd_23' | chpasswd

# Cleanup
RUN rm -rf /var/apt

WORKDIR /workspace
VOLUME /workspace
VOLUME /home/csd_23
EXPOSE 22/tcp
#USER supervisord
CMD ["/usr/bin/supervisord"]

