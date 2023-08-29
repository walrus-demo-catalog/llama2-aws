resource "aws_spot_instance_request" "llama" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.vpc_name != "" ? data.aws_subnets.selected.0.ids.0 : null
  vpc_security_group_ids      = var.security_group_name != "" ? [data.aws_security_group.selected.0.id] : null
  key_name                    = var.key_name
  spot_type                   = "one-time"
  spot_price                  = var.spot_price * 1.2
  wait_for_fulfillment        = true
  associate_public_ip_address = true
  user_data     = <<-EOF
                  #!/bin/bash
                  cd /opt/llama/text-generation-webui
                  docker compose up
                  EOF

  tags = {
    "Name" = var.instance_name
  }

  root_block_device {
    volume_type = "io2"
    volume_size = var.disk_size
    iops        = var.disk_iops
  }
}


resource "null_resource" "health_check" {
  depends_on = [
    aws_instance.llama,
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "for i in `seq 1 60`; do if `command -v wget > /dev/null`; then wget --no-check-certificate -O - -q $ENDPOINT >/dev/null && exit 0 || true; else curl -k -s $ENDPOINT >/dev/null && exit 0 || true;fi; sleep 5; done; echo TIMEOUT && exit 1"
    interpreter = ["/bin/sh", "-c"]
    environment = {
      ENDPOINT = "http://${aws_spot_instance_request.llama.public_ip}:7860"
    }
  }
}
