# Announcement:
This mod is not dead, I'm merely going through financial difficulties as a full time student and can't fix my PC to continue working on it.
If you would like to support this passion project, I deeply appreciate all donations at https://ko-fi.com/balakesuperwow

[<img width="646" height="250" alt="image" src="https://github.com/user-attachments/assets/a1dc435c-78b9-4be3-bd8b-f37c843193d9" />
](https://www.paypal.com/ncp/payment/33QB5LEXN9KVC
)

# SuperWoW
SuperWoW is a launcher/mod made for the 1.12.1 version of World of Warcraft with the purpose of fixing client bugs and expanding the lua-based API used by user interface addons.

# FAQ
- Q: How does this mod work?
  
A: SuperWoW is a dll injection. Executing the launcher launches the base game (WoW.exe file in the same directory) and injects a dll (dynamic link library). This gives the mod access to the game's allocated memory within your RAM. The mod edits the process' memory to change certain variables and instructions, and to make use of code caves and function detouring. The program does not alter any computer files, of the game or otherwise, not permanently nor temporarily. launching the client from the original .exe file will launch the exact same game you had on your game directory before you used the mod.


- Q: Are dll injections safe?
  
A: Dlls have legitimate use cases in Software extensibility, such as the benchmarking & screen capture tool Fraps. However, it can also be used for malicious purposes to bypass security measures and steal sensitive information. It's essential to understand the potential risks, vulnerabilities, and implications associated with closed source DLL injection activities.


- Q: Why is this program closed source?
  
A: Making the mod open source [by definition](https://opensource.org/osd) licenses it for commercial use without requiring permission, and permits the creation of derived works that can very easily bypass the countermeasures placed within this mod to stop it being used for automation, cheating, or any other methods to gain a **direct** gameplay advantage.


- Q: Does this mod give any gameplay advantage?
  
A: It does that indirectly by improving the user interface, making it more direct and require less inter-player communication through hidden messages that drain both player and server resource. The functionalities it adds are recreations of Classic Client functionalities familiar to people who play on 1.12.1 servers using Hermes Proxy.


- Q: Is the mod stable and bug free?

A: There is no guarantee of stability. It is greatly appreciated to report all bugs or crashes in this repository's bugtracker, copying or screenshotting the crash log and detailing reproduction steps.


- Q: Will this mod work with X mod / addon / server

A: There is no guarantee that the mod is compatible with any specific mod, addon, or server's custom client. [It is greatly appreciated to document everything that is compatible or not compatible with the mod in the bugtracker](https://github.com/balakethelock/SuperWoW/wiki/Compability-with-other-mods).


- Q: Is this mod allowed by X server? Will it get cought by anti-cheat?
  
A: The mod makes no attempt at hiding itself from Warden, any server can easily ban for it if they choose to do so. Use at your own discretion.

# Instructions
- Download the [release](https://github.com/balakethelock/SuperWoW/releases/tag/Release), unzip and place SuperWoWhook.dll and SuperWoWlauncher.exe in your game directory, in the same folder that contains the WoW.exe file. If your game's client executable is not named exactly "WoW.exe", you have to create a copy of it and name that new file WoW.exe
- Download the [compability addon](https://github.com/balakethelock/SuperAPI) and its modules from their corresponding repositories and install them as you would typical addons, in Interface\Addons folder making sure to remove the "-master" suffix appended by github.
- If you want to use the [custom Selection Circle styles](https://github.com/balakethelock/SuperWoW/wiki/Changelog#14042024--110:~:text=Added%20SelectionCircleStyle%20CVar), you will need to grab the textures for it from [here](https://github.com/balakethelock/SuperWoW/releases/tag/Patch) 
- Run SuperWoWlauncher.exe to play the game

# Documentation
https://github.com/balakethelock/SuperWoW/wiki

# Troubleshooting

- Read the [Installation Guide](https://github.com/pepopo978/SuperwowInstallation). In case of VanillaFixes or SuperWoW launcher not starting with no error (Windows) fix by Orfc

    1) Go to Control Panel > System and Security > System > Advanced system settings. Under Performance, click Settings, then the Data Execution Prevention tab.

    2) Select Turn on DEP for all programs and services except those I select, and add WoW.exe to the list. (Remember to remove this later if it doesn’t help you.)


# Copyright © 2024-2025 Balake. All rights reserved.

This program is licensed for personal use only. Commercial
use, distribution, modification, or any form of exploitation
for profit is strictly prohibited without the express written
permission of the copyright holder.

World of Warcarft is the intellectual property of Blizzard
Entertainment, Inc. This mod is not affiliated with or
endorsed by Blizzard Entertainment in any way.

This mod is not associated with or designed for any private
server or unauthorized service.

This mod is created and distributed under the principles of
fair use as defined in 17 U.S.C. § 107, including commentary,
criticism, and transformative use for personal enjoyment and
educational purposes.

This mod is provided "as is," without warranty of any kind.
