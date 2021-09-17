IMAGE_TAG=jcr.ztecloud.com:8081/devops/jenkinsfile-runner-custom

.PHONY: get-plugins network dind test

tmp/jenkins-plugin-manager.jar: tmp
	test -f $@ || curl -o $@ https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.11.0/jenkins-plugin-manager-2.11.0.jar

tmp/jenkins.war: tmp
	test -f $@ || curl -o $@ https://get.jenkins.io/war-stable/2.303.1/jenkins.war

tmp/docker-ce-cli.deb: tmp
	test -f $@ || curl -o $@ https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce-cli_20.10.8~3-0~ubuntu-bionic_amd64.deb

tmp:
	test -d $@ || mkdir $@

download:
	test -d $@ || mkdir $@

get-plugin: download tmp/jenkins.war tmp/jenkins-plugin-manager.jar
	java -Dhttp.proxyPort=80 -Dhttp.proxyHost=proxyhk.zte.com.cn -Dhttps.proxyPort=80 -Dhttps.proxyHost=proxyhk.zte.com.cn -jar tmp/jenkins-plugin-manager.jar --plugin-download-directory download --war tmp/jenkins.war --plugin-file plugins.txt --verbose

clean:
	-rm -rf download

build: tmp/docker-ce-cli.deb
	docker build --no-cache -t $(IMAGE_TAG) .

network:
	docker network create jenkins

dind:
	docker run --name jenkins-docker --rm --detach \
        --privileged --network jenkins --network-alias docker \
        --env DOCKER_TLS_CERTDIR=/certs \
        --volume jenkins-docker-certs:/certs/client \
        --volume jenkins-data:/build@tmp:rw \
        --volume $(HOME)/artifact/docker:/docker-image \
        --publish 2376:2376 docker:dind --storage-driver overlay2

test:
	docker run --rm -it \
        --network jenkins \
        -v $(PWD)/test:/workspace \
        -v jenkins-docker-certs:/certs/client:ro \
        -v jenkins-data:/build@tmp:rw \
        -e DOCKER_HOST=tcp://docker:2376 \
        -e DOCKER_CERT_PATH=/certs/client \
        -e DOCKER_TLS_VERIFY=1 \
        $(IMAGE_TAG)

bash:
	docker run --rm -it \
        --network jenkins \
        -v $(PWD)/test:/workspace \
        -v jenkins-docker-certs:/certs/client:ro \
        -v jenkins-data:/var/jenkins_home \
        -e DOCKER_HOST=tcp://docker:2376 \
        -e DOCKER_CERT_PATH=/certs/client \
        -e DOCKER_TLS_VERIFY=1 \
        --entrypoint bash \
        $(IMAGE_TAG)
