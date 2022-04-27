FROM jenkins/inbound-agent:jdk11

USER root
RUN apt-get update && apt-get install -y docker.io \
			awscli \
			python3 \
			python3-pip \
			postgresql-client \
			curl \
			gnupg \
			lsb-release \
			software-properties-common \
		&& curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
		&& apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
		&& apt-get update && apt-get install -y terraform \
		&& rm -Rf /var/lib/apt/lists/*
