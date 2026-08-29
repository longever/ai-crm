# ============================================================
# Twenty server —— 以本地源码(0.2.1)构建，与 twenty-front 同源版本
# 目的：根治陈旧镜像(twentycrm/twenty-server:latest, 2024) 缺 /client-config
#       路由导致前端报「无法访问后端」。
# 构建上下文：docker-compose.twenty.yml 的 build.context = ./twenty
# ============================================================
FROM node:24-bookworm-slim

WORKDIR /app

# 原生模块(bcrypt 等)编译所需工具链
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

# 拷贝本地源码（.dockerignore 已排除 node_modules/.git/.env/.nx/cache）
COPY . .

# 安装工作区依赖（node-modules linker，与源码 .yarnrc.yml 的 yarnPath 一致）
# 使用 .yarn/releases 中的 yarn 4.13.0，避免 corepack 版本歧义
RUN node .yarn/releases/yarn-4.13.0.cjs install

# 构建 twenty-server（nx 会先构建其依赖包 twenty-client-sdk 等，再 nest build）
ENV NODE_OPTIONS=--max-old-space-size=4096
RUN node .yarn/releases/yarn-4.13.0.cjs nx build twenty-server

# 运行时
WORKDIR /app/packages/twenty-server
ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/main"]
