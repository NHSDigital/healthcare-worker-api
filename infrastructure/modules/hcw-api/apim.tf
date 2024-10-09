data "aws_secretsmanager_secret" "apim_account_private_key" {
  name = "apim-account-private-key"
}

resource "terraform_data" "apim_instance_deploy" {
  triggers_replace = {
    spec = sha1(file("${path.root}/../specification/healthcare-worker-api.yaml"))
    build_script = sha1(file("${path.module}/apim_instance_deploy.sh"))
  }

  provisioner "local-exec" {
    command = "${path.module}/apim_instance_deploy.sh ${var.env} ${var.apim_environment} ${data.aws_secretsmanager_secret.apim_account_private_key.arn} ${aws_api_gateway_stage.live.invoke_url}"
  }

  provisioner "local-exec" {
    when = destroy
    command = ""
  }
}
