provider "aws" {
  region = "us-east-1"  # Defina a região desejada
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"  # Substitua pelo CIDR desejado
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"  # Substitua pelo CIDR desejado para a subnet
  availability_zone       = "us-east-1a"    # Substitua pela zona de disponibilidade desejada

  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_private" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"  # Substitua pelo CIDR desejado para a subnet
  availability_zone       = "us-east-1a"    # Substitua pela zona de disponibilidade desejada

  map_public_ip_on_launch = false
}

resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig_public.id 
  }

  depends_on = [ aws_internet_gateway.ig_public ]
}

resource "aws_route_table_association" "association_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_internet_gateway" "ig_public" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ng_private.id  
  }

  depends_on = [ aws_nat_gateway.ng_private ]
}

resource "aws_route_table_association" "association_private" {
  subnet_id      = aws_subnet.subnet_private.id
  route_table_id = aws_route_table.route_table_private.id
}

resource "aws_nat_gateway" "ng_private" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.subnet_private.id
}

################################################# Cria Instancias ###################################################

# Instancia Jump Server
resource "aws_security_group" "jump_server_sg" {
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jump_server_instance" {
  ami           = "ami-0fc5d935ebf8bc3bc"  # Ubuntu 22.04 LTS
  instance_type = "t2.micro"
  key_name      = "jumpserver-keypar"  # Substitua pelo nome da sua chave

  vpc_security_group_ids = [aws_security_group.jump_server_sg.id]

  subnet_id = aws_subnet.subnet_public.id
}

# Instancia Web Server
resource "aws_security_group" "web_server_sg" {
    vpc_id = aws_vpc.example.id
    ingress {
        from_port   = 10050
        to_port     = 10050
        protocol    = "tcp"
        cidr_blocks = [aws_instance.zabbix_instance.private_ip]
    }

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = [aws_instance.database_instance.private_ip]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [aws_instance.jump_server_instance.private_ip]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    depends_on = [ aws_instance.database_instance, aws_instance.zabbix_instance ]
}

resource "aws_instance" "web_server_instance" {
  ami           = "ami-0fc5d935ebf8bc3bc"  # Ubuntu 22.04 LTS
  instance_type = "t2.micro"
  key_name      = "jumpserver-keypar"  # Substitua pelo nome da sua chave

  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  subnet_id = aws_subnet.subnet_public.id
}

# Instancia Database
resource "aws_security_group" "database_sg" {
    vpc_id = aws_vpc.example.id
    ingress {
        from_port   = 10050
        to_port     = 10050
        protocol    = "tcp"
        cidr_blocks = [aws_instance.zabbix_instance.private_ip]
    }

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = [aws_instance.web_server_instance.private_ip]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [aws_instance.jump_server_instance.private_ip]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    depends_on = [ aws_instance.web_server_instance, aws_instance.zabbix_instance ]
}

resource "aws_instance" "web_server_instance" {
  ami           = "ami-0fc5d935ebf8bc3bc"  # Ubuntu 22.04 LTS
  instance_type = "t2.micro"
  key_name      = "jumpserver-keypar"  # Substitua pelo nome da sua chave

  vpc_security_group_ids = [aws_security_group.database_sg.id]

  subnet_id = aws_subnet.subnet_private.id
}

# Instancia Zabbix
resource "aws_security_group" "zabbix_sg" {
    vpc_id = aws_vpc.example.id
    ingress {
        from_port   = 10050
        to_port     = 10050
        protocol    = "tcp"
        cidr_blocks = [aws_instance.database_instance.private_ip]
    }

    ingress {
        from_port   = 10050
        to_port     = 10050
        protocol    = "tcp"
        cidr_blocks = [aws_instance.web_server_instance.private_ip]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [aws_instance.jump_server_instance.private_ip]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    depends_on = [ aws_instance.database_instance, aws_instance.web_server_instance ]
}

resource "aws_instance" "zabbix_instance" {
  ami           = "ami-0fc5d935ebf8bc3bc"  # Ubuntu 22.04 LTS
  instance_type = "t2.medium"
  key_name      = "jumpserver-keypar"  # Substitua pelo nome da sua chave

  vpc_security_group_ids = [aws_security_group.zabbix_sg.id]

  subnet_id = aws_subnet.subnet_public.id
}