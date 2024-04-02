# syntax=docker/dockerfile:1.4.1
FROM python:3.11-slim as builder

ARG WORKDIR
ENV PATH=${WORKDIR}/vendor/bin:$PATH \
	PYTHONPATH=${WORKDIR}/vendor/bin:${WORKDIR} \
	PYTHONUSERBASE=${WORKDIR}/vendor
WORKDIR ${WORKDIR}

COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY . .

FROM python:3.11-slim as production

# セキュリティアップデートの適用
RUN apt-get update && apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends \
		sudo \
		bsdutils \
		util-linux \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

ARG WORKDIR
ENV PATH=${WORKDIR}/vendor/bin:$PATH \
	PYTHONPATH=${WORKDIR}/vendor/bin:${WORKDIR} \
	PYTHONUSERBASE=${WORKDIR}/vendor
WORKDIR ${WORKDIR}

# Create the user
ARG USERNAME
ARG HOMEDIR
ARG USERID
ARG GROUPID
RUN <<-EOF
	echo "Create User = ${USERID}. Group = ${GROUPID}"
	groupadd -g ${GROUPID} ${USERNAME}
	useradd -m -s /bin/bash -d ${HOMEDIR} -u ${USERID} -g ${GROUPID} ${USERNAME}
	mkdir -p /etc/sudoers.d/
	echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME}
	chmod 0440 /etc/sudoers.d/${USERNAME}
EOF
USER ${USERNAME}

# ビルドステージからコピーした依存関係とアプリケーションのソースコードをコピー
COPY --from=builder ${WORKDIR} ${WORKDIR}

# 環境変数の設定
# Pythonがpycファイルとdiscへの書き込みを行わないようにする
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# アプリケーションの起動コマンド
CMD ["-c", "while true; do sleep 30; done"]
