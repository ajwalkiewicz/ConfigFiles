#!/bin/bash
# Python project setup

if [ "$#" -eq 0 ]; then
  echo "Please provide a procejt name!!";
  exit 1;
fi

mkdir docs  tests $1

touch $1/__init__.py
touch $1/__main__.py
touch "$1/$1\.py"
touch "$1/test_$1\./py"
touch setup.py README.md


