import sys.FileSystem;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.io.Path;
import objects.StrumNote;
import psychlua.HScript;
import states.editors.ChartingState;
import backend.NoteTypesConfig;
import backend.Mods;
import psychlua.LuaUtils;

// Important data structs / constants.

typedef StrumData = {
	var strumline:Array<StrumNote>;
	@:optional var char:Character;
}

final defaultScale:Float = 0.7;
final swagWidth:Float = 160;
var curScale:Float =  defaultScale;

var strumlineOrder:Array<String> = [];
var strumlineData:StringMap<StrumData> = new StringMap();

var gameScripts:Array<HScript> = [];

function getScriptName(name:String):String
{
	var path:Path = new Path(name);
	path.dir = null;
	path.ext = null;
	return path.toString();
}

// STRUMLINE FUNCTIONS ----------------------------------------------------------------------------------

// Callback functions

// Called whenever a strum note is added.
// Can be used for cool intro effects, when possible.
function onStrumAdded(strum:StrumNote)
{
	strum.scale.set(curScale, curScale);
	strum.updateHitbox();

	var returnValue = callEvent("onStrumAdded", [strum]);

	if (returnValue != Function_Stop && !PlayState.isStoryMode && !game.skipArrowStartTween)
	{
		strum.alpha = 0;
		FlxTween.tween(strum, {alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * strum.ID)});
	}
}

// Called whenever a strum note is removed.
// Can be used for cool outro effects, when possible.
function onStrumRemoved(strum:StrumNote)
{
	game.strumLineNotes.remove(strum, true);
	callEvent("onStrumRemoved", [strum]);
}

// Data functions (pretty self-explanatory I think)

function createStrumData(name:String, strumline:Array<StrumNote>, ?char:Character):Void
	strumlineData.set(name, {strumline: strumline, char: char});

function strumlineExists(name:String):Bool
	return strumlineData.exists(name);

function getStrumline(name:String):Null<Array<StrumNote>>
	return strumlineData.get(name)?.strumline ?? [];

function getCharacter(name:String):Null<Character>
	return strumlineData.get(name)?.char;

// Finds the middle between the first and the last note on the X coordinates.
function getStrumlineMidpoint(name:String):Float {
	var strumline:Array<StrumNote> = getStrumline(name);

	var first:StrumNote = strumline[0];
	var last:StrumNote = strumline[strumline.length - 1];

	return (first.x + (last.x + last.width)) * 0.5;
}

// Strum Manipulation functions (functions that control the strumline)

function setNoteScale(note:Note, size:Float)
{
	if (note.isSustainNote)
		// Adjust the X offset of sustain notes.
		note.offsetX *= (size / note.scale.x);
	else
		note.scale.y = size;

	note.scale.x = size;
	note.updateHitbox();
}

function updateNoteGroupScale(noteGroup:Array<Note>, targetStrums:Array<StrumNote>, scale:Float, ?forceScale:Bool)
{
	for (note in noteGroup)
	{
		if (forceScale)
		{
			setNoteScale(note, scale);
			continue;
		}

		var strumGroup:Array<StrumNote> = note.mustPress ? game.playerStrums : game.opponentStrums;
		var myStrumNote:StrumNote = strumGroup.members[note.noteData];

		if (myStrumNote != null && targetStrums.indexOf(myStrumNote) != -1)
			setNoteScale(note, myStrumNote.scale.x);
	}
}

// Local (updated only for one strumline) &
// Global (updated for all current and future strumlines)
function updateNoteScale(size:Float, ?strumline:String)
{
	var isGlobal:Bool = (strumline == null || StringTools.trim(strumline).length == 0);
	var targetStrums:Array<StrumNote> = (isGlobal) ? game.strumLineNotes.members : getStrumline(strumline);
	var newScale:Float = defaultScale * size;

	if (isGlobal) curScale = newScale;
	
	for (strum in targetStrums)
	{
		strum.scale.set(newScale, newScale);
		strum.updateHitbox();
	}

	updateNoteGroupScale(game.unspawnNotes, targetStrums, newScale, isGlobal);
	updateNoteGroupScale(game.notes.members, targetStrums, newScale, isGlobal);
}

