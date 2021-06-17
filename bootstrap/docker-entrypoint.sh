#!/usr/bin/env bash
set -e
# set -ex

if [[ -z $1 ]]; then
  printf 'Usage: %s project_name \n' $(basename ${0})
  exit 1
fi

echo -e "Nuxeo Developer Environment bootstrap:"
echo -e "\n> NOS Credentials"
echo -e "Used to access NOS Studio project"
echo -e "Create one following: https://connect.nuxeo.com/nuxeo/site/connect/tokens"
read -p "- NOS Username: " STUDIO_USERNAME
read -s -p "- NOS Token: " STUDIO_TOKEN
echo "" # Add extra carret return; `read -s` silent it.
read -p "- NOS Project: " STUDIO_PROJECT
echo -e "\n> Nexus UserToken"
echo -e "Used to access Nexus artifacts"
echo -e "Create one following: https://packages.nuxeo.com/#user/usertoken"
read -p "- Nexus User Code: " NEXUS_USER
read -s -p "- Nexus Pass Code: " NEXUS_TOKEN
echo "" # Add extra carret return; `read -s` silent it.
echo -e "\n> Nuxeo Instance CLID"
echo "Content of an instance.clid file while replace '\n' carret return with '--'."
read -p "- Instance CLID: " NUXEO_CLID

echo -e "\nCreating projet ${1}..."

PROJECT=${1}

WORKSPACE=/home/nuxeo/workspace

CLI_B_OPTS=${CLI_B_OPTS:-}
CLI_BOOTSTRAP=${NUXEO_BOOTSTRAP:-multi-module single-module package}
DOCKER_REPOSITORY=docker.packages.nuxeo.com/nos-dev

STUDIO_PROJECT=${STUDIO_PROJECT:-}
STUDIO_USERNAME=${STUDIO_USERNAME:-}
STUDIO_TOKEN=${STUDIO_TOKEN:-}

# Ensure folder is empty
if [ "$(ls -A ${PROJECT} >&/dev/null)" ]; then
  echo "Target directory (${PROJECT}) is not empty."
  exit 1
fi

# Run fixuid
eval $(fixuid -q)

mkdir -p ${PROJECT} && cd ${PROJECT}

# Bootstrap Project
# TODO Disable end message, to KISS without displaying useless msg
echo "Bootstraping a new Nuxeo Project..."
bash -e -c "nuxeo -n b ${CLI_B_OPTS} ${CLI_BOOTSTRAP}"

# Register Instance
bash -c "nuxeo -b -n studio link --params.username=${STUDIO_USERNAME} --params.password=${STUDIO_TOKEN} --params.project=${STUDIO_PROJECT} --params.settings=false"

# Create Docker Module
bash -e -c "nuxeo -b -n b ${CLI_B_OPTS} docker devcontainer --params.username=${STUDIO_USERNAME} --params.password=${STUDIO_TOKEN} --params.nexusUser=${NEXUS_USER} --params.nexusToken=${NEXUS_TOKEN}"

# Create .env.nuxeo-cli file
cat >.env.nuxeo-cli <<EOF
NOS_USERNAME=${STUDIO_USERNAME}
NOS_TOKEN=${STUDIO_TOKEN}
NOS_PROJECT=${STUDIO_PROJECT}

NEXUS_USER_CODE=${NEXUS_USER}
NEXUS_PASS_CODE=${NEXUS_TOKEN}

NUXEO_CLID=${NUXEO_CLID}
EOF

# Create start-shell.sh
cat >start-shell.sh <<EOF
#!/usr/bin/env sh
set -e

realpath() {
  [[ \$1 = /* ]] && echo "\$1" || echo "\$PWD/\${1#./}"
}

CWD=\$(realpath \$(dirname \$0))

exec docker run --rm -it \
  -u "\$(id -u):\$(id -g)" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  --mount "type=bind,source=\${CWD},destination=${WORKSPACE}/${PROJECT}" \
  --mount "type=volume,source=${PROJECT}_m2repo,destination=/home/nuxeo/.m2/repository" \
  ${DOCKER_REPOSITORY}/shell-project:latest
EOF
chmod +x start-shell.sh

# Create start-ide.sh
cat >start-ide.sh <<EOF
#!/usr/bin/env sh
set -e

realpath() {
  [[ \$1 = /* ]] && echo "\$1" || echo "\$PWD/\${1#./}"
}

B64_PROJECT=$(echo -n "${STUDIO_PROJECT}" | md5sum | awk '{print $1}')
CWD=\$(realpath \$(dirname \$0))

exec docker run --rm -it \
  -u "\$(id -u):\$(id -g)"         \
  -p 8080:8080 \
  -v "/var/run/docker.sock:/var/run/docker.sock"  \
  --mount "type=bind,source=\${CWD},destination=${WORKSPACE}/${PROJECT}" \
  --mount "type=volume,source=${PROJECT}_m2repo,destination=/home/nuxeo/.m2/repository" \
  --mount "source=cs-settings-\${B64_PROJECT},target=/home/nuxeo/.local/share/code-server/User" \
  ${DOCKER_REPOSITORY}/code-server-project:latest
EOF
chmod +x start-ide.sh

# TODO Create start-(ide|shell).cmd scripts too?

# End Message
echo ""
echo ""
echo "🍻 Congrats! Your environment is ready to go."
echo "What to do next?"
echo "  - Build the project Docker image and then open ${PROJECT} folder with VSCode then let the devcontainer magic happenning..."
echo "  - Start Online IDE: ./${PROJECT}/start-ide.sh"
echo "  - Start Dev Shell: ./${PROJECT}/start-shell.sh"
echo "  - Use VS Code Remote-Container extension: ./${PROJECT}/start-shell.sh then \"Remote-Container: Attach to Running Container\" from VS Code"
echo "  - Use your prefered IDE: open ./${PROJECT}/pom.xml"
echo ""

exit 0
