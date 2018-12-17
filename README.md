AmRedis
======================================================================

概要
----------------------------------------------------------------------

AWSを使用した、シンプルなRedisのKVS構成

- Makefile 
- Server Less Framework（Lambda + APIGateway）
- Terraform（上記以外のAWSリソース諸々）
- jq
- yq
	- brewで入れると古すぎてダメ、pipで最新版を入れること。
	- macOSでpipがはまる問題：https://github.com/adobe-type-tools/afdko/issues/238 の下の方みろ

を使用した自動構成に対応している。

最初にやること
----------------------------------------------------------------------

> Makeのたびに引数のAPI_STAGE指定するのがめんど場合、作業毎に、Makefile.envを弄っておくと無指定でOK（言うまでもなくCIで指定して実行するの奨励）

- Api側のプロジェクト初期化

```
make env
emacs Makefile.env
```

- TerraformでResource生成
	- Terraform側の初期化はTerraform側のREADME参照

- Api側のプロジェクトビルド


```
make all
make package
make api-all
make api-info
```

#### dev => release とか書き換えて、別環境Deployする場合

Makefile.env の env を書き換えた後、

```
make api-all
make api-info
```

を実行する。

Lambda側は、Stageを環境変数で拾って諸々処理しているなら、リビルド不要。

Terraform側は該当環境のリソースディレクトリでよしなにやっておくこと。

serverless.yml のハマりどころ
----------------------------------------------------------------------

### nameを手動でつける場合の注意

- ${opt:stage} を手動でつけておかないと、複数環境でリソース名衝突が起きてエラーになるので注意。
	- 具体的に、AWS側でハッシュっぽいのが付いてないリソースがあったら間違いなく起きるので、開発時から注意すること。


Redis周りのメモ
----------------------------------------------------------------------

C#Library は [StackExxange.Redis](https://www.nuget.org/packages/StackExchange.Redis/1.2.6) を使おう！
ただし、こいつ、最新バージョンを使うと、Lambdaでの実行時にエラーを吐く。
故に1系を明示指定して、使う必要あり。


```
dotnet add package StackExchange.Redis --version 1.2.6
```

> ServiceStack.Redis は罠だった。


リソースのクリーンナップ手順
----------------------------------------------------------------------

- Terraform側のディレクトリに入って

```
make tf-clean
make clean
```

- その後、ServerlessFramework側のディレクトリに入って

```
make api-clean
make clean
```

実装フロー
----------------------------------------------------------------------

### Modeの追加

わりと、手順を忘れるのでメモ。
Stubとかはジェネレーター作っても良い気がする。

- 実装するmodeの名前を決める
- Lambda{MODE}.cs と {MODE}Server.cs にStubを実装
- {MODE}Data.cs と {ACTION}Data.cs に Request定義を実装
- Program.cs に テスト用メソッド定義
- XXXXXXXServer.cs を実装しつつ、Lambda単体テスト
- make package で Lambda Package更新（この後のフローでもLambdaのコード修正するたびに必要なので注意）
- test/*****.json でテスト用引数オブジェクト定義
- Makefile.envの引数指定を変更
- serverless.yml に Endpoint追加
- DeployしてLambda単体テスト
- curl経由で、Server側結合テスト
- LambdaXXXXXX.cs と XXXXXXXClient.cs にStubを実装
- XXXXXXXClient.cs を実装しつつ、C#単体テスト

### API更新されない？

- make package して lambdaパッケージを更新しないと、 make api で、更新されてないよ！って言われます。

参考資料
----------------------------------------------------------------------

- [Serverless Framework v1.0の使い方まとめ](https://qiita.com/horike37/items/b295a91908fcfd4033a2)
- [APIGateway周りの記述方法](https://serverless.com/framework/docs/providers/aws/events/apigateway/#setting-api-keys-for-your-rest-api)
	- ただし、バージョン依存激しい箇所なので、本家通りでも動かない場合が多々ある。うろたえるな。
