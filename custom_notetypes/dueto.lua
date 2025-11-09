function goodNoteHit(id, dir, noteType, sus)
	if noteType == 'dueto' then
		playAnim('gf', getProperty('singAnimations')[math.abs(dir) + 1], true);
		setProperty('gf.holdTimer', 0);
	end
end