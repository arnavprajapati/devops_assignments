#!/bin/bash

echo "===== BASIC INFO ====="
echo "User: $(whoami)"
echo "Host: $(hostname)"

echo ""
echo "===== SYSTEM INFO ====="
echo "Date: $(date)"
echo "Current Directory: $(pwd)"

echo ""
echo "===== FILES ====="
ls
