#!/bin/sh

BUILD_DIR='build'
echo "Building an application..."
if [ ! -d "$BUILD_DIR" ]; then
  echo "Creating build directory..."
  mkdir build
fi

pip install nuitka || (echo "You must install python first!" && exit 1)
python -m nuitka --remove-output --output-dir="$BUILD_DIR" --onefile main.py -o khipu || (echo "Build failed!" && exit 1)
pip uninstall -y nuitka
echo "Finished! Binary file is in $(pwd)/$BUILD_DIR"
