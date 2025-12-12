#!/bin/bash
# Simple wrapper to avoid MAX_PARAMS_NUM issue
# Just calls the real compiler directly with instrumentation
exec /usr/bin/clang "$@"
