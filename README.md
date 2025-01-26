## デプロイ
```bash
# （必要に応じて）terraform destroy
sh deploy.sh
```

## variablesについて
- 機密情報と、moduleをまたいで使用する情報は、`./variables.tf` に記載する
- module内でのみ使用する情報は、`./<module>*/variables.tf` に記載する

### `./terraform.tfvars` 
```javascript
pve_user        = "user@pam"
pve_password    = "password"
bitwarden_token = "bitwarden_machine_account_token"
```

## VMの再作成
すでにクラスタが稼働している状態で、特定のノードを再作成する場合は以下を実行する
```bash
terraform apply -target="talos_machine_configuration_apply.worker[i]" -target="proxmox_virtual_environment_vm.workers[i]" -replace="proxmox_virtual_environment_vm.workers[i]"
```
