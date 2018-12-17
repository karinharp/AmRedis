#####################################################################################

# tfstate管理用のs3 bucket, AWSのCredential（初期化終わったら空にしていい）
# skelthon落とす => make env して出来た Makefile.env を Fill => make init
include Makefile.env
include ../Makefile.env

# このリソースのディレクトリ名
CURRENT_DIR            = ${shell basename `pwd`}
TERRAFORM             ?= terraform

# 上記で設定されるパラメータ
TFSTATE_BUCKET        ?= 
AWS_ACCESS_KEY_ID     ?= 
AWS_SECRET_ACCESS_KEY ?= 
# 一部、上位から引き継ぐ。あと、小文字に揃えておく。
# 遅延評価演算子使わないと、include前に解決されてしまう...
PROJECT_NAME          := `echo ${PROJECT} | tr A-Z a-z`
PROJECT_DB_REVISION   ?=
PROJECT_ENV           ?= 

CLUSTER_ID      := ${shell cat ClusterId.txt}
CLUSTER_NODE_ID := ${shell cat ClusterNodeId.txt}

#####################################################################################

default:
	@echo "do nothing"
	@echo ${PROJECT_NAME}

clean:
	rm tfplan
	rm terraform.tfvars
	rm -rf .terraform

Makefile.env:
	${MAKE} env

env:
	@echo "TFSTATE_BUCKET        ?= ${TFSTATE_BUCKET}" > Makefile.env
	@echo "AWS_ACCESS_KEY_ID     ?= ${AWS_ACCESS_KEY_ID}" >> Makefile.env
	@echo "AWS_SECRET_ACCESS_KEY ?= ${AWS_SECRET_ACCESS_KEY}" >> Makefile.env
	@echo "PROJECT_NAME          ?= ${PROJECT_NAME}" >> Makefile.env
	@echo "PROJECT_ENV           ?= ${PROJECT_ENV}" >> Makefile.env
	@echo "PROJECT_DB_REVISION   ?= ${PROJECT_DB_REVISION}" >> Makefile.env

# 環境変数にexportしてない場合は、生成後に手動で書き換えること
terraform.tfvars: Makefile.env
	echo "aws_access_key = \"${AWS_ACCESS_KEY_ID}\"" > terraform.tfvars
	echo "aws_secret_key = \"${AWS_SECRET_ACCESS_KEY}\"" >> terraform.tfvars
	echo "tfstate_bucket = \"${TFSTATE_BUCKET}\"" >> terraform.tfvars
	echo "tfstate_object = \"${CURRENT_DIR}\"" >> terraform.tfvars
	echo "title          = \"${PROJECT_NAME}\"" >> terraform.tfvars
	echo "env            = \"${PROJECT_ENV}\"" >> terraform.tfvars
	echo "db_revision    = \"${PROJECT_DB_REVISION}\"" >> terraform.tfvars

# 追加モジュールのロードとか。Provider定義後に実行する
# initのbackend setupの段階ではtfvarsを読まないので、トリッキーだが、backend-configで渡す必要あり。
# issue 湧いてるので、そのうち改善されるかも？
# https://github.com/hashicorp/terraform/issues/13022
# init時の対話モードを切り方が分からんので、initだけは、メインシェルで実行してくれ...
tf-init: terraform.tfvars
	${TERRAFORM} init \
		-backend-config "bucket=${TFSTATE_BUCKET}" \
		-backend-config "key=${CURRENT_DIR}" \
		-backend-config "region=ap-northeast-1" \

# シンタックスチェック
tf-test:
	${TERRAFORM} validate 

# 実行内容事前チェック
tf-plan:
	${TERRAFORM} plan -out=tfplan -input=false 

# 実行
tf-apply:
	${TERRAFORM} apply -input=false tfplan 

# test => plan => apply
tf-all: tf-test tf-plan tf-apply ClusterId ClusterNodeId

# リソース破棄
tf-destroy:
	${TERRAFORM} plan --destroy -out=tfplan -input=false 

# test => destroy => apply 
tf-clean: tf-test tf-destroy tf-apply

tf-status:
	${TERRAFORM} show

tf-reboot:
#	echo ${CLUSTER_ID}
#	echo ${CLUSTER_NODE_ID}
	aws elasticache reboot-cache-cluster --cache-cluster-id ${CLUSTER_ID} --cache-node-ids-to-reboot ${CLUSTER_NODE_ID} 

setupTfstate:
	${TERRAFORM} remote config \
		-backend=S3 \
		-backend-config="${TFSTATE_BUCKET}" \
		-backend-config="region=ap-northeast-1" \
		-backend-config="key=${CURRENT_DIR}.tfstate" \
		-backend-config="access_key=${AWS_ACCESS_KEY_ID}" \
		-backend-config="secret_key=${AWS_SECRET_ACCESS_KEY}"

ServerlessRedisConfig:
	${TERRAFORM} state show aws_elasticache_cluster.redis | grep "cache_nodes.0.address" | awk '{print "host: " $$3}' > ../serverlessRedisConfig.yml
	${TERRAFORM} state show aws_elasticache_cluster.redis | grep "cache_nodes.0.port" | awk '{print "port: " $$3}' >> ../serverlessRedisConfig.yml

ServerlessVpcConfig:
	${TERRAFORM} state show aws_vpc.VPC | grep "default_security_group_id" | awk '{print "sg: " $$3}' > ../serverlessVpcConfig.yml
	${TERRAFORM} state show aws_elasticache_subnet_group.SubnetGroup | grep " subnet-" | awk '{print "subnetId: "$$3}' >> ../serverlessVpcConfig.yml

ClusterId:
	${TERRAFORM} state show aws_elasticache_cluster.redis | grep "cluster_id" | awk '{print $$3}' > ClusterId.txt

ClusterNodeId:
	${TERRAFORM} state show aws_elasticache_cluster.redis | grep "cache_nodes.0.id" | awk '{print $$3}' > ClusterNodeId.txt

#####################################################################################
