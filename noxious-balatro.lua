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

-- Jokers

---- Common Jokers

--[[ Flash Paper
	Sell this card to Draw 5
	Cards from your deck
]]
SMODS.Joker {
	key = 'flashpaper',
	loc_txt = {
		name = 'Flash Paper',
		text = {
			"Sell this card to {C:attention}Draw #1#{}", 
			"Cards from your deck"
		}
	},
	config = { extra = { cards = 5 } },
	rarity = 1,
	atlas = 'noxious-balatro',
	pos = { x = 0, y = 0 },
	cost = 3,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.cards } }
	end,
	calculate = function(self, card, context)
		if context.selling_self and G.hand and #G.hand.cards >= 1 then
			SMODS.draw_cards(card.ability.extra.cards)
			return {
				message = 'Burned!',
				colour = G.C.FILTER,
				cardarea = G.jokers,
				selling_card = true,
				card = card
			}
		end
	end
}

---- Uncommon Jokers

--[[ Orange Juicer
	When discarding, draw an additional card.
]]
SMODS.Joker {
	key = 'ojuicer',
	loc_txt = {
		name = 'Orange Juicer',
		text = {
			"When discarding, always {C:attention}Draw{}",
			"1 more card than was discarded"
		}
	},
	config = { extra = { cards = 0 }, active = nil },
	rarity = 2,
	atlas = 'noxious-balatro',
	pos = { x = 0, y = 0 },
	cost = 5,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.cards, card.ability.trigger } }
	end,
	calculate = function(self, card, context)
		if context.pre_discard then
			card.ability.active = true
			card.ability.extra.cards = math.min(#G.hand.highlighted - (G.hand.config.card_limit - (#G.hand.cards - #G.hand.highlighted)), #G.hand.highlighted) + 1
			end

		if context.drawing_cards and card.ability.active then
			card.ability.active = nil
			return {
				cards_to_draw = context.amount + card.ability.extra.cards,
				message = 'No Pulp!',
				colour = G.C.FILTER,
				card = card
			}
		end
	end
}

---- Rare Jokers

--[[ Turnabout
	When Small Blind or Big Blind is defeated,
	gain any remaining hands when selecting next blind
]]
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
	rarity = 3,
	atlas = 'noxious-balatro',
	pos = { x = 0, y = 0 },
	cost = 10,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.hands, card.ability.extra.hands_last } }
	end,
	calculate = function(self, card, context)
		if context.setting_blind and card.ability.extra.hands > 0 and context.blueprint then
			ease_hands_played(card.ability.extra.hands)
			local hand_msg = card.ability.extra.hands
            return {
				message = '+' .. tostring(hand_msg) .. ' Hands',
				colour = G.C.FILTER,
				card = card
			}
        end

        if context.setting_blind and card.ability.extra.hands > 0 and not context.blueprint then
			ease_hands_played(card.ability.extra.hands)
			card.ability.extra.hands_last = card.ability.extra.hands
			card.ability.extra.hands = 0
            return {
				message = '+' .. tostring(card.ability.extra.hands_last) .. ' Hands',
				colour = G.C.FILTER,
				card = card
			}
        end

        if context.end_of_round and context.cardarea == G.jokers and not G.GAME.blind.boss and not context.blueprint then
            card.ability.extra.hands = G.GAME.current_round.hands_left
			ease_hands_played(-G.GAME.current_round.hands_left)
            return {
                message = 'Hold It!',
				colour = G.C.BLUE,
				card = card
            }
        end

		if context.end_of_round and context.cardarea == G.jokers and G.GAME.blind.boss and not context.blueprint then
			card.ability.extra.hands_last = 0
            return {
                message = 'Adjourned!',
				colour = G.C.FILTER,
				card = card
            }
        end
	end
}
