# Portable PS Monitor Website (PPSMW)

A website generated by PowerShell to monitor devices (Physical/Virtual/Virtual Host (specifically Hyper-v)). Either keep a constant ping or get some basic details of the remote devices. In order to get the remote details, the script assume network credentials are available for all monitored resources.

### (Simplified) Installation Instrcutions
Download files  
Unzip files  
Unblock files (Get-ChildItem -File .\PortablePSMonitorWebSite-main\ -Recurse | Unblock-File)  
Place files in a PS module path ($env:PSmodulepath -split ';')  
Update path in module file (first line; psm1 extension) to the path you are placing the files in  

### Example Command

Invoke-PPSMWOrchestration  
-RootDirectoryPath "$env:USERPROFILE\Desktop\PPSMW"  
-SourceFiles "$env:USERPROFILE\Desktop\PortablePSMonitorWebSite"   
-Devices (Get-Content "$env:USERPROFILE\Desktop\AllComputers.txt")  

> [!NOTE]
> The module will have to be imported first. Also, if you run into an issue with the individual pages not being created, that is due to one of the script not being imported when trying to run jobs. Working on that. Best suggesting is to add the folder to a path that is within your PowerShell $env:PATH. Also, update the module file. Specify the directory location of the files.

### Home page

You should see something similar to the following:

![homepage](https://github.com/ozruxo/PortablePSMonitorWebSite/blob/main/exampleimages/homepage.png)

### Hover over device name

When hovering over the name of the device. A simple status message will appear.

![hover device name](https://github.com/ozruxo/PortablePSMonitorWebSite/blob/main/exampleimages/hover-hp.png)

### Selecting device names

When selecting the name of a device through out the web site, another page should load. Like one of the following:

![individual page](https://github.com/ozruxo/PortablePSMonitorWebSite/blob/main/exampleimages/individual.png)
![404](https://github.com/ozruxo/PortablePSMonitorWebSite/blob/main/exampleimages/404.png)

### Virtual host page

The page should look like the following:

![virtual host](https://github.com/ozruxo/PortablePSMonitorWebSite/blob/main/exampleimages/virtualhost.png)

> [!NOTE]
> The review section will populate the name of a virtual machine, when the OS disk has less than 15% virtual disk space available. 

>[!NOTE]
> Why are there X's? Well, I didn't want to account for devices that we not originally on the list for monitoring. So, you get greated with the 404 page.

### Selecting the images on the virtual host page

When selecting the imgaes on the virtual host page you will see very brief input on the device. Both for the VM and the Host.

![vm](https://github.com/ozruxo/PortablePSMonitorWebSite/blob/main/exampleimages/vm.png)

> [!NOTE]
> You may have noticed 3 ellipses. First is to indicate the computer is ping able. Second is to indicate Access to the system. Third is to indicate the disk status of being greater that 15%.

> [!Note]
> If you see a combination of 🟢 🔴 🔴. The computer is pingable, but PowerShell is not able to reach the system. When applicable, reboot the system or spend a bunch of time trouble shooting why ps session is not working 🙂.

### Single page

You should see something similar to the following:

![single](https://github.com/ozruxo/PortablePSMonitorWebSite/blob/main/exampleimages/single.png)

# Issues

I am sure there are some.
