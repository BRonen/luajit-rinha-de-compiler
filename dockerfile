FROM ubuntu

WORKDIR /home

RUN apt update && apt install bash luajit luarocks -y

RUN luarocks install lua-cjson

COPY . .

ENTRYPOINT [ "bash" ]