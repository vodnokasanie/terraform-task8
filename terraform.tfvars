project_id          = "cmtr-ghjc0xhd"
ssh_key_name        = "cmtr-ghjc0xhd-keypair"
vpc_id              = "vpc-052a1a5e239a8d3ed"

public_subnet_ids = [
  "subnet-0121cf16cd7a70abb",
  "subnet-08124a54dfc0aeac1"
]

security_group_ec2  = "sg-0a08fa8709fc33bc0"  # cmtr-ghjc0xhd-ec2_sg
security_group_http = "sg-069fe118e36d1a7a9"  # cmtr-ghjc0xhd-http_sg
security_group_lb   = "sg-0900da443f15873da"  # cmtr-ghjc0xhd-sglb

instance_profile    = "cmtr-ghjc0xhd-instance_profile"
