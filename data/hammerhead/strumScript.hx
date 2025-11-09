var luigi:Character;

function onInit()
{
	// Basic character setup shenanigans.

	game.dadGroup.y += 40;
	for (dad in game.dadGroup)
	{
		dad.cameraPosition[1] -= 40;
	}

	luigi = new Character(game.dadGroup.x - 175, game.dadGroup.y, 'pico');
	luigi.scrollFactor.set(0.97, 0.97);
	luigi.y += luigi.positionArray[1] - 50;
	game.addBehindDad(luigi);

	// Functions for creating the strumline!

	// Creates a new strumline, and you can assign a character to it
	// You can also use assignCharacter("Third Player Note", game.gf) to do the same thing!
	createStrumline("Third Player Note", luigi);

	addStrumline("Third Player Note"); // Adds it to the game!

	// createStrumline("Fourth Player Note"); // NOWAY....
	// addStrumline("Fourth Player Note"); // 😱

	scaleNotes(0.625); // Scales all the notes down (so they can all be visible and not go off-screen)

	// Basic position for your strumline

	positionStrumline("Third Player Note", FlxG.width * .125);
	positionStrumline("dad", FlxG.width*0.5);
	positionStrumline("bf", FlxG.width*0.875);

	// Puts all of the strumlines to their position before the staring animation begins

	// triggerAnimation("left", "prepare");
}

function onStrumAdded(strum:StrumNote)
{
	strum.y += 720;
	FlxTween.tween(strum, {y: DEFAULT_STRUM_Y}, 2, {ease: FlxEase.backOut, startDelay: 0.1 * strum.ID});
	return Function_Stop;
}

function tween_getRemoveData(strum:StrumNote)
{
	return {
		properties: {y: strum.y + 720},
		time: 2,
		settings: {ease: FlxEase.elasticIn, startDelay: 0.1 * strum.ID}
	};
}

function onSongStart()
{
	// setStrumLineOrder(["dad", "bf"]);
	// flyStrumlineUp("Third Player Note", 3, 5, FlxEase.sineInOut);
	removeStrumline("Third Player Note");
}

// More character code

function characterBopper(char:Character, beat:Int):Void
{
	if (char != null && beat % char.danceEveryNumBeats == 0 && !StringTools.startsWith(char.getAnimationName(), 'sing') && !char.stunned)
		char.dance();
}

function onCountdownTick(tick:Countdown, count:Int)
	characterBopper(luigi, count);

function onBeatHit()
	characterBopper(luigi, curBeat);

function flyStrumlineUp(name:String, id:Int, ?time:Float, ?tween:FlxEase)
{
	if (Math.isNaN(time))
		time = 2;

	tween = tween ?? FlxEase.linear;

	var strumlineOrder = getStrumLineOrder();
	id = Math.max(Math.min(id, strumlineOrder.length + 1), 1) - 1;

	strumlineOrder.insert(id, name);
	var len:Int = strumlineOrder.length;
	
	var i:Int = 0;

	for (strumline in strumlineOrder)
	{
		var X:Float = FlxG.width * ((i + .5) / len);
		var Y:Float = ClientPrefs.data.downScroll ? (FlxG.height) : -200;

		if (i == id)
			positionStrumline(strumline, X, Y);

		moveStrumline(strumline, X, DEFAULT_STRUM_Y, time, tween);

		i += 1;
	}
}

function oldFormula()
{
	setStrumLineOrder(["dad", "bf", "Third Player Note"]);

	var i:Int = 0;
	var len:Int = strumAPI.get("strumlineOrder").length;

	for (strumline in strumAPI.get("strumlineOrder"))
	{
		moveStrumline(strumline, FlxG.width * ((i + .5) / len), null, 2, FlxEase.bounceInOut);
		i += 1;
	}
}

function oldFormula2()
{
	setStrumLineOrder(["dad", "bf"]);
	var whatIwanttoappear:String = "Third Player Note";

	strumAPI.get("strumlineOrder").insert(1, whatIwanttoappear);
	positionStrumline(whatIwanttoappear, FlxG.width * .5, FlxG.height + 100);

	var i:Int = 0;
	var len:Int = strumAPI.get("strumlineOrder").length;

	for (strumline in strumAPI.get("strumlineOrder"))
	{
		moveStrumline(strumline, FlxG.width * ((i + .5) / len), ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50, 2, FlxEase.bounceInOut);
		i += 1;
	}
}