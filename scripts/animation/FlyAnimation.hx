import psychlua.LuaUtils;

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
function onAnim_Start(name:String, ?eID:String, ?eTime:String, ?eTween:String)
{
	if (isStrumlineAlive(name))
		return;

	var strumlineOrder = getStrumlineOrder();

	// Parsing event data to actual data.
	var id:Int = Std.parseInt(eID);
	var time:Float = Std.parseFloat(eTime);
	var tween:FlxEase = LuaUtils.getTweenEaseByString(eTween);

	if (time == null || Math.isNaN(time))
		time = 2;

	if (id == null || Math.isNaN(id))
		id = Math.floor(strumlineOrder.length / 2);

	id = Math.max(Math.min(id, strumlineOrder.length + 1), 1) - 1;
	insertStrumline(id, name);
	positionStrumline(name,
		FlxG.width * ((id + .5) / strumlineOrder.length),
		ClientPrefs.data.downScroll ? (FlxG.height) : -200
	);
	
	updateStrumPosition(DEFAULT_STRUM_Y, time, tween);
}