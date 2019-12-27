#!/usr/bin/env python3.6

import sys

from getpass import getpass

from github3.github import GitHubEnterprise

if len(sys.argv) < 2:
  print("Usage: %s <repository name>" % sys.argv[0])
  sys.exit(1)

repository_name = sys.argv[1]
username = input("GHE appliance username: ")
password = getpass("GHE appliance password: ")


ghe = GitHubEnterprise(
  url="https://github.nchub.net",
  username=username,
  password=password
)


repository = ghe.repository('cars-sm', repository_name)

for key in repository.keys():
  print("================")
  print(key.title)
  print("================")
  print(key.key)
  print("")
