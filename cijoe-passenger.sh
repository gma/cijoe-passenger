#!/bin/bash

WWW_ROOT=${WWW_ROOT:-/var/apps/cijoe}
REPO_ROOT=${REPO_ROOT:-/var/apps/cijoe-repos}
GITHUB_USER=${GITHUB_USER:-gma}

# Functions

usage()
{
    echo "Usage: $(basename $0) <project> [branch] [repo-url]" 1>&2
    exit 1
}

setup_root_directories()
{
    mkdir -p $REPO_ROOT
    mkdir -p $WWW_ROOT
    cat > "$REPO_ROOT/config.ru" <<'EOF'
$project_path = File.dirname(__FILE__) + "/app"
require 'cijoe'

# setup middleware
use Rack::CommonLogger
# configure joe
CIJoe::Server.configure do |config|
  config.set :project_path, $project_path
  config.set :show_exceptions, true
  config.set :lock, true
end

run CIJoe::Server
EOF
}

project_dir()
{
    echo "$PROJECT-$BRANCH"
}

clone_project()
{
    mkdir -p $REPO_ROOT/$(project_dir)
    pushd $REPO_ROOT/$(project_dir) >/dev/null
    if [ ! -d app ]; then
        git clone $REPO app
        pushd app >/dev/null
        git config --add cijoe.branch $BRANCH
        popd >/dev/null
    fi
    popd >/dev/null
}

create_rack_app()
{
    mkdir -p $WWW_ROOT/$(project_dir)
    ln -sf $REPO_ROOT/$(project_dir) $WWW_ROOT/$(project_dir)/public
    pushd $REPO_ROOT/$(project_dir) >/dev/null
    mkdir -p public
    ln -sf ../config.ru
    popd >/dev/null
}

# Main program

[ -n "$DEBUG" ] && set -x
set -e

PROJECT=$1
BRANCH=${2:-master}
REPO=${3:-git://github.com/$GITHUB_USER/$PROJECT.git}
[ -z "$PROJECT" ] && usage

setup_root_directories
clone_project
create_rack_app
