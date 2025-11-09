function flyStrumlineUp(name:String, id:Int, ?time:Float, ?tween:FlxEase)
{
	var strumlineOrder = getStrumLineOrder();

	time = time ?? 2;
	id = id ?? Math.floor(strumlineOrder.length / 2);
	tween = tween ?? FlxEase.linear;

	id = Math.max(Math.min(id, strumlineOrder.length + 1), 1) - 1;
	strumlineOrder.insert(id, name);
	var i:Int = 0;

	for (strumline in strumlineOrder)
	{
		var X:Float = FlxG.width * ((i + .5) / strumlineOrder.length);
		var Y:Float = ClientPrefs.data.downScroll ? (FlxG.height) : -200;

		if (i == id)
			positionStrumline(strumline, X, Y);

		moveStrumline(strumline, X, DEFAULT_STRUM_Y, time, tween);

		i += 1;
	}
}