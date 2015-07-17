-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
--Splash Screen
--------------------------------------------------
display.setStatusBar( display.HiddenStatusBar )
local physics = require("physics")
physics.start() --crank up the phys engine

local soundID = audio.loadSound( "splash.wav" ) 


-- Background init stuff
--local bgWidth = display.viewableContentWidth
--local bgHeight = display.viewableContentHeight
display.setDefault( "background", 0, 0, 0 )
display.setDefault( "fillColor", 0, 0, 0 )

local splash = display.newImage("splash.png")
splash.x = display.contentCenterX
splash.y = display.contentCenterY
timer.performWithDelay(1000,audio.play( soundID ), 1)

--This is just the function main()
--it is invoked at the end

function main()
	--Heres a freeware sound file from one of my old projects
	--Sounds like a card being flipped over
	soundID = audio.loadSound( "draw.mp3" )
	splash:removeSelf( )
	--The back starts at 0 width so that when we flip the front, 
	--	the back will grow out correctly
	local backgroundBack = display.newImageRect( "replicatorsbackgroundBack.png", 
													0, 
													display.viewableContentHeight )
	local backgroundFront = display.newImageRect( "replicatorsbackgroundFront.png", 
													display.viewableContentWidth, 
													display.viewableContentHeight)
	backgroundBack.x = display.contentCenterX --set origin coordinates
	backgroundFront.x = display.contentCenterX
	backgroundBack.y = display.contentCenterY 
	backgroundFront.y = display.contentCenterY

	local background = backgroundFront -- Container for the background files
	local warshipGroup = display.newGroup() --This was added at the end to hide the warships

	local backgroundFlip = function( event )
		local temp = background --kinda like a bubble sort
		--toggle
		background=(backgroundFront==background and backgroundBack) or backgroundFront
		transition.to( temp, {width=0,time=500,height=display.viewableContentHeight})
		--Flip front card in, and as soon as it is done flip back card out
		timer.performWithDelay( 500, function() 
			transition.to( background, {width = display.contentWidth,time = 500} )
			end )

		--This hides the warships for readability of the back of the card
		if background == backgroundBack then
			warshipGroup.isVisible = false
		elseif background == backgroundFront then
			warshipGroup.isVisible = true
		end

		--Free little flip sound. Probably go with something more Sci-Fi/Spacey later
		audio.play( soundID )	
	end
	backgroundFront:addEventListener( "tap", backgroundFlip )  --add the listeners
	backgroundBack:addEventListener( "tap", backgroundFlip )

	--So That's the end of the background part, now we just need to be able to add 
	--	and remove warships
	--So let's start with the deck of 10 warships
	local warships = { }
	local availibleWarships = 10 --num in the deck, so we dont draw too many!

	--We will need some methods to continue. First a way to shuffle the deck,
	--then methods for adding and removing warships from the screen

	--this is where googling saves you time.
	--Theres tons of helpful code snippets like this on the LUA website
	--or even on the Corona labs blog like this one!


	math.randomseed( os.time() )

	local function shuffleTable( t )
	    local rand = math.random 
	    assert( t, "shuffleTable() expected a table, got nil" )
	    local iterations = availibleWarships
	    local j
	    
	    for i = iterations, 2, -1 do
	        j = rand(i)
	        t[i], t[j] = t[j], t[i]
	    end
	end

	--Now we can make methods for adding warships!

	local function addWarship()
		if availibleWarships > 0 then --only do something if there is a warship availible
			shuffleTable( warships ) --shuffle again, when warships are removed they
						--are placed back on top of the deck in the order they were removed. 
			local rand = math.random --this spawns the warship in a random place, for fun!
			transition.to(warships[availibleWarships],
				{x= rand(20, display.contentWidth - 20),
				 y= rand(20,100),
				 time=0})
			warships[availibleWarships].isVisible = true
			physics.addBody( warships[availibleWarships], --Add it to the phys engine
				 { density=1.0, friction=0.3, bounce=0.2, radius=30 } )
			availibleWarships = availibleWarships - 1 -- Decrement availible
		end	
		return true --Stopping the function there. 
	end				--If we don't add this, the program will execute all
					--"tap" functions until it gets a true or runs out of functions!

	local oops = { } --A placeholder for the later 'Undo' funtion


	local function removeWarship( event ) --event.target = the warship touched
		physics.removeBody(event.target)
		event.target.isVisible = false
		availibleWarships= availibleWarships+1
		warships[availibleWarships] = event.target
		oops = event.target --set the removed for undo if needed
		return true
	end

	--All the undo function does, is undoes what the remove did, except for
	-- the iterator
	--This function is still not complete, creating issues
	local function undo( )
		oops.isVisible = true
		physics.addBody( oops,
				 { density=1.0, friction=0.3, bounce=0.2, radius=30 } )
		--availibleWarships = availibleWarships - 1 --creates problems since deck is
													--constantly being shuffled
		return true
	end

	--Okay, now that the methods are over with we can actually init the deck
	--You can do them individually or however you like,
	--but I found it easier to just use a loop
	for i =1, 10 do
		warships[i] = display.newImageRect("warship"..i..".png", 60, 60)
		warships[i].isVisible = false
		warships[i]:addEventListener("tap", removeWarship)
		warshipGroup:insert(warships[i],false)--add them to the group from earlier
											  --so we can hide them when needed
	end

	shuffleTable( warships ) --shuffle the deck! Wasn't that easy?

	--All that's left is the creating the bounds and the buttons!
	local floor = display.newRect(display.contentCenterX, 
									2*display.viewableContentHeight/3, 
									display.viewableContentWidth, 
									0.2)
	local ceiling = display.newRect(display.contentCenterX, 
									0, 
									display.viewableContentWidth, 
									1)
	local leftWall = display.newRect(0, 
									display.contentCenterY, 
									1, 
									display.viewableContentHeight)
	local rightWall = display.newRect(display.viewableContentWidth, 
									display.contentCenterY, 
									1, 
									display.viewableContentHeight)
	physics.addBody(floor, "static")
	physics.addBody(ceiling, "static")
	physics.addBody(leftWall, "static")
	physics.addBody(rightWall, "static")

	--adds warships
	local addButton = display.newImageRect("warshipadd.png",40,40)
	addButton.x =50
	addButton.y =30

	--undo
	local backButton = display.newImageRect("back.png",40,40)
	backButton.x = display.contentWidth - 15
	backButton.y = display.contentHeight - 40

	local aboutButton = display.newImageRect("about.png", 40, 40)
	aboutButton.x = display.contentWidth - 15
	aboutButton.y = display. contentHeight - 80


	local aboutImage = display.newRect(display.contentWidth*2,display.contentCenterY,500,300)
	local forestnympho = display.newImageRect("forestnympho.png",(display.contentWidth/2) - 20,
												display.contentHeight/4)
	local shaungamer = display.newImageRect("shaungamer.png",(display.contentWidth/2) - 20,
												display.contentHeight/4)
	local morechallenges = display.newImageRect("morechallenges.png",(display.contentWidth/2)-20,
												display.contentHeight/4)
	local officialgame = display.newImageRect("officialgame.png",(display.contentWidth/2)-20,
												display.contentHeight/4)

	shaungamer.x = display.contentWidth*2 - display.contentWidth/4
	shaungamer.y = display.contentHeight/4

	forestnympho.x = display.contentWidth*2 - display.contentWidth/4
	forestnympho.y = 3*(display.contentHeight/4)

	morechallenges.x = display.contentWidth*2 + display.contentWidth/4
	morechallenges.y = display.contentHeight/4

	officialgame.x = display.contentWidth*2 + display.contentWidth/4
	officialgame.y = 3*(display.contentHeight/4)

	local removeAboutButton = display.newImageRect("back.png",40,40)
	removeAboutButton.x = display.contentWidth*2
	removeAboutButton.y = display.contentCenterY

	local function showAbout()
		transition.to(aboutImage,
						{
							x=display.contentCenterX,
							y=display.contentCenterY,
							time = 2000
						})
		transition.to(removeAboutButton,
						{
							x=display.contentCenterX,
							y=display.contentCenterY,
							time = 2000
						})	
		transition.to( shaungamer, 
						{
							x=display.contentWidth/4,
							y=display.contentHeight/4,
							time = 2000
						})
		transition.to( forestnympho, 
						{
							x=display.contentWidth/4,
							y=3*(display.contentHeight/4),
							time = 2000
						})
		transition.to( morechallenges, 
						{
							x=3*(display.contentWidth/4),
							y=display.contentHeight/4,
							time = 2000
						})
		transition.to( officialgame, 
						{
							x=3*(display.contentWidth/4),
							y=3*(display.contentHeight/4),
							time = 2000
						})
		return true --We have all of these returning true to keep
	end				--the touches from getting through

	local function hideAbout()
		transition.to(aboutImage,
						{
							x=display.contentWidth*2,
							y=display.contentCenterY,
							time = 2000
						})
		transition.to(removeAboutButton,
						{
							x=display.contentWidth*2,
							y=display.contentCenterY,
							time = 2000
						})	
		transition.to( shaungamer, 
						{
							x=display.contentWidth*2 - display.contentWidth/4,
							y=display.contentHeight/4,
							time = 2000
						})
		transition.to( forestnympho, 
						{
							x=display.contentWidth*2 - display.contentWidth/4,
							y=3*(display.contentHeight/4),
							time = 2000
						})
		transition.to( morechallenges, 
						{
							x=display.contentWidth*2 + display.contentWidth/4,
							y=display.contentHeight/4,
							time = 2000
						})
		transition.to( officialgame, 
						{
							x=display.contentWidth*2 + display.contentWidth/4,
							y=3*(display.contentHeight/4),
							time = 2000
						})
		return true
	end

	--These are all the event listeners for the about screen
	--Each of the four picture buttons opens a webpage to the
	--credited entities.

	--The cool part about this is Corona handles all of the stuff
	--to switch the app to a webpage and open the right page.
	--Literally all you have to do is system.openURL( thePage )
	aboutButton:addEventListener("tap",showAbout)
	removeAboutButton:addEventListener("tap",hideAbout)

	shaungamer:addEventListener("tap", function()
		system.openURL( "https://boardgamegeek.com/user/ShaunGamer" )
		return true 
	end)

	forestnympho:addEventListener("tap", function()
		system.openURL( "http://forestnympho.wix.com/home" )
		return true 
	end)

	morechallenges:addEventListener("tap", function()
		system.openURL( "https://boardgamegeek.com/geeklist/189611/star-realms-solo-challenges" )
		return true 
	end)

	officialgame:addEventListener("tap", function()
		system.openURL( "http://www.starrealms.com/buy/" )
		return true 
	end)

	aboutImage:addEventListener("tap", function()
		return true --Pre-emptively catch the touches from getting through
	end)

	addButton:addEventListener("tap", addWarship )
	backButton:addEventListener("tap", undo)

end

timer.performWithDelay( 4000, main, 1 ) 
--call main after 4 seconds of splash screen,
--Remember, ALWAYS sign your work! Even if it's free!
