#!/bin/sh

brew install cocoapods

cd $CI_WORKSPACE

pod install
cp Xliffie/APIKeys.sample.h Xliffie/APIKeys.h
