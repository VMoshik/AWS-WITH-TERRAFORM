resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "sub1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "sub2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.myvpc.id
}
resource "aws_route_table" "myrt" {
  vpc_id = aws_vpc.myvpc.id

route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
}
}
resource "aws_route_table_association" "rta1" {
  subnet_id = aws_subnet.sub1.id
  route_table_id = aws_route_table.myrt.id
}
resource "aws_route_table_association" "rta2" {
  subnet_id = aws_subnet.sub2.id
  route_table_id = aws_route_table.myrt.id
}
resource "aws_security_group" "SG" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}
resource "aws_instance" "server1" {
  ami = "ami-0261755bbcb8c4a84"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.SG.id]
  subnet_id = aws_subnet.sub1.id
   user_data = base64encode(file("userdata1.sh")) 
}
resource "aws_instance" "server2" {
  ami = "ami-0261755bbcb8c4a84"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.SG.id]
  subnet_id = aws_subnet.sub2.id
  user_data = base64encode(file("userdata.sh"))
}
resource "aws_lb" "mylb" {
 name = "mylb"
 internal = false
 load_balancer_type = "application"
 security_groups =[aws_security_group.SG.id]
 subnets = [aws_subnet.sub1.id,aws_subnet.sub2.id] 
}
resource "aws_lb_target_group" "TG" {
  name = "TG"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "attach1" {
target_group_arn = aws_lb_target_group.TG.arn
target_id =aws_instance.server1.id
port = 80
}
resource "aws_lb_target_group_attachment" "attach2" {
target_group_arn = aws_lb_target_group.TG.arn
target_id = aws_instance.server2.id
port = 80
}
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.mylb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.TG.arn
    type = "forward"
  }
}
output "load_balancer_arn" {
  value = aws_lb.mylb.dns_name
}