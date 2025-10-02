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

SMODS.current_mod.optional_features = {
    retrigger_joker = true,
    post_trigger = true,
    quantum_enhancements = true,
    cardareas = {
        discard = true,
        deck = true
    }
}

-- Xmult detection from Cryptid
local scie = SMODS.calculate_individual_effect
function SMODS.calculate_individual_effect(effect, scored_card, key, amount, from_edition)
	local ret = scie(effect, scored_card, key, amount, from_edition)
	if
		(
			key == "x_mult"
			or key == "xmult"
			or key == "Xmult"
			or key == "x_mult_mod"
			or key == "xmult_mod"
			or key == "Xmult_mod"
		)
		and amount ~= 1
		and mult
	then
		SMODS.calculate_context({nox_xmult = true})
	end
	return ret
end

-- Destroy Detection
local remove_card = Card.remove_from_deck
function Card:remove_from_deck(from_debuff)
	if self.added_to_deck then
		if self.config.center_key == "j_nox_hangman" then
			G.GAME.nox_hangman = G.GAME.nox_hangman + self.ability.extra.bonus_xmult
		end
	end
	local ret = remove_card(self, from_debuff)
	return ret
end

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
	pos = { x = 2, y = 0 },
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

--[[ Salt
	+2 Mult every time any other
	Joker is triggered during scoring
	(Ignores Salt and Pepper)
]]
SMODS.Joker {
	key = 'salt',
	loc_txt = {
		name = 'Salt',
		text = {
			"{C:mult}+2{} Mult every time any other",
			"{C:attention}Joker{} is triggered during scoring",
			"{s:0.8}Ignores Salt and Pepper"
		}
	},
	config = { extra = { mult = 2 }, active = nil },
	rarity = 1,
	atlas = 'noxious-balatro',
	pos = { x = 0, y = 0 },
	cost = 3,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult, card.ability.active } }
	end,
	calculate = function(self, card, context)
		if context.before then
			card.ability.active = true
		end
		if context.after then
			card.ability.active = nil
		end
		if context.post_trigger and context.cardarea == G.jokers and card.ability.active then
			return {
				mult = card.ability.extra.mult
			}
		end
	end
}

--[[ Pepper
	+15 Chips every time any other
	Joker is triggered during scoring
	(Ignores Salt and Pepper)
]]
SMODS.Joker {
	key = 'pepper',
	loc_txt = {
		name = 'Pepper',
		text = {
			"{C:chips}+15{} Chips every time any other",
			"{C:attention}Joker{} is triggered during scoring",
			"{s:0.8}Ignores Salt and Pepper"
		}
	},
	config = { extra = { chips = 15 }, active = nil },
	rarity = 1,
	atlas = 'noxious-balatro',
	pos = { x = 1, y = 0 },
	cost = 3,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips, card.ability.active } }
	end,
	calculate = function(self, card, context)
		if context.before then
			card.ability.active = true
		end
		if context.after then
			card.ability.active = nil
		end
		if context.post_trigger and context.cardarea == G.jokers and card.ability.active then
			return {
				chips = card.ability.extra.chips
			}
		end
	end
}

--[[ Coupon
	Sell this card to gain
	+1 selection in the 
	current booster pack
]]
SMODS.Joker {
	key = 'coupon',
	loc_txt = {
		name = 'Coupon',
		text = {
			"{C:attention}Sell{} this card to gain",
			"{C:attention}+1{} selection in the",
			"current booster pack"
		}
	},
	config = { extra = { selection = 1 } },
	rarity = 1,
	atlas = 'noxious-balatro',
	pos = { x = 2, y = 0 },
	cost = 3,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.selection } }
	end,
	calculate = function(self, card, context)
		if context.selling_self and G.GAME.pack_choices and G.GAME.pack_choices > 0 then
			G.GAME.pack_choices = G.GAME.pack_choices + 1
			return {
				message = 'Sale!',
				colour = G.C.MONEY,
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
	pos = { x = 3, y = 0 },
	cost = 5,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.cards, card.ability.active } }
	end,
	calculate = function(self, card, context)
		if context.pre_discard then
			card.ability.active = true
			card.ability.extra.cards = #G.hand.highlighted + 1
			end

		if context.drawing_cards and card.ability.active then
			card.ability.active = nil
			return {
				cards_to_draw = card.ability.extra.cards,
				message = 'No Pulp!',
				colour = G.C.FILTER,
				card = card
			}
		end
	end
}

