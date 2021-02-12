# PoE-HarvestVendor

⚠️ It's a BETA there will be issues and lacking features :)

- Convert your Horticrafting station crafts into a post, almost in a smart way
- Using AHK to call Capture2Text OCR tool on selected screen region
- Then parsing the text
- It works as long as OCR doesn't do stupid stuff

## Getting started

- Requires [AHK 1.1.33.02](https://www.autohotkey.com/download/ahk-install.exe)
    - not that it wont work on older, but there was a bug where it would say that a piece of code is unreachable in a switch/case and you will get a warning popup everytime you launch it
    - the error message it shows on older versions is:

```
Warning: This line will never execute, due to Return precceding it
```

- Download last release of Capture2Text: https://sourceforge.net/projects/capture2text/files/Capture2Text/
- Download last release: https://github.com/esge/PoE-HarvestVendor/releases/latest
- Create a new folder with the `.ahk` script
- Extract the Capture2Text archive in that same folder
- Run `.ahk` script 🎉

## Usage

- To start extracting your Horticrafts you have to press: **CTRL + SHIFT + G**

  (You can also start capture directly without using window by using: **CTRL + G**)
- The tool window will appear, you have to select your league, add your IGN, then start the scanning
  
![Tool window](examples/Description.png)
- After clicking on "Add crafts", you have to drag from the top left corner of your craft to the bottom right. Here is
  the recommended area to select:
  
![Recommended area](examples/snapshotArea.png)
- You now have to set all prices for your crafts
- Then you can click on "Create Posting" buttons to copy your selling message, here is an example:
```
WTS Ritual Softcore 
  1x Remove Influence lv83 - 100c
  2x Remove Speed lv83 - 2ex
```

# FAQ
**Q. A craft i have in horticrafting station is not showing up in the result**  
A. I arbitrarily decided its not worth to list that one, if you want it listed, contact me or open an issue. [List of ignored crafts](https://github.com/esge/PoE-HarvestVendor/wiki/Crafts-that-are-being-ignored)

## Used libraries

- http://capture2text.sourceforge.net/ for OCR
- https://github.com/cocobelgica/AutoHotkey-JSON jxon function embeded in the main file
