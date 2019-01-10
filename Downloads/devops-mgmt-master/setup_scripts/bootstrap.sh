#! /usr/bin/sh
set -e

CREATE_NEXUS=$1
CREATE_SONAR=$2
JENKINS_EFS=$3
JENKINS_EBS=$4
VPC_NAME=$5
AWS_REGION=$6
PROJECT_NAME=$7
GITHUB_UN=$8
GITHUB_TOKEN=$9

if [ -f /bin/aws ]; then 
	AWSCMD=/bin/aws
else
	AWSCMD=/usr/local/bin/aws
fi


if [ "$JENKINS_EFS" != "false" ]; then
	#Setup EFS volume
	JENKINS_EFS_IP=`$AWSCMD efs describe-mount-targets --region $AWS_REGION --file-system-id $JENKINS_EFS --query "MountTargets[*].IpAddress" --output=text`
	yum install -y nfs-utils;
	mkdir /var/lib/jenkins;
	mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $JENKINS_EFS_IP:/ /var/lib/jenkins;
	cp /etc/fstab /etc/fstab.orig;
	echo "$JENKINS_EFS_IP:/ /var/lib/jenkins nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0" >> /etc/fstab;
	mount -a;
fi
if [ "$JENKINS_EBS" == "true" ]; then
	# Setup EBS volume
	mkfs.xfs /dev/nvme1n1 -L JENKINS;
	mkdir /var/lib/jenkins;
	mount /dev/nvme1n1 /var/lib/jenkins;
	cp /etc/fstab /etc/fstab.orig;
	echo "LABEL=JENKINS                           /var/lib/jenkins   xfs    defaults,noatime 0 2" >> /etc/fstab;
	mount -a;
fi

# Install ansible
echo "setting up ansible";
yum install ansible -y;

# Remove require tty for ec2-user
cp /etc/sudoers /etc/sudoers.org;
echo 'Defaults:ec2-user !requiretty' >> /etc/sudoers;

chmod 700 /home/ec2-user/.ssh;
chmod 600 /home/ec2-user/.ssh/id_rsa;
chown -R ec2-user:ec2-user /home/ec2-user;

#Create host list for playbooks
if [ "$CREATE_NEXUS" = "true" ]; then
	NEXUS_IP=`$AWSCMD ec2 describe-instances --filter --region $AWS_REGION "Name=tag:Name,Values=$PROJECT_NAME-$VPC_NAME-devops-nexus" --query "Reservations[*].Instances[*].PrivateIpAddress" --output=text`
	echo "[nexus]" > /home/ec2-user/devops_hosts;
	echo "$NEXUS_IP" >> /home/ec2-user/devops_hosts;
	su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/ansible/playbooks/nexus.yml &';
fi
if [ "$CREATE_SONAR" = "true" ]; then
	SONAR_IP=`$AWSCMD ec2 describe-instances --filter --region $AWS_REGION "Name=tag:Name,Values=$PROJECT_NAME-$VPC_NAME-devops-sonar" --query "Reservations[*].Instances[*].PrivateIpAddress" --output=text`
	echo "[sonar]" >> /home/ec2-user/devops_hosts;
	echo "$SONAR_IP" >> /home/ec2-user/devops_hosts;
	su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/ansible/playbooks/sonar.yml &';
fi

su ec2-user -c "ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/ansible/playbooks/jenkins.yml --extra-vars \"create_nexus=\"$CREATE_NEXUS\" github_un=\"$GITHUB_UN\" github_token=\"$GITHUB_TOKEN\" create_sonar=\"$CREATE_SONAR\"\"&";
