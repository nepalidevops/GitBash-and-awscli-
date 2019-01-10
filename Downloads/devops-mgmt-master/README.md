# devops-mgmt
The DaaS Automation Framework provides ADOs a standard DevOps infrastructure. The configuration is customizable and should adapt to the ADOs needs and requirements. At the very minimum, the framework will consist of one Jenkins EC2 instance. The option of creating a SonarQube and/or Nexus instance is also included.

## How it Works
The "devops-mgmt.yaml" file under /cloudformation is the cloudformation script used to automate everything from one command/run. Parameters can be set to customize the script for the ADOs environment.

The Jenkins ec2 instance uses user-data to clone this repo from a remote source and then run the /setup_scripts/bootstrap.sh script. The bootstrap.sh script setups the volumes, installs ansible, and runs the chosen ansible playbooks. 

ADO teams (with help from the DaaS team) will run the cloudformation script to create the inital framework

## Setup  
### Github
1. Create a GitHub personal access token for the Jenkins service account **Settings > Personal access tokens > Generate new token** and copy down / save the personal access token as you will need to use it again later.
 - **Note:** To set up the ability to push changes to GitHub from your local system, use the `https://` URL for your repository (e.g. `https://github.cms.gov/DaaS/devops-mgmt`) as your remote URL, and when prompted for credentials upon `git push`, use your EUA ID as the username and the Personal Access Token as your password. 
 - Also, before the first time you try to do this, you should open Git Bash and run the following command to make your HTTP POST buffer large enough to push this repo: `git config --global http.postBuffer 524288000` (that "magic number" is just 500 MiB)
 - SSH pushing is not supported as port 22 is not open, so all interaction with CMS GitHub must be over `https`. Your regular EUA password won't work, either, because that wouldn't be proper 2FA. The Personal Access Token resolves this problem.

### AWS Console 
2. Create jeknins-master-key key pair (Used to ssh to jenkins instance). **EC2 > Key Pairs**  
3. Create jenkins-deploy-key key pair (Used to ssh from jenkins to client). **EC2 > Key Pairs**  
4. Create Encryption key to secure param store. Set desired key admin and user (Should be ADO admin for the environment). **IAM > Encryption Keys**  
5. Create Parameters to be used by the scripts **AWS Systems Manager > Parameter store > Create parameter**
> **Parameters**: JenkinsDeployKey, GithubToken  
> **Type**:  SecureString  
> **KMS key source**: My current account  
> **KMS keys ID**: *"choose Encryption key alias created for param store"*  
> **Value**: *Respective values for the two params*

6. Generate the cloudformation script **CloudFormation > Create Stack** :
- Obtain up-to-date script from DaaS team
- Choose to upload the template from file. 
- Name the stack "devops-mgmt".
- Update the parameters accordingly for the ADO environment.
- Continue until "Create" is an option. Check the radio button to acknowledge IAM resource creation.

7. The cloudforamtion script will begin to create the AWS resources. Under the EC2 Service on the console, search for the whatever the "ProjectName" parameter was set to in the cloudformation script. The jenkins, nexus, and sonar instances should begin to show as initalizing. Once the jenkins instance has started, ssh access should soon be available.  
Using the jenkins-master-key, connect to OpenVPN ssh into the jenkins instance:
`ssh -i <path_to_jenkins-master-key_private_key> ec2-user@<jenkins_private_ip_address>`
Tail the log file to show the progress of the script and ensure no errors occur:
`sudo tail -f /var/log/user-data.log` 

### SonarQube UI

 8. Open a browser and head to 
	 `<sonar_private_ip>:9000`
 9. Login with the deafult credentials
	 > Username: admin
	 > Password: admin 
10. Change the default admin password and store the new password in a secure location.
11.  Generate a token to be used with Jenkins (https://docs.sonarqube.org/display/SONAR/User+Token)
12. Copy the token and store in a secure location

### Jenkins UI
13. Open a browser and head to 
	   `<jenkins_private_ip>:8080`
14. Login with the default credentials
	  > Username: admin
	  > Password: admin
15. Change the default admin password and store the new password in a secure location
17. Add SonarQube token to the Jenkins SonarQube Global configuration **Manage Jenkins** **>** **Global Tool Configuration** 

### Nexus UI
18. Open a browser and head to 
	   `<nexus_private_ip>:8081`
19. Login with the default credentials
	  > Username: admin
	  > Password: changeme
20. Change the default admin password and store the new password in a secure location

 ## Notes
 ### Thirparty Sources:
 - Spring: https://github.com/springframeworkguru/springbootwebapp/search?q=.png&unscoped_q=.png
 - Jenkins: https://github.com/geerlingguy/ansible-role-jenkins
 - Java: https://github.com/geerlingguy/ansible-role-java
 - Apache: https://github.com/geerlingguy/ansible-role-apache
 - SonarQube: https://github.com/Hylke1982/ansible-role-sonar
 - Ansible-Terraform plugin https://nicholasbering.ca/tools/2018/01/08/introducing-terraform-provider-ansible/

- Nexus: https://github.com/savoirfairelinux/ansible-nexus3-oss
> Change made: added ansible resource to update permissions on install directory  
> task: nexus_install.yml  
> - name: Update permissions on nexus install dir
  file:
    dest: "{{ nexus_installation_dir }}/nexus-{{ nexus_version }}"
    owner: "{{ nexus_os_user }}"
    group: "{{ nexus_os_group }}"
    recurse: yes
 
- MySql: https://github.com/geerlingguy/ansible-role-mysql
> Change made: account for SELINUX issue.  
> task: configure.yml  
>  - -name: Change context on error log file  (if configured).
  command: chcon system_u:object_r:mysqld_log_t:s0 "{{ mysql_log_error }}"
  when: mysql_log == "" and mysql_log_error != "" 

### To Do:
- Docker: https://tech.ticketfly.com/our-journey-to-continuous-delivery-chapter-4-run-jenkins-infrastructure-on-aws-container-service-ef37e0304b95
- Docker Role
- DNS
- S3 terraform state files
- User / SSH management
- Fortify
- Jmeter
- Gradle / Maven bootstrap
- Automated testing framework/s
- HA / CloudWatch
- Please add any more ideas below...
 ### Potential Changes:
- **Ansible Galaxy**: The thirdparty ansible roles have been manually downloaded from Ansible Galaxy. We may want to consider using Ansible Galaxy versioning/pulling instead of manually updating these roles.
- **Docker**: maintain creation of Jenkins, nexus, sonarqube, etc... through containers.
- **RDS for SonarQube running on Docker**
- **OWASP Dependency Checker / ZAP**

### Helpful commands
sudo docker run --rm -v "$(pwd)":/opt/maven -w /opt/maven --net="host" -v "$(pwd)":/root/.m2 maven:3.3.9-jdk-8 mvn -B clean verify
