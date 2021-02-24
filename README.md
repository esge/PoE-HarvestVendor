# PoE-HarvestVendor

```diff
- Only works if PoE is in WINDOWED / WINDOWED BORDERLESS mode, doesnt work in Fullscreen
```
# [DOWNLOAD HERE](https://github.com/esge/PoE-HarvestVendor/releases/latest)

⚠️ It's a BETA there will be issues and lacking features :)

- Convert your Horticrafting station crafts into a post, almost in a smart way
- Using AHK to call Capture2Text OCR tool on selected screen region
- Then parsing the text
- It works as long as OCR doesn't do stupid stuff

## FIRST TIME INSTALL
1. Download 4.6.2 release of Capture2Text: https://sourceforge.net/projects/capture2text/files/Capture2Text/
2. Download last release of HarvestVendor: https://github.com/esge/PoE-HarvestVendor/releases/latest
3. Create a new folder and put HarvestVendor (ahk or exe) and extracted Cature2text folder into it
    ![](examples/folder.png)

4. Run HarvestVendor `.ahk`/`.exe` 🎉

- If you download the `.ahk` file:
    - Requires AHK 1.1.27+
    - link to current [AHK 1.1.33](https://www.autohotkey.com/download/ahk-install.exe)

## UPDATING
- just get the new HarvestVendor file from the DONWLOAD HERE link, replace the existing and reload

## HOW TO USE
- Default Hotkeys:
    - CTRL + SHIFT + G - opens GUI
    - CTRL + G - starts scan

- When you start scan, Drag select area with the craft text
![Recommended area](examples/snapshotArea.png)

- wait a moment and crafts will be loaded into the UI
- set prices if you wish
- select your league and so on
- click Create Posting for the section you wish to
- now you have a Discord formatted message in clipboard
![](examples/exampleMessage.png)

## Settings
- if you game on monitor thats not primary in windows you can change it in settings
- if you use display scaling in wodnwos, you need to change it in settings
- if you don't like the default keys, surprise, you can change them in settings

## List of features
- Uses OCR to identify crafts from Horticrafting station
- Option to rescan last scanned area
- Counts crafts if there are multiple of the same
- Sorts them into groups based on TFT Discord rules
- Allows to set prices for crafts
- Line of custom text (be careful to not write anything that triggers the discord bot)
- Checkbox "Can Stream"
- box for IGN if you want to add that to the post
- Generates formatted discord post
- Remembers prices
- Remembers loaded crafts
- Outputs Log.csv of sold crafts (entry triggered by Shift+click on the rows delete button)

## FAQ
**Q. Why does it show lv00?**  
A. If its unable to read the level it says lv00. You can try delete the craft and rescan it. Or fix the level manualy.

**Q. I'm getting error about "WinInet-something"**  
A. This one?  
![](examples/https-error.png)  
Get curl binary from [here](https://curl.se/windows/), extract curl.exe from archive and put in into directory with ahk script. Script now will use this tool for version checking.

**Q. A craft i have in horticrafting station is not showing up in the result**  
A. There are 2 possible reasons:
  1. text recognition was too messed up and i couldn't recognize the craft  
    - Solution: Run the scan again and select only that one craft
  2. I arbitrarily decided its not worth to list that one, if you want it listed, contact me or open an issue. [List of ignored crafts](https://github.com/esge/PoE-HarvestVendor/wiki/Crafts-that-are-being-ignored)

## Used libraries
- http://capture2text.sourceforge.net/ for OCR
- https://github.com/cocobelgica/AutoHotkey-JSON jxon function embeded in the main file

---
### If you got all the way here and want to throw some beer money my way
[PayPal.me link](https://www.paypal.com/paypalme/Esge1)
