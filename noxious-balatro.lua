SMODS.Atlas {
	-- Key for code to find it with
	key = "noxious-balatro",
	-- The name of the file, for the code to pull the atlas from
	path = "noxious-balatro.png",
	-- Width of each sprite in 1x size
	px = 71,
	-- Height of each sprite in 1x size
	py = 95
}

SMODS.Joker {
	key = 'turnabout',
	loc_txt = {
		name = 'Turnabout',
		text = {
			"This Joker Give {C:blue}+1{} Hand for each",
			"remaining hand at end of the last round",
            "Resets when {C:attention}Boss Blind{} is defeated",
			"{C:inactive}(Currently {C:chips}+#1#{C:inactive} Hands)"
		}
	},
	config = { extra = { hands = 0 } },
	rarity = 2,
	atlas = 'noxious-balatro',
	pos = { x = 0, y = 0 },
	cost = 7,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.hands } }
	end,
	calculate = function(self, card, context)
        if context.setting_blind then
            return {
                ease_hands_played(card.ability.extra.hands)
            }
        end

        if context.end_of_round and context.cardarea == G.jokers and not G.GAME.blind.boss then
            card.ability.extra.hands = G.GAME.current_round.hands_left
            return {
                message = 'Hold It!',
				colour = G.C.BLUE,
				card = card
            }
        end

        if context.end_of_round and context.cardarea == G.jokers and G.GAME.blind.boss then
            card.ability.extra.hands = 0
            return {
                message = 'Adjourned!',
				colour = G.C.FILTER,
				card = card
            }
        end
	end
}
