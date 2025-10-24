#!/bin/bash

# Install core
yarn setup:clean

# Testnet
cd packages/core
yarn sth config:publish --network=testnet --reset
yarn full:testnet