// Positions a note lane and gives it an offset based on it's position in a strumline.
function positionStrumNote(spr:StrumNote, pos:Float):Float
	return pos - spr.width / 2 + (swagWidth * spr.scale.x * (spr.noteData - 1.5));

// Positions the entire strumline based on X and Y coordinates.
function positionStrumline(name:String, ?X:Float, ?Y:Float):Void {
	for (strum in getStrumline(name)) {
		strum.x = (X == null || Math.isNaN(X)) ? strum.x : positionStrumNote(strum, X);
		strum.y = (Y == null || Math.isNaN(Y)) ? strum.y : Y;
	}
}

// Moves the strumline under the influence of a tween.
function moveStrumline(strumLine:String, ?X:Float, ?Y:Float, ?time:Float, ?ease:FlxEase, ?onComplete:Void->Void):Void {
	time = time ?? 0;
	ease = ease ?? FlxEase.linear;
	var cum:Bool = false;
	
	if (Math.max(0, time) == 0) {
		positionStrumline(strumLine, X, Y);
		return;
	}

	for (strum in getStrumline(strumLine)) {
		var xPoint:Float = (X == null || Math.isNaN(X)) ? strum.x : positionStrumNote(strum, X);
		var yPoint:Float = (Y == null || Math.isNaN(Y)) ? strum.y : Y;

		FlxTween.cancelTweensOf(strum);
		FlxTween.tween(strum, {x: xPoint, y: yPoint}, time, {ease: ease, onComplete: (_) ->
			{
				if (!cum && onComplete != null)
				{
					onComplete();
					cum = true;
				}
			}
		});
	}
}

// Makes the strumline visible on a screen.
function addStrumline(name:String, ?isPlayer:Bool):Void {
	if (!strumlineExists(name) || strumlineOrder.contains(name))
		return;

	for (strum in getStrumline(name))
	{
		game.strumLineNotes.add(strum);
		onStrumAdded(strum);
	}

	strumlineOrder.push(name);
};

// Works like inserting an FlxBasic in an FlxState.
function insertStrumline(idx:Int, name:String, ?isPlayer:Bool):Void {
	if (!strumlineExists(name) || strumlineOrder.contains(name))
		return;

	var strumIDX:Int = game.strumLineNotes.length;

	if (idx < strumlineOrder.length)
		strumIDX = game.strumLineNotes.members.indexOf(getStrumline(strumlineOrder[idx])[0]);

	for (strum in getStrumline(name))
	{
		game.strumLineNotes.insert(strumIDX, strum);
		onStrumAdded(strum);
	}

	strumlineOrder.insert(idx, name);
};

// Add the strumline behind another one.
function addStrumlineBehind(strumline:String, name:String, ?isPlayer:Bool):Void {
	insertStrumline(strumlineOrder.indexOf(strumline), name, isPlayer);
};

// EVENT HANDLING --------------------------------------------------------------------------

final DEFAULT_RETURN = Function_Continue;

// Functions that manages firing events, and receiving callbacks.
// Works similarly to Psych Engine.
function callEvent(eventName:String, ?args:Array<Dynamic>)
{
	var returnValue = DEFAULT_RETURN;

	for (script in gameScripts)
	{
		if (script == null || !script.exists(eventName))
			continue;

		var scriptReturn = script.call(eventName, args).returnValue ?? DEFAULT_RETURN;

		if (scriptReturn == Function_Stop || scriptReturn == Function_StopHScript || script == Function_StopAll)
		{
			returnValue = Function_Stop;
			break;
		}
	}

	return returnValue;
}

final ANIMATION_EVENT_PREFIX:String = "strumline.";
var animationMap:StringMap<HScript> = new StringMap();

// Checks whether the animation script is eligible for use.
function validateAnimScript(script:HScript):Bool {
	if (script.exists("onAnim_Start"))
		return true;

	return false;
}

