#!/bin/sh

BUILD_DIR='build'
echo "Building an application..."
if [ ! -d "$BUILD_DIR" ]; then
  echo "Creating build directory..."
  mkdir build
fi

set -e
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
python3 -m nuitka --remove-output --output-dir="$BUILD_DIR" --onefile main.py -o khipu || (echo "Build failed!" && exit 1)
pip3 uninstall -y nuitka
echo "Finished!"
deactivate
rm -rf venv
