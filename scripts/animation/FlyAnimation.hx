final y_Start:Float = ClientPrefs.data.downScroll ? (FlxG.height) : -200;

function updateStrumPosition(toY:Float, time:Float, tween:FlxEase)
{
	// Loop logic that updates position of all active strumlines.
	var strumlineOrder = getStrumlineOrder();

	var i:Int = 0;
	for (strumline in strumlineOrder)
	{
		var X:Float = FlxG.width * ((i + .5) / strumlineOrder.length);
		moveStrumline(strumline, X, toY, time, tween);
		i += 1;
	}
}

// Must be in strings because yeah. Shadow Mario.
function onAnim_Start(name:String, time:Float, tween:FlxEase, ?eID:String)
{
	if (isStrumlineAlive(name))
		return;

	var strumlineOrder = getStrumlineOrder();

	// Parsing custom event data to make it usable.
	var id:Int = Std.parseInt(eID);

	if (id == null || Math.isNaN(id))
		id = Math.floor(strumlineOrder.length / 2);

	id = Math.max(Math.min(id, strumlineOrder.length + 1), 1);
	insertStrumline(id, name);
	positionStrumline(name,
		FlxG.width * ((id + .5) / strumlineOrder.length),
		y_Start
	);
	
	updateStrumPosition(DEFAULT_STRUM_Y, time, tween);
}

function onAnim_End(name:String, time:Float, tween:FlxEase)
{
	if (!isStrumlineAlive(name))
		return;

	var strumlineOrder = getStrumlineOrder();
	strumlineOrder.remove(name);

	moveStrumline(name, null, y_Start, time, tween, () -> hideStrumline(name));
	updateStrumPosition(DEFAULT_STRUM_Y, time, tween);
}