--[[ Deathbed
X2 Mult
1 in 8 chance this card is destroyed at end of
round to upgrade a random poker hand by 1 level
(Upgrade amount increases by 1 at end of round,
Destruction chance increases by 1 every ante)
]]
SMODS.Joker {
	key = 'deathbed',
	loc_txt = {
		name = 'Deathbed',
		text = {
			"{X:mult,C:white}X2{} Mult",
			"{C:green}#1# in #2#{} chance this card is destroyed at end of",
			"round to upgrade a random {C:attention}poker hand{} by {C:attention}#3#{} levels",
			"{C:inactive}(Upgrade amount increases by 1 at end of round,",
			"{C:inactive}Destruction chance increases by 1 every ante)"
		}
	},
	config = { extra = { chance = 1, odds = 8, upgrade = 1, xmult = 2 } },
	rarity = 2,
	atlas = 'noxious-balatro',
	pos = { x = 6, y = 0 },
	cost = 6,
	blueprint_compat = true,
	eternal_compat = false,
	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(card, card.ability.extra.chance, card.ability.extra.odds, 'nox_deathbed')
		return { vars = { numerator, denominator, card.ability.extra.upgrade } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = card.ability.extra.xmult
			}
		end
		if context.end_of_round and context.game_over == false then
			if SMODS.pseudorandom_probability(card, 'nox_deathbed', card.ability.extra.chance, card.ability.extra.odds) then
				local hands_list = {}
				for k, v in pairs(G.GAME.hands) do
					if v["visible"] == true then
						table.insert(hands_list, k)
					end
				end
				SMODS.smart_level_up_hand(card, hands_list[math.random(#hands_list)], nil, card.ability.extra.upgrade)
				SMODS.destroy_cards(card, nil, nil, true)

				return {
					message = "I'm a goner!",
					colour = G.C.MULT
				}
			end

			card.ability.extra.upgrade = card.ability.extra.upgrade + 1

			if G.GAME.blind.boss then
				if card.ability.extra.chance < card.ability.extra.odds then
					card.ability.extra.chance = card.ability.extra.chance + 1
				end
				if card.ability.extra.chance >= card.ability.extra.odds then
					local eval = function(card) return not card.REMOVED end
					juice_card_until(card, eval, true)
				end
				return {
					message = "*COUGH* *COUGH*",
					colour = G.C.FILTER
				}
			end
            return {
				message = "I'M OLD!",
				colour = G.C.FILTER
			}
        end
	end
}

--[[ Hangman
	X2 Mult
	X1 Mult for each time this 
	card is destroyed or sold
]]
SMODS.Joker {
	key = 'hangman',
	loc_txt = {
		name = 'Hangman',
		text = {
			"{X:mult,C:white}X#1#{} Mult",
			"{X:mult,C:white}X#2#{} Mult for each time this",
			"card is {C:attention}destroyed{} or {C:attention}sold{}"
		}
	},
	config = { extra = { xmult = 2, bonus_xmult = 1 } },
	rarity = 2,
	atlas = 'noxious-balatro',
	pos = { x = 6, y = 0 },
	cost = 5,
	blueprint_compat = true,
	eternal_compat = false,
	loc_vars = function(self, info_queue, card)
		if G.GAME.nox_hangman == nil then
			G.GAME.nox_hangman = 0
		end
		return { vars = { card.ability.extra.xmult + G.GAME.nox_hangman, card.ability.extra.bonus_xmult } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = card.ability.extra.xmult + G.GAME.nox_hangman
			}
		end
		if context.selling_self then
			G.GAME.nox_hangman = G.GAME.nox_hangman + card.ability.extra.bonus_xmult
			return {}
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
	pos = { x = 4, y = 0 },
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

        if context.end_of_round and context.cardarea == G.jokers and not G.GAME.blind.boss and not context.blueprint and context.game_over == false then
            card.ability.extra.hands = G.GAME.current_round.hands_left
			ease_hands_played(-G.GAME.current_round.hands_left)
            return {
                message = 'Hold It!',
				colour = G.C.BLUE,
				card = card
            }
        end

		if context.end_of_round and context.cardarea == G.jokers and G.GAME.blind.boss and not context.blueprint and context.game_over == false then
			card.ability.extra.hands_last = 0
            return {
                message = 'Adjourned!',
				colour = G.C.FILTER,
				card = card
            }
        end
	end
}

--[[ Double Vision
	Gives X1.5 Chips when
	any source of XMULT is
	triggered during scoring
]]
SMODS.Joker {
	key = 'seeingdouble',
	loc_txt = {
		name = 'Double Vision',
		text = {
			"Gives {X:chips,C:white}X#1#{} Chips when",
			"any source of {X:mult,C:white}XMULT{} is",
			"triggered during scoring"
		}
	},
	config = { extra = { xchips = 1.5 } },
	rarity = 3,
	atlas = 'noxious-balatro',
	pos = { x = 5, y = 0 },
	cost = 8,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xchips } }
	end,
	calculate = function(self, card, context)
		if context.nox_xmult then
			return {
				xchips = card.ability.extra.xchips
			}
		end
	end
}