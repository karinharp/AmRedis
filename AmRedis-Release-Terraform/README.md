Terraformのスケルトン
============================================================

新規にリソース管理をはじめる手順
------------------------------------------------------------

- tfstate管理用のS3 bucketを準備
	- 1つのbucketを複数リソースで使いまわしていいので、２つ目以降は不要
- このスケルトンをcloneして、ディレクトリ名を変更
- touch Makefile.env
- make env
- Makefile.env のパラメータ書き換え
- make tf-init
	- Makefile.env がちゃんと設定できてれば、tfvars はいい感じに自動生成されるので、気にしないでいい
- *.tf でリソースを定義
- make tf-all
	- tf-test => tf-plan => tf-apply
- make tf-status
	- show

