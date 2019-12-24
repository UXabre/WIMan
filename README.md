![Logo](/doc/logo.png?raw=true "Logo")

# WIMan
WIMan is a Windows Image Generator for The Foreman. It creates both the WinPE file as well as the Windows images with a zero-hassle approach as all batteries are included

 - A single parameterless command!
 - Beautifies WinPE and styles it with the foreman logo
 - Optimizes the images as much as possible by extracting the individual images &rarr; Results in a smaller images to apply and download!
 - Includes updates if you want
 - Includes additional drivers
 - Follows a convention approach
 - WinPE is not mandatory in the sense that this script allows to use a WinPE image shipped with the original ISO automatically
 - If you want, though, WinPE can be automatically installed and used

# Installation
Simply Clone this repository to your local machine and place a windows ISO inside the "sources/&lt;arch&gt;/&lt;arbitrary-folder-name&gt;/" directory and run "./GenerateWIM.ps1"


![In progress](/doc/progress.png?raw=true "In progress")

# Usage

 - Copy all the content from the within the "finalized" folder to the webserver serving your windows images.
 - Configure your Foreman Installation Media to point to this folder. As you can see from the folder structure, we included the architecture in the path!

# to-do
 - A manifest ini is now created to tell the consumer in which WIM-file an image is stored (based on the optimization level); however at this point in time the template does not consume this manifest file!

# Result
![Result PXE](/doc/pxe.png?raw=true "PXE")
Early measurements showed that deploying a windows server core 2016 takes around 6 minutes from boot to final boot!

# Want to join forces?
GREAT! Just Fork off and send me a PR; I'd be happy to review and include your work!

# PARENTAL ADVISORY
This script is in its early stages, meaning it will get better in time but you might encounter some issues (although I did my very best to test this thoroughly).

If you do find an issue, please share it here so we can take a look!