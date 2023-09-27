FROM akorn/luarocks:luajit2.1-alpine

WORKDIR /home

RUN apk add gcc musl-dev
RUN luarocks install lua-cjson

COPY . .

ENTRYPOINT [ "lua", "test.lua" ]