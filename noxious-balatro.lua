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
			"When {C:attention}Small Blind{} or {C:attention}Big Blind{}",
			"is defeated, gain any remaining",
            "hands when selecting next blind",
			"{C:inactive}(Will give {C:blue}+#1#{C:inactive} Hands next blind)"
		}
	},
	config = { extra = { hands = 0, hands_last = 0 } },
	rarity = 2,
	atlas = 'noxious-balatro',
	pos = { x = 0, y = 0 },
	cost = 7,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.hands, card.ability.extra.hands_last } }
	end,
	calculate = function(self, card, context)
        if context.setting_blind and card.ability.extra.hands > 0 then
			ease_hands_played(card.ability.extra.hands)
			card.ability.extra.hands_last = card.ability.extra.hands
			card.ability.extra.hands = 0
            return {
				message = '+' .. tostring(card.ability.extra.hands_last) .. ' Hands',
				colour = G.C.FILTER,
				card = card
			}
        end

        if context.end_of_round and context.cardarea == G.jokers and not G.GAME.blind.boss then
            card.ability.extra.hands = G.GAME.current_round.hands_left
			ease_hands_played(-G.GAME.current_round.hands_left)
            return {
                message = 'Hold It!',
				colour = G.C.BLUE,
				card = card
            }
        end

		if context.end_of_round and context.cardarea == G.jokers and G.GAME.blind.boss then
			card.ability.extra.hands_last = 0
            return {
                message = 'Adjourned!',
				colour = G.C.FILTER,
				card = card
            }
        end
	end
}
