#!/bin/bash
set -e

FRP_VERSION="0.47.0"

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--server)
      SERVER_ADDRESS="$2"
      shift 
      shift 
      ;;
    -p|--port)
      SERVER_PORT="$2"
      shift 
      shift 
      ;;
    -t|--token)
      SERVER_TOKEN="$2"
      shift 
      shift 
      ;;
    -n|--name)
      NAME="$2"
      shift 
      shift 
      ;;
    -y|--type)
      TYPE="$2"
      shift 
      shift 
      ;;
    -i|--localip)
      LOCAL_IP="$2"
      shift 
      shift 
      ;;
    -o|--localport)
      LOCAL_PORT="$2"
      shift 
      shift 
      ;;
    -r|--remoteport)
      REMOTE_PORT="$2"
      shift 
      shift 
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift 
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}"

FRP_RELEASE_NAME="frp_${FRP_VERSION}_linux_amd64.tar.gz"
FRP_DIRECTORY_NAME="frp_${FRP_VERSION}_linux_amd64"
FRP_RELEASE_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FRP_RELEASE_NAME}"
curl -fsLO "$FRP_RELEASE_URL"
tar -xzf "${FRP_RELEASE_NAME}"
rm "${FRP_RELEASE_NAME}"
mv "${FRP_DIRECTORY_NAME}" "/opt/frp"
BINDIR="/opt/frp"

echo """[common]
server_addr = ${SERVER_ADDRESS}
server_port = ${SERVER_PORT}
token = ${SERVER_TOKEN}

[${NAME}]
type = ${TYPE}
local_ip = ${LOCAL_IP}
local_port = ${LOCAL_PORT}
remote_port = ${REMOTE_PORT}
""" > "${BINDIR}/frpc.ini"

echo """[Unit]
Description = frp client
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
ExecStart = /opt/frp/frpc -c /opt/frp/frpc.ini
Restart=on-failure
RestartSec=5s

[Install]
WantedBy = multi-user.target
""" > "${BINDIR}/frpc.service"

cp "${BINDIR}/frpc.service" "/etc/systemd/system/frpc.service"
systemctl daemon-reload
systemctl start frpc
systemctl enable frpc
