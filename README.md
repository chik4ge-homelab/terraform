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
