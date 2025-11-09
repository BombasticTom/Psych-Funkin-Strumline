local botplaySetting = getPropertyFromClass("backend.ClientPrefs", "data.gameplaySettings")["botplay"]

function onEvent(name, v1, v2)
	if name == 'HudEvent' then
		local bool = v1:lower() == 'true';
		setProperty('cpuControlled', bool or botplaySetting);
		doTweenAlpha('huddy', 'camHUD', (bool and 0 or 1), 0.4, 'sineInOut');
	end
end