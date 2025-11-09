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