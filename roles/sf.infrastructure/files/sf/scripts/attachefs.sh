#!/bin/bash
echo "###########################"
echo "###########################"
echo "start jenkins deployment"

pip3 install awscli

mkdir -p /root/.jenkins

EFS_ID=$(aws efs describe-file-systems --region=us-east-2 --query 'FileSystems[*].[FileSystemId, Tags[?Value==`jenkins-efs`]][0][0]' --output text)

echo ${EFS_ID}

sudo touch /etc/systemd/system/jenkins_sf.service

sudo tee -a  /etc/systemd/system/jenkins_sf.service > /dev/null <<EOT
[Unit]
Description=Job that runs Jenkins

[Service]
ExecStart=java -jar /home/ubuntu/jenkins.war -httpPort=8080
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOT


DATA_STATE="unknown"
echo $DATA_STATE
until [ "$DATA_STATE" == "available" ]; do
        DATA_STATE=$(aws efs describe-mount-targets --file-system-id ${EFS_ID} --query 'MountTargets[*].[LifeCycleState][0][0]' --region=us-east-2 --output text)
        echo $DATA_STATE
        sleep 3
done

sleep 10

sudo sh -c "echo '${EFS_ID}:/ /root/.jenkins efs _netdev,tls,iam 0 0' >> /etc/fstab"
sudo mount -av

echo "###########################"
echo "###########################"
echo "finished jenkins deployment"

sudo systemctl daemon-reload
sudo systemctl enable jenkins_sf.service
sudo systemctl start jenkins_sf.service