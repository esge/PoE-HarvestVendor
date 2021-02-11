# Its BETA there will be issues and lackign features :)
 - Download https://github.com/esge/PoE-HarvestVendor/releases/tag/0.2.2
 - Requires AHK 1.1.33.02 
   - not that it wont work on older, but there was a bug where it would say that a piece of code is unreachable in a switch/case and you will get a warning popup everytime you launch it
   - the error message it shows on older versions is:   
        Warning: This line will never execute, due to Return precceding it
 
# PoE-HarvestVendor
  - Convert your Horticrafting station crafts into a post, almost in a smart way
  - Using ahk to call capture2text OCR tool on selected screen region
  - then parsing the text
  - it works as long as OCR doesnt do stupid stuff

# Description

<img src="examples/Description.png">

- Recommended area to select
<img src="examples/snapshotArea.png">
 
- example output message
```
WTS Ritual Softcore 
  1x Remove Influence lv83 - 100c
  2x Remove Speed lv83 - 2ex
```


# 3rd Party stuff
  - http://capture2text.sourceforge.net/ for OCR
  - https://github.com/cocobelgica/AutoHotkey-JSON jxon function embeded in the main file

# Install
  - get the above mentioned OCR tool (tested on version 4.6.2)
  - get the .ahk file
  - put them in the same Folder  
  <img src="examples/folder.png">  

# Use
  - open horticrafting station
  - open harvestVendor Gui CTRL + SHIFT+ G
  - or start capture instantly CTRL + G
  - click Add crafts
  - select the area with text (the left side icons mess up OCR)
    - you can include Levels if you wish
  - stuff gets loaded into the GUI fields, add prices, sort out OCR mess if any, click Create Posting
  - now you have a message ready in clipboard
  
 
# FAQ
 **Q. A craft i have in horticrafting station is not showing up in the result**  
 A. I arbitrarily decided its not worth to list that one, if you want it listed, contact me or open an issue. [List of ignored crafts](https://github.com/esge/PoE-HarvestVendor/wiki/Crafts-that-are-being-ignored)


<form action="https://www.paypal.com/donate" method="post" target="_top">
<input type="hidden" name="business" value="KWMY8R82SLWGC" />
<input type="hidden" name="item_name" value="PoE-HarvestVendor" />
<input type="hidden" name="currency_code" value="EUR" />
<input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif" border="0" name="submit" title="PayPal - The safer, easier way to pay online!" alt="Donate with PayPal button" />
<img alt="" border="0" src="https://www.paypal.com/en_SK/i/scr/pixel.gif" width="1" height="1" />
</form>