// Helper function to extract data from animation event values.
function getEventAnimData(value:String):Array<String>
{
	// the full prompt of value1 should be "add strumline" or "remove strumline". this splits it into "add/remove" and "strumline"
	var cmd = StringTools.trim(value).split(" ");
	return [StringTools.trim(cmd.shift()), StringTools.trim(cmd.join(" "))];
}

function onEventPushed(n:String) {
	if (!animationMap.exists(n) && StringTools.startsWith(n, ANIMATION_EVENT_PREFIX))
	{
		// Initializing a new Animation Script

		var animation:String = StringTools.trim(n.substr(ANIMATION_EVENT_PREFIX.length));
		var scriptPath:String = Paths.mods(Mods.currentModDirectory + "/scripts/animation/" + animation + ".hx");

		if (FileSystem.exists(scriptPath))
		{
			var daScript = new HScript(null, scriptPath);

			if (validateAnimScript(daScript))
				animationMap.set(n, initAnimScript(daScript));
			else
				daScript.destroy();
		}
	}
}

function onEvent(n:String, v1:String, v2:String) {
	if (animationMap.exists(n)) {
		// Parsing event data and passing it onto the found animation script.

		var script = animationMap.get(n);

		var v1Data = getEventAnimData(v1);
		var properties = v2.split(";");

		// If getEventAnimData fails to extract anything it activates this safeguard.
		// Also works as a default
		var animState:String = "onAnim_Start";
		var strumlineName:String = v1;

		if (v1Data.length > 1 && v1Data[0] != "" && v1Data[1] != "")
		{
			animState = switch(v1Data[0]) {
				case "add": "onAnim_Start";
				case "remove": "onAnim_End";
				default: animState;
			};

			strumlineName = v1Data[1];
		}

		for (i in 0...properties.length)
			properties[i] = StringTools.trim(properties[i]);

		var timeData:String = properties.shift() ?? "2";
		var tween:FlxEase = LuaUtils.getTweenEaseByString(properties.shift());
		var parseTime:Float = Std.parseFloat(timeData);

		if (Math.isNaN(parseTime))
			parseTime = 2;

		script.call(animState, [strumlineName, parseTime, tween].concat(properties));
	}
	// else
	// 	debugPrint("Unable to find the matching animation script for " + n);
}

// SCRIPT HANDLING -------------------------------------------------------------------------

function applyDefaultScript(script:HScript):HScript
{
	// Importing functions from the API script.
	script.set("getCharacter", getCharacter);
	script.set("addStrumline", addStrumline);
	script.set("getStrumlineMidpoint", getStrumlineMidpoint);
	script.set("insertStrumline", insertStrumline);
	script.set("addStrumlineBehind", addStrumlineBehind);
	script.set("positionStrumline", positionStrumline);
	script.set("moveStrumline", moveStrumline);

	// The default Y position the strumline spawns at.
	script.set("DEFAULT_STRUM_Y", ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50);

	// Updates the order of strumlines. Usually used for animation.
	script.set("getStrumlineOrder", () -> return strumlineOrder);
	script.set("setStrumlineOrder", (order:Array<String>) -> strumlineOrder = order);

	script.set("setStrumlineVisible", (name:String, value:Bool) -> {
		for (strum in getStrumline(name))
			strum.visible = value;
	});

	// Update note scale on a specific strumline.
	script.set("scaleStrumlineNotes", function (name:String, size:Float):Void {
		updateNoteScale(size, name);
	});
	
	// Update note scale on all strumlines.
	// This also updates the default scale of all future strum notes.
	script.set("scaleNotesGlobal", function(size:Float):Void {
		updateNoteScale(size);
	});

	// Has the strumline been added yet?
	script.set("isStrumlineAlive", function(name:String):Void {
		return strumlineOrder.contains(name);
	});

	// Removes strumline from the world.
	script.set("removeStrumline", function(name:String):Void {
		for (strum in getStrumline(name))
		{
			var tweenData = script.call("removeStrum_getTweenData", [strum]).returnValue;
			
			if (tweenData != null)
			{
				var properties = tweenData.properties ?? {};
				var time = tweenData.time ?? 0;
				var settings = tweenData.settings ?? {};

				var userOnComplete = settings.onComplete;
				settings.onComplete = (_) -> {
					if (userOnComplete != null) userOnComplete(_);
					onStrumRemoved(strum);
				}

				FlxTween.tween(strum, properties, time, settings);
			}
			else
				onStrumRemoved(strum);
		}

		strumlineOrder.remove(name);
	});

	// lol
	script.set("hideStrumline", function(name:String) {
		positionStrumline(name, -1000);
	});

	return script;
}

