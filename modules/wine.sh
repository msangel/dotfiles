#!/bin/bash
# Wine sectiom
#  Install MS Office on Wine
#  General instruction: https://gist.github.com/raelgc/4ccc023830bfd12c0227
#   1) Get wine
#   > sudo apt-get install playonlinux samba winbind
#   wine can be installed from playonlinux menu, or:
#   > sudo dpkg --add-architecture i386
#   > sudo add-apt-repository ppa:wine/wine-builds && sudo apt-get update
#   > sudo apt-get install --install-recommends winehq-devel
#   2) MS installer
#     Installer location:
#   gdrive://external/installs/ms/
#   or
#   google:// MICROSOFT.OFFICE.2010.SELECT.EDITION.SP1.VOLUME.X86.DVD.RUSSIAN-KROKOZ
#   note: rename it to normal short name
#   3) Procedure
#   mount it:
#   > sudo mkdir /media/iso
#   > sudo mount -o loop path/to/iso/file/YOUR_ISO_FILE.ISO /media/iso
#   close descriptors:
#   > sudo fuser -km /media/iso
#   > sudo umount /media/iso
#   install from setup.exe (not a disk)
