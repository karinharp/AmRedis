#######################################################################################

include Makefile.env

# 上記で設定されるパラメータ、API_ はテスト用パラメータ
PROJECT      ?= 
API_FUNC     ?=
API_FUNC_ARG ?=
API_STAGE    ?=
API_NAME     ?= $(shell cat serverless.yml | yq '.functions.${API_FUNC}.events[0].http.path' | tr -d "\"")
API_URL      ?= $(shell cat ${PROJECT}Info-${API_STAGE}.json | jq '.list[] | select (.url | endswith("${API_NAME}")) | .url '  | tr -d "\"")
API_KEY      ?= ${shell cat ${PROJECT}Info-${API_STAGE}.json | jq '.key' | tr -d "\""}
REDIS_URI    ?= 

# Terraform側にも同じ定義あり。
# 必要に応じて定期的にS3 syncでどこかにバックアップしておくこと。
S3_BUCKET    ?= `echo ${PROJECT} | tr A-Z a-z`-data-${API_STAGE}

# LocalLambda実行時の環境変数設定
# REDISはVPC内部なので、定義しても参照不可
# CLIENT側は逆にLocal実行のみなので、ここでのみ定義
LAMBDA_ENV_VAR  = export LAMBDA_SERVICE=${PROJECT}; 
LAMBDA_ENV_VAR += export LAMBDA_ENV=${API_STAGE}; 
#LAMBDA_ENV_VAR += export REDIS_URI=${REDIS_URI}; 
LAMBDA_ENV_VAR += export DEBUG_API_URL=${API_URL}; 
LAMBDA_ENV_VAR += export DEBUG_API_KEY=${API_KEY}; 

#######################################################################################

default:

env:
	@echo "PROJECT       ?= ${PROJECT}"       > Makefile.env
	@echo "API_FUNC      ?= ${API_FUNC}"     >> Makefile.env
	@echo "API_FUNC_ARG  ?= ${API_FUNC_ARG}" >> Makefile.env
	@echo "API_STAGE     ?= ${API_STAGE}"    >> Makefile.env

Makefile.env: env

clean:
	-rm -rf arc
	-rm -rf obj
	-rm -rf bin
	-rm -rf .serverless
	-rm publish.zip
	-rm serverlessConfig.yml
	-rm serverlessVpcConfig.yml
	-rm serverlessRedisConfig.yml
	-rm ${PROJECT}Info-*.json
	-rm apiKey.txt
	-rm apiList.txt

##[ Lambda Build ]####################################################################

all: init build run

build:
	dotnet build --configuration Release

new:
	dotnet new console

init:
	dotnet restore

run:
	${LAMBDA_ENV_VAR} dotnet run

publish:
	dotnet publish --output arc

package: publish
#	dotnet lambda package --configuration Release --framework netcoreapp1.0
	(cd arc && zip ../publish.zip *)

# nuget（https://www.nuget.org/packages?q=AWSSDK）からAWSSDK.*** とか探してPKGにいれる
add-library:
	dotnet add package ${PKG}

##[ Serverless Framework ]#############################################################

serverlessVpcConfig.yml:
	make -C AmRedis-Release-Terraform ServerlessVpcConfig

serverlessRedisConfig.yml:
	make -C AmRedis-Release-Terraform ServerlessRedisConfig

serverlessConfig.yml:
	echo "service: ${PROJECT}" > serverlessConfig.yml

api-all: serverlessConfig.yml serverlessVpcConfig.yml serverlessRedisConfig.yml
	serverless deploy -v --stage ${API_STAGE}

api: serverlessConfig.yml serverlessVpcConfig.yml serverlessRedisConfig.yml
	serverless deploy function -f ${API_FUNC} --stage ${API_STAGE}

# Terraformと違って、書き換えたら勝手に消すとかしてくれない
api-clean:
	serverless remove -v --stage ${API_STAGE}

# Lambda 直接呼
api-test:
	serverless invoke --function ${API_FUNC} -p ${API_FUNC_ARG} --log --stage ${API_STAGE}

# パッケージの更新から、デプロイ、テスト呼び出しまでを一括でやる用
api-test-batch: package api api-test


# LambdaをAPIGatway経由で呼ぶ場合（APIキーなし）
api-test-gw:
	curl -X POST -H 'Content-Type:application/json' -d @${API_FUNC_ARG} ${API_URL}

# LambdaをAPIGatway経由で呼ぶ場合（APIキーあり）
api-test-gwk:
	curl -X POST -H 'Content-Type:application/json' -d @${API_FUNC_ARG} ${API_URL} --header x-api-key:${API_KEY}

# あとから確認したい用
api-log:
	serverless logs --function ${API_FUNC} --stage ${API_STAGE}

export-api-list:
	serverless info --stage ${API_STAGE} | grep "https://" | awk '{print $$3}' > apiList.txt

export-api-key:
	serverless info --stage ${API_STAGE} | grep -a1 "api keys" | tail -n1 | cut -d":" -f2 | awk '{print $$1}' > apiKey.txt

api-info: export-api-list export-api-key
	php tools/CreateInfo.php > ${PROJECT}Info-${API_STAGE}.json
	cat ${PROJECT}Info-${API_STAGE}.json | jq .
#	aws s3 cp ${PROJECT}Info-${API_STAGE}.json s3://${S3_BUCKET}/InfoData/${PROJECT}Info-${API_STAGE}.json

#######################################################################################
