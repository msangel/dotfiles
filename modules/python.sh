#!/bin/bash

# docker run -it ubuntu /bin/bash
# docker system prune -a --volumes
# do not upgrade pip, use venv
# https://stackoverflow.com/questions/49836676/error-after-upgrading-pip-cannot-import-name-main
# https://gist.github.com/Geoyi/d9fab4f609e9f75941946be45000632b
apt install python3-pip