function initAnimScript(script:HScript):HScript
{
	applyDefaultScript(script);

	// WIP...
	return script;
}

function initGameScript(script:HScript):HScript
{
	// Game script has a lot more low-level access than a default script.

	applyDefaultScript(script);

	script.set("strumAPI", this);
	script.set("strumlineData", strumlineData);

	script.set("strumlineExists", strumlineExists);
	script.set("getStrumline", getStrumline);

	script.set("setCharacter", (name:String, char:Character) -> strumlineData.get(name).char = char);

	script.set("createStrumline", function(name:String, ?char:Character, ?isPlayer:Bool):Array<StrumNote> {
		var strumNotes:Array<StrumNote> = [];

		for (i in 0...4)
		{
			var strum:StrumNote = new StrumNote(0, 0, i, 0);
			strum.ID = i;
			strum.downScroll = ClientPrefs.data.downScroll;
			strum.playAnim("static");
			strumNotes.push(strum);

			((isPlayer ?? false) ? game.playerStrums : game.opponentStrums).add(strum);
		}

		createStrumData(name, strumNotes, char);

		// AUTOMATIC NOTE TYPE DETECTION!! HELL YEAH!!! (FUCK SHADOWMARIO!!!)
		NoteTypesConfig.loadNoteTypeData(name); // ChartingState.noteTypeList.push(name);

		return strumNotes;
	});

	gameScripts.push(script);

	return script; // The most USELESS line of code ever but anyways :P
}

function onCreatePost()
{
	// The reason we copy the array is because we don't wanna reference
	// these strumlines. If we did reference them then it would count
	// the strums that were added AFTER these ones.

	createStrumData("dad", game.opponentStrums.members.copy());
	createStrumData("bf", game.playerStrums.members.copy());

	strumlineOrder = ["dad", "bf"];

	for (script in game.hscriptArray)
	{
		var name:String = getScriptName(script.origin);
		if (StringTools.startsWith(name, "strumScript"))
			initGameScript(script);
	}

	if (gameScripts.length < 1) // Destroy the script if there's no strumline gameScripts available (performance reasons)
	{
		game.hscriptArray.remove(this);
		this.destroy();
		return;
	}

	callEvent("onInit");

	for (note in game.unspawnNotes)
	{
		if (!strumlineExists(note.noteType))
			continue;

		var myStrum:StrumNote = getStrumline(note.noteType)[note.noteData];
		var mustPress:Bool = game.playerStrums.members.indexOf(myStrum) > -1;
		var strumLine = mustPress ? game.playerStrums : game.opponentStrums;

		note.mustPress = mustPress;
		note.noteData = strumLine.members.indexOf(myStrum);
		note.noAnimation = true;
	}

	callEvent("onInitPost");
}

function onDestroy()
{
	trace("DESTROYING ANIMATION SCRIPTS");

	for (animScript in animationMap)
	{
		if (animScript == null)
			continue;

		// Causes the game to pause for longer
		// We won't need a destroy onDestroy callback for animation scripts anyways :P
		// if (animScript.exists("onDestroy"))
			// animScript.call("onDestroy");

		trace("DESTROYED [" + getScriptName(animScript.origin) + ".hx]");
		animScript.destroy();
	}

	animationMap.clear();
}
