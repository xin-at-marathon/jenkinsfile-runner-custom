FROM jenkins/jenkinsfile-runner

COPY download/* /usr/share/jenkins/ref/plugins/

#RUN sed -i "s@archive.ubuntu.com@mirrors.zte.com.cn@g" /etc/apt/sources.list
#RUN sed -i "s@security.ubuntu.com@mirrors.zte.com.cn@g" /etc/apt/sources.list
#RUN apt-get update

ADD tmp/docker-ce-cli.deb /root

RUN dpkg -i /root/docker-ce-cli.deb


