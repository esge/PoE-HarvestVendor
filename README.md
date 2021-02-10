# PoE-HarvestVendor
 - uses AHK to call the http://capture2text.sourceforge.net/ OCR tool on a specific region
 - Trims OCR-ed text to just the basic stuff (Augment a Magic or Rare item with a new Caster modifier -> Augment Caster)
 - puts the result into clipboard (for now, later maybe some gui to add prices and other info to it and then clipboard)
 
# Install
  - get the above mentioned OCR tool (tested on version 4.6.2)
  - get the .ahk file
  - put them in the same Folder  
    Folder:
      - Capture2text
      - PoE-harvestVendor.ahk
      
# Use
  - open horticrafting station
  - use the harvestVendor hotkey (TDB for now ctrl+shift+q)
  - select the area with text (the left side icons mess up OCR)
  - you should have stuff in clipboard now
  
 <img src="examples/example.gif" width="724" height="540">  

| source | result |
| --- | --- |
| ![example2](examples/example2.png) | Change Lightning Resistance into Fire Resistance<br /> Change Cold Resistance into Lightning Resistance<br /> Remove Physical V ~ ‘<br /> Change Fire Resistance into Cold Resistance<br /> Remove Fire add Fire|

- As you can see occasionally there is a stray letter or symbol, thats an issue of the OCR tool, can't really do much with it

# FAQ
 **Q. A craft i have in horticrafting station is not showing up in the result**  
 A. I arbitrarily decided its not worth to list that one, if you want it listed, contact me or open an issue. [List of ignored crafts](https://github.com/esge/PoE-HarvestVendor/wiki/Crafts-that-are-being-ignored)
