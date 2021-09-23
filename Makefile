IMAGE_TAG=cdn-snapshot-docker.artnj.zte.com.cn/coral/devops/jenkinsfile-runner-custom

.PHONY: get-plugins network dind test-ssl test

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

push:
	docker push $(IMAGE_TAG)

test:
	docker run --rm -it \
        -v $(PWD)/test:/workspace \
        -v /build@tmp:/build@tmp:rw \
        -v /var/run/docker.sock:/var/run/docker.sock \
        $(IMAGE_TAG)

bash:
	docker run --rm -it \
        --network host \
        -v $(PWD)/test:/workspace \
        -v /build@tmp:/build@tmp:rw \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --entrypoint bash \
        $(IMAGE_TAG)

