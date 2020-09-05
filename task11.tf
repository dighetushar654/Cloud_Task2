provider "aws" {
  region     = "ap-south-1"
  profile    = "tushar"
}

resource "aws_security_group" "allow_my_http" {
  name        = "launch-wizard-7"
  description = "Allow my HTTP SSH inbound traffic"
  vpc_id      = "vpc-dbe1fcb3"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "httpsecurity"
  }
}

resource "aws_s3_bucket" "job171" {
  bucket = "job171" 
  acl    = "public-read"
  tags = {
    Name        = "job171"
  }
  versioning {
	enabled =true
  }
}

resource "aws_s3_bucket_object" "s3object" {
  bucket = "${aws_s3_bucket.job171.id}"
  key    = "download.png"
  source = "C:/Users/Admin/Pictures/download.png"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "This is origin access identity"
}

resource "aws_cloudfront_distribution" "imgcf" {
    origin {
        domain_name = "job171.s3.amazonaws.com"
        origin_id = "S3-job171" 


        s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
       
    enabled = true
      is_ipv6_enabled     = true

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-job171"


        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 10
        max_ttl = 30
    }
    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }


    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

resource "aws_instance" "os" {
  ami               = "ami-07db4adf15d7719d1"
  instance_type     = "t2.micro"
  key_name          = "task2"
  security_groups   = [ "launch-wizard-7" ]
	

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/Admin/Downloads/task2.pem")
    host        = "${aws_instance.os.public_ip}"
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php  git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd"
    ]
  }

  tags = {
      Name = "myfirstos"
  }
}

#creating_efs_storage
resource "aws_efs_file_system" "foo" {
  creation_token = "my-product"


  tags = {
    Name = "MyProduct"
  }
}


#Creating_Mount_Target
resource "aws_vpc" "efs-vpc" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_subnet" "efs-sub" {
  depends_on = [aws_vpc.efs-vpc]
  vpc_id            = aws_vpc.efs-vpc.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.0.1.0/24"
}


resource "aws_efs_mount_target" "target" {
    depends_on = [aws_subnet.efs-sub]
  file_system_id = aws_efs_file_system.foo.id
  subnet_id      = aws_subnet.efs-sub.id
}


#mount_efs_mountTarget


resource "null_resource" "mount_vol" {
  depends_on = [
    aws_efs_mount_target.target,
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Admin/Downloads/task2.pem")
    host     = "${aws_instance.os.public_ip}"
   }
  provisioner "remote-exec" {
      inline = [
        #"sudo mkfs.ext4  ${aws_efs_mount_target..target.mount_target_dns_name}",
        "sudo mount  ${aws_efs_mount_target.target.mount_target_dns_name}  /var/www/html",
        "sudo rm -rf /var/www/html/*",
        "sudo git clone https://github.com/dighetushar654/Cloud_Task1.git /var/www/html/"
        ]
      }
}
