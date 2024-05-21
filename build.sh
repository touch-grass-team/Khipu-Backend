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
pip install -r requirements.txt
pip3 install nuitka || (echo "You must install python first!" && exit 1)
python3 -m nuitka --remove-output --output-dir="$BUILD_DIR" --onefile main.py -o khipu || (echo "Build failed!" && exit 1)
pip3 uninstall -y nuitka
echo "Finished! Binary file is in $(pwd)/$BUILD_DIR"
deactivate
rm -rf venv
