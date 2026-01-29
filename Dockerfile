# 处方生成服务器 Dockerfile
# 优化镜像大小，支持中文LaTeX编译

# 第一阶段：构建LaTeX环境
FROM oven/bun:alpine AS latex-builder

# 安装LaTeX和相关依赖
RUN apk add --no-cache \
    texlive-xetex \
    texlive-latex-extra \
    texlive-latex-recommended \
    texlive-fonts-extra \
    texlive-lang-chinese \
    texlive-pstricks \
    wqy-zenhei \
    font-noto-cjk \
    ghostscript \
    make \
    perl \
    && mkdir -p /usr/share/texmf-dist/tex/latex

# 第二阶段：应用构建
FROM oven/bun:alpine

# 安装运行时依赖
RUN apk add --no-cache \
    texlive-xetex \
    texlive-latex-extra \
    texlive-latex-recommended \
    texlive-fonts-extra \
    texlive-lang-chinese \
    texlive-pstricks \
    wqy-zenhei \
    font-noto-cjk \
    ghostscript \
    # 清理缓存以减小镜像大小
    && rm -rf /var/cache/apk/*

# 创建工作目录
WORKDIR /app

# 复制package.json和bun.lock
COPY package.json bun.lock ./

# 安装依赖
RUN bun install --production

# 复制应用程序文件
COPY index.js ./
COPY signPng.js ./
COPY index.html ./
COPY styles.css ./
COPY tex/ ./tex/

# 创建必要的目录
RUN mkdir -p temp

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3000
ENV MAX_CONCURRENT_COMPILATIONS=5
ENV COMPILATION_TIMEOUT_MS=30000

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD bun -e "import('node:http').then(http => http.get('http://localhost:3000/status', res => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1)))"

# 启动命令
CMD ["bun", "run", "index.js"]