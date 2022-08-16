# Launch an ec2 instance from terrform and deploy nginx server in that instance.
# Show the IP of the server in the output.

## Step 1 - Launch ubuntu instance on the AWS and access via terminal

![image](https://user-images.githubusercontent.com/67600604/184825997-b372c460-7ebf-44e4-b11a-33aca6e6ad96.png)

![image](https://user-images.githubusercontent.com/67600604/184826577-b4d07f8d-9ec2-45b0-8499-ba9386dea13d.png)

## Step 2 - Install Terraform in the sever 

``` 
sudo mkdir -p /opt/terraform
cd /opt/terraform
sudo apt-get install unzip
https://www.terraform.io/downloads.html
wget https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip
unzip terraform_1.0.7_linux_amd64.zip
----sudo mv terraform /opt/terraform-----

check it by using the command - terraform --version 

```
## Step 3 - Installing AWS cli in the server 

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

## Step 4 - To create AWS user and run the command aws configure and add the "Access key" and "Secret Key" and configure the AWS shell

![image](https://user-images.githubusercontent.com/67600604/184829544-cc281cac-9e05-40f6-a353-943401ad71db.png)

## step 5 - To create the public and private key using the ssh keygen

Now, we have to create the private and public key to access our newly created instance via terraform

![image](https://user-images.githubusercontent.com/67600604/184830113-8328dac7-ef71-44dc-be81-f41adcf23191.png)

Run the Command 

```ssh-keygen```
press enter 3 times 
check in the root directory , there should be a .ssh directory formed 

now copy both the files in the /opt/terraform folder (our terraform directory)

## Step 6 - to create infra file for the creation of the terraform instance 

Now, create a file named as "instance.tf" in the /opt/terraform folder , you can get the same file in the repo 

After that, run the folowing commands to create and apply the terraform changes

```
terraform init
terraform plan
terraform apply
```

when it gets completed , go to  AWS console and check the instance created and when i hit the public ip of that instance it should be like this:

![image](https://user-images.githubusercontent.com/67600604/184831458-4481d042-7305-49ea-a26b-7d1071e23e06.png)

### Important Note - we have created a new private key for the newly created  

now, to access the new instance using ssh , we need to go into the /opt/terraform folder in our aws server and then run the command ``` ssh -i id_rsa ec2-user@ipaddress``` 

you will be able to get access using the ssh now to your server created via terraform - 

![image](https://user-images.githubusercontent.com/67600604/184835597-a0d93298-a338-4900-8b67-55e8398beabe.png)


