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
		if self.config.center_key == "j_nox_rasputin" then
			G.GAME.nox_rasputin = G.GAME.nox_rasputin + self.ability.extra.bonus_xmult
		end
		if self.config.center_key == "j_nox_hero" and self.ability.extra.level == 4 then
			G.jokers.config.card_limit = G.jokers.config.card_limit - 1
		end
		if self.config.center_key == "j_nox_nosuprises" then
			G.GAME.nox_nosuprises = nil
		end
	end
	local ret = remove_card(self, from_debuff)
	return ret
end

-- Money Detection
local ed = ease_dollars
function ease_dollars(mod, instant)
	if mod < 0 then
		SMODS.calculate_context({nox_spend_money = true, nox_spent_money = -mod})
	end
	local ret = ed(mod, instant)
	return retw
end

-- RNG Hook local numerator, _ = SMODS.get_probability_vars(card, card.ability.extra.chance, card.ability.extra.odds, 'nox_777')
local sprp = SMODS.pseudorandom_probability
function SMODS.pseudorandom_probability(trigger_obj, seed, base_numerator, base_denominator, identifier, no_mod)
	local numerator, denominator = SMODS.get_probability_vars(trigger_obj, base_numerator, base_denominator, identifier or seed, true, no_mod)
	if G.GAME.nox_nosuprises then return numerator / denominator >= 0.25 end
	local ret = sprp(trigger_obj, seed, base_numerator, base_denominator, identifier, no_mod)
	return ret
end

-- Card added hook
local catd = Card.add_to_deck
function Card:add_to_deck(from_debuff)
		if self.config.center_key == "j_nox_nosuprises" then
			G.GAME.nox_nosuprises = true
		end
	local ret = catd(self, from_debuff)
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
	pos = { x = 2, y = 1 },
	cost = 3,
	blueprint_compat = true,
	eternal_compat = false,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.cards } }
	end,
	calculate = function(self, card, context)
		if context.selling_self and G.hand and #G.hand.cards >= 1 then
			SMODS.draw_cards(card.ability.extra.cards)
			return {
				message = 'TA-DA!',
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
	pos = { x = 0, y = 1 },
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
			"{C:chips}+#1#{} Chips every time any other",
			"{C:attention}Joker{} is triggered during scoring",
			"{s:0.8}Ignores Salt and Pepper"
		}
	},
	config = { extra = { chips = 8 }, active = nil },
	rarity = 1,
	atlas = 'noxious-balatro',
	pos = { x = 1, y = 1 },
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
	pos = { x = 5, y = 2 },
	cost = 3,
	blueprint_compat = true,
	eternal_compat = false,
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
	pos = { x = 3, y = 1 },
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
	pos = { x = 6, y = 1 },
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

--[[ Rasputin
	X2 Mult
	X1 Mult for each time this card
	is destroyed or sold this run
]]
SMODS.Joker {
	key = 'rasputin',
	loc_txt = {
		name = 'Rasputin',
		text = {
			"{X:mult,C:white}X#1#{} Mult",
			"{X:mult,C:white}X#2#{} Mult for each time this card",
			"is {C:attention}destroyed{} or {C:attention}sold{} this run"
		}
	},
	config = { extra = { xmult = 2, bonus_xmult = 1 } },
	rarity = 2,
	atlas = 'noxious-balatro',
	pos = { x = 6, y = 2 },
	cost = 5,
	blueprint_compat = true,
	eternal_compat = false,
	loc_vars = function(self, info_queue, card)
		if G.GAME.nox_rasputin == nil then
			G.GAME.nox_rasputin = 0
		end
		return { vars = { card.ability.extra.xmult + G.GAME.nox_rasputin, card.ability.extra.bonus_xmult } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = card.ability.extra.xmult + G.GAME.nox_rasputin
			}
		end
		if context.selling_self then
			G.GAME.nox_rasputin = G.GAME.nox_rasputin + card.ability.extra.bonus_xmult
			return {}
		end
	end
}

