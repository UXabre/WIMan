#  VMware Drivers

locate the folder `C:\Program Files\Common Files\VMware\Drivers` on a machine with VMware Tools installed.

You should get a folder list like those:
- efifw
- memctl
- mouse
- pvscsi
- video_wddm
- vmci
- vmxnet3
- vss

copy all folders from there to your WiMan workspace:
- WinPE Enviroment: `wiman\winpe\drivers`
- your OS Images: eg. `wiman\sources\x86_64\2019\drivers`
