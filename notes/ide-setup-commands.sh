# Commands to connect to the EC2 instance and transfer files

ssh -i "kp-defualt-ah.pem" ec2-user@ec2-35-92-63-30.us-west-2.compute.amazonaws.com
ssh -i "kp-defualt-ah.pem" ec2-user@ec2-35-92-63-30.us-west-2.compute.amazonaws.com -L 2081:localhost:2041 -L 4888:localhost:4888 -L 2080:localhost:2080 -L 8050:localhost:8050 -L 4141:localhost:4141
scp -r -i "kp-defualt-ah.pem" docker_exp ec2-user@ec2-35-92-63-30.us-west-2.compute.amazonaws.com:/home/ec2-user/docker_exp

# Installing docker and docker-compose on the EC2 instance
sudo yum update -y
sudo yum install docker
sudo yum install -y libxcrypt-compat
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo gpasswd -a $USER docker
newgrp docker
sudo systemctl start docker
sudo systemctl stop docker

# Commands to run the docker containers and access the NiFi UI
docker ps
cd docker_exp
docker-compose up -d
docker exec -i -t nifi bash

# Jupyter Lab at: http://localhost:4888/lab? 
# NiFi at: http://localhost:2080/nifi/ 