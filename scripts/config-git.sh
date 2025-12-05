#!/usr/bin/env bash
git config merge.sops.driver 'sops merge %A %O %B'
git config merge.sops.name 'sops-merge-driver'
