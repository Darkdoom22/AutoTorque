COMMANDS:

	//at set - sets your target as the chest to solve, or adds it to the queue if there is already a chest currently set
	//at solve - starts solving detected chests in the order they spawned (move between chests as the addon opens them and then check the chest contents after the addon has finished guessing for all chests, or check on a mule or have a mule solve - checking contents in the middle of the solve loop is likely to packet lock you)
	//at stuck - attempts to reset you if you get packet locked (alternatively, aggroing a mob and getting hit will have the same effect)
	//at reset - clears current chest target and queue
	//at debug - toggle debug logging on or off, recommended to leave on so that you have a more granular idea of what step the addon is currently performing 

GENERAL STUFFS:

	To use, wait for a chest to spawn and type //at solve while within 7 yalms of the chest, the addon will attempt to solve every chest it has detected a spawn for.

	You can generally allow the addon to handle adding new chest spawns on its own, manually setting should only be required if you have a chest spawn and subsequently reload the addon without solving it

	Due to the amount of menuing required to both obtain hints and input guesses into chests (each hint or guess requires re-entering the menu), the possibility of being packet locked exists - I recommend you do nothing on the character that is using the addon while it is solving a chest.  There are mitigations in place, but user interaction at the same time as the addon attempts a menu can still cause issues.

KNOWN ISSUES:

	If a box despawns while you are greater than 50 yalms away from it the despawn packet is not received and it is not removed.

TODO:

	The current Range handling algorithm does not correctly handle all cases, though enough information is usually given by other hints to render this moot - this will be fixed soon.
	
	Thief's tools allow for an extra hint and support for using them will be added in the future.
	
	General cleanup and organization of the code.