The digipad allows you to enter a number 0-9 digits, which will be sent down
a digiline.  You can select channels 1-3 with buttons in the formspec. channels
are prefixed with "keypad" so Channel 1 transmits on "keypad1" etc.

The hardened digipad shares the same functions, but has different physical
properties.  It is a full 1m wide, so it can cover a wire channel in a wall
completely.  It also has the same digging properties as a steel block, so some
random noob with a stone pickaxe can't steal it.


If the digipad_terminal (Enable Terminal) setting is true then there is a keyboard and a terminal:

The keyboard allows arbitrary strings to be entered.  It sends only on channel "keyb1" right now.

The terminal allows entering strings, and receiving responses.  It's channel prefix is "tty" and the suffix can be set with /channel <suffix>.
Default suffix is "1", making  the channel "tty1".  "/help" will display a help text.


TODO:
— better sound and more sounds
