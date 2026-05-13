#!/bin/bash
# This script bootstraps the TOTO API base image.

set -o errexit

sleep 60

echo "Install Google Ops Agent"
sudo mkdir -p /app/google-ops-agent/
sudo curl -sSo /app/google-ops-agent/add-google-cloud-ops-agent-repo.sh https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash /app/google-ops-agent/add-google-cloud-ops-agent-repo.sh --also-install
sudo mv /tmp/google-ops-agent-config.yaml /etc/google-cloud-ops-agent/config.yaml
sudo rm -rf /app/google-ops-agent
sudo service google-cloud-ops-agent restart
sudo service google-cloud-ops-agent status

echo "Fix issue with google-cloud-ops-agent installation"
if ! sudo grep -q "signed-by" /etc/apt/sources.list.d/google-cloud-ops-agent.list; then sudo sed -i 's/deb/& \[signed-by=\/etc\/apt\/keyrings\/packages.cloud.google.com.gpg\]/' /etc/apt/sources.list.d/google-cloud-ops-agent.list; fi
sudo curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | sudo gpg --dearmor -o "/etc/apt/keyrings/packages.cloud.google.com.gpg"

echo "Updating to the latest versions of the packages"
sudo apt -qy update
sudo DEBIAN_FRONTEND=noninteractive apt -qy upgrade

echo "Install needed packages for the installation"
sudo DEBIAN_FRONTEND=noninteractive apt -qy install $PACKAGE

echo "Install Docker"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt -qy update
sudo DEBIAN_FRONTEND=noninteractive apt -qy install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl restart docker

echo "Install the UA client"
sudo DEBIAN_FRONTEND=noninteractive apt -qy install ubuntu-advantage-tools

sleep 30

echo "Set up the Ubuntu Security Guide"
sudo ua enable usg || true
sudo DEBIAN_FRONTEND=noninteractive apt -qy install usg

echo "Fix using tailoring file"
sudo usg fix --tailoring-file tailor.xml || true

echo "Audit using tailoring file"
sudo usg audit --tailoring-file tailor.xml || true

echo "Install TOTO startup runner"
cat <<'EOF' | sudo tee /usr/local/bin/toto-runner.sh
#!/bin/bash
set -euo pipefail

METADATA_BASE="http://metadata.google.internal/computeMetadata/v1"
METADATA_HEADER="Metadata-Flavor: Google"

get_metadata_attr() {
  local key="$1"
  curl -fsH "$METADATA_HEADER" "${METADATA_BASE}/instance/attributes/${key}" || true
}

PROJECT_ID="$(curl -fsH "$METADATA_HEADER" "${METADATA_BASE}/project/project-id" || true)"
IMAGE="$(get_metadata_attr "toto_container_image")"
PORT="$(get_metadata_attr "toto_port")"
REGION="$(get_metadata_attr "toto_region")"
HUB_PROJECT_ID="$(get_metadata_attr "toto_hub_project_id")"

if [ -z "$IMAGE" ]; then
  IMAGE="us-docker.pkg.dev/med-shared-srv-nprd/med-shared-srv-nprd-ard-uscontainerregistry/beacon-api:latest"
fi

if [ -z "$PORT" ]; then
  PORT="8080"
fi

if [ -z "$REGION" ]; then
  REGION="us-east4"
fi

if [ -z "$HUB_PROJECT_ID" ]; then
  HUB_PROJECT_ID="$PROJECT_ID"
fi

/usr/bin/docker rm -f toto-api >/dev/null 2>&1 || true
/usr/bin/docker pull "$IMAGE"
/usr/bin/docker run -d \
  --name toto-api \
  --restart unless-stopped \
  --network host \
  -e HUB_PROJECT_ID="$HUB_PROJECT_ID" \
  -e REGION="$REGION" \
  -e PORT="$PORT" \
  "$IMAGE"
EOF

sudo chmod 755 /usr/local/bin/toto-runner.sh

cat <<'EOF' | sudo tee /etc/systemd/system/toto-api.service
[Unit]
Description=TOTO API container runner
Requires=docker.service
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/toto-runner.sh
ExecStop=/usr/bin/docker rm -f toto-api

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable toto-api.service