--[[ Side Quest
	This card gains an innate
	edition every 40$ spent
]]
SMODS.Joker {
	key = 'hero',
	loc_txt = {
		name = 'Side Quest',
		text = {
			"This card gains an {C:attention}innate{}",
			"{C:dark_edition}edition{} every {C:money}#3#${} {C:inactive}[#1#]{} spent",
			"{C:inactive}(Currently Level {C:dark_edition}#2#{C:inactive})"
		}
	},
	config = { extra = { money_tracker = 0, level = 0, level_cost = 40, foil_chips = 50, holo_mult = 10, poly_xmult = 1.5 } },
	rarity = 2,
	atlas = 'noxious-balatro',
	pos = { x = 0, y = 2 },
	cost = 6,
	blueprint_compat = false,
	loc_vars = function(self, info_queue, card)
		if card.ability.extra.level > 0 then info_queue[#info_queue+1] = {key = 'nox_foil', set = 'Other' } end
		if card.ability.extra.level > 1 then info_queue[#info_queue+1] = {key = 'nox_holo', set = 'Other' } end
		if card.ability.extra.level > 2 then info_queue[#info_queue+1] = {key = 'nox_poly', set = 'Other' } end
		if card.ability.extra.level > 3 then info_queue[#info_queue+1] = {key = 'nox_negative', set = 'Other' } end
		local remaining_exp = 0
		if card.ability.extra.level < 4 then
			remaining_exp = card.ability.extra.level_cost - card.ability.extra.money_tracker
		end
		return { vars = {
			remaining_exp,
			card.ability.extra.level,
			card.ability.extra.level_cost,
		 } }
	end,
	calculate = function(self, card, context)
		if context.nox_spend_money and card.ability.extra.level < 4 then
			card.ability.extra.money_tracker = card.ability.extra.money_tracker + context.nox_spent_money
			while card.ability.extra.money_tracker >= card.ability.extra.level_cost and card.ability.extra.level < 4 do
				card.ability.extra.money_tracker = card.ability.extra.money_tracker - card.ability.extra.level_cost
				card.ability.extra.level = card.ability.extra.level + 1
			end
			if card.ability.extra.level == 4 then
				G.jokers.config.card_limit = G.jokers.config.card_limit + 1
			end
			return {}
		end
		if context.joker_main then
			if card.ability.extra.level > 2 then
				return {
					chips = card.ability.extra.foil_chips,
					mult = card.ability.extra.holo_mult,
					x_mult = card.ability.extra.poly_xmult
					
				}
			end
			if card.ability.extra.level > 1 then
				return {
					chips = card.ability.extra.foil_chips,
					mult = card.ability.extra.holo_mult
				}
			end
			if card.ability.extra.level > 0 then
				return {
					chips = card.ability.extra.foil_chips
				}
			end
		end
		if context.card_added and context.cardarea == G.jokers and context.card == self then
			if card.ability.extra.level == 4 then
				G.jokers.config.card_limit = G.jokers.config.card_limit + 1
			end
		end
	end
}

--[[ In the Red
	X0.2 Mult for every 
	$1 below $0 you have
]]
SMODS.Joker {
	key = 'inthered',
	loc_txt = {
		name = 'In the Red',
		text = {
			"{X:mult,C:white}X#1#{} Mult for every",
			"{C:money}$1{} below {C:money}$0{} you have",
			"{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)"
		}
	},
	config = { extra = { xmult = 0.2 } },
	rarity = 2,
	atlas = 'noxious-balatro',
	pos = { x = 0, y = 1 },
	cost = 5,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult, 1 - (card.ability.extra.xmult * math.min((G.GAME.dollars or 0) + (G.GAME.dollar_buffer or 0), 0)) } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = 1 - (card.ability.extra.xmult * math.min((G.GAME.dollars or 0) + (G.GAME.dollar_buffer or 0), 0))
			}
		end
	end
}

--[[ Lucky Sevens
	Gives a chance to gain $7 based on
	number of scoring 7s in played hand
	(Currently 1 in 7 for each 7)
]]
SMODS.Joker {
	key = '777',
	loc_txt = {
		name = 'Lucky Sevens',
		text = {
			"Gives a chance to gain {C:money}$#3#{} based on",
			"number of scoring {C:attention}7s{} in {C:attention}played hand",
			"{C:inactive}(Currently {C:green}#1#{} {C:inactive}in {C:green}#2#{} {C:inactive}for each {C:attention}7{C:inactive})"
		}
	},
	config = { extra = { chance = 1, odds = 7, cash = 7 } },
	rarity = 2,
	atlas = 'noxious-balatro',
	pos = { x = 8, y = 1 },
	cost = 5,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(card, card.ability.extra.chance, card.ability.extra.odds, 'nox_777')
		return { vars = { numerator, denominator, card.ability.extra.cash } }
	end,
	calculate = function(self, card, context)
		if context.before then
			local sevens = 0
			for _, playing_card in ipairs(context.scoring_hand) do
                if playing_card.base.value == '7' then
					sevens = sevens + 1
                end
            end
			if sevens > 0 and SMODS.pseudorandom_probability(card, 'nox_777', sevens, card.ability.extra.odds) then
				ease_dollars(card.ability.extra.cash, nil)
				return {
					message = "Jackpot!",
					colour = G.C.MONEY
				}
			end
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
	pos = { x = 4, y = 1 },
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
	config = { extra = { xchips = 1.25 } },
	rarity = 3,
	atlas = 'noxious-balatro',
	pos = { x = 5, y = 1 },
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

--[[ Pumpkin Carriage
	This Joker gains +0.25X Mult per
	consecutive hand played without
	a scoring number card or ace
]]
SMODS.Joker {
	key = 'pupmkincarriage',
	loc_txt = {
		name = 'Pumpkin Carriage',
		text = {
			"This Joker gains {X:mult,C:white}X#1#{} Mult per",
			"{C:attention}consecutive{} hand played without",
			"a scoring {C:attention}number{} card or {C:attention}ace{}",
			"{C:inactive}(Currently{} {X:mult,C:white}X#2#{} {C:inactive}Mult)"
		}
	},
	config = { extra = { xmult = 0.25, bonus_xmult = 1 } },
	rarity = 3,
	atlas = 'noxious-balatro',
	pos = { x = 7, y = 1 },
	cost = 8,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult, card.ability.extra.bonus_xmult } }
	end,
	calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local numcard = false
            for _, playing_card in ipairs(context.scoring_hand) do
                if not playing_card:is_face() and playing_card.ability.effect ~= 'Stone Card' then
                    numcard = true
                    break
                end
            end
            if numcard then
                local last_mult = card.ability.extra.bonus_xmult
                card.ability.extra.bonus_xmult = 1
                if last_mult > 1 then
                    return {
                        message = localize('k_reset')
                    }
                end
            else
                -- See note about SMODS Scaling Manipulation on the wiki
                card.ability.extra.bonus_xmult = card.ability.extra.bonus_xmult + card.ability.extra.xmult
            end
        end
        if context.joker_main then
            return {
               xmult = card.ability.extra.bonus_xmult
            }
        end
	end
}

--[[ No Suprises
	Events with a probability of 1 in 4 or higher always occur
	Events with a probability less than 1 in 4 never occur
]]
SMODS.Joker {
	key = 'nosuprises',
	loc_txt = {
		name = 'No Suprises',
		text = {
			"Events with a {C:green}probability{} of {C:green}1{} in {C:green}4{} or higher {C:attention}always{} occur",
			"Events with a {C:green}probability{} less than {C:green}1{} in {C:green}4{} {C:attention}never{} occur"
		}
	},
	rarity = 3,
	atlas = 'noxious-balatro',
	pos = { x = 4, y = 1 },
	cost = 8,
	blueprint_compat = false,
	loc_vars = function(self, info_queue, card)
		return {}
	end,
	calculate = function(self, card, context)
        if context.card_added and context.cardarea == G.jokers and context.card == self then
			G.GAME.nox_nosuprises = true
		end
	end
}