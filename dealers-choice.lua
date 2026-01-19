SMODS.Atlas {
	-- Key for code to find it with
	key = "dealers-choice",
	-- The name of the file, for the code to pull the atlas from
	path = "dealers-choice.png",
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
		SMODS.calculate_context({deacho_xmult = true})
	end
	return ret
end

-- Money Detection
local ed = ease_dollars
function ease_dollars(mod, instant)
	if mod < 0 then
		SMODS.calculate_context({deacho_spend_money = true, deacho_spent_money = -mod})
	end
	local ret = ed(mod, instant)
	return ret
end

-- RNG Hook
local sprp = SMODS.pseudorandom_probability
function SMODS.pseudorandom_probability(trigger_obj, seed, base_numerator, base_denominator, identifier, no_mod)
	local numerator, denominator = SMODS.get_probability_vars(trigger_obj, base_numerator, base_denominator, identifier or seed, true, no_mod)
	if G.GAME.deacho_nosuprises then return numerator / denominator >= (1 / G.deacho_nosuprises_threshold ) end
	local ret = sprp(trigger_obj, seed, base_numerator, base_denominator, identifier, no_mod)
	return ret
end

-- Card:get_id hook
local cgid = Card.get_id
function Card:get_id()
	local ret = cgid(self)
	if G.GAME.deacho_proxy and not SMODS.has_no_rank(self) then
		--local prox_val = self.base.id
		for proxy_instance, proxy_value_a in pairs(G.GAME.deacho_proxy_a) do
			--if prox_val == proxy_value_a then prox_val = G.GAME.deacho_proxy_b[proxy_instance] end
			if self.base.id == proxy_value_a then return G.GAME.deacho_proxy_b[proxy_instance] end
		end
		--return prox_val
	end
	return ret
end

local csdbf = Card.set_debuff
function Card:set_debuff(should_debuff)
	local ret = csdbf(self, should_debuff)

	if self.seal and self.seal == "deacho_Silver" then
		self.debuff = false
		return
	end

	return ret
end

-- Seals

--[[ Silver Seal
	This card cannot be debuffed
]]
SMODS.Seal {
    key = 'Silver',
	atlas = 'dealers-choice',
    pos = { x = 0, y = 6 },
    badge_colour = G.C.EDITION,
    draw = function(self, card, layer)
        if (layer == 'card' or layer == 'both') and card.sprite_facing == 'front' then
            G.shared_seals[card.seal].role.draw_major = card
            G.shared_seals[card.seal]:draw_shader('dissolve', nil, nil, nil, card.children.center)
            G.shared_seals[card.seal]:draw_shader('voucher', nil, card.ARGS.send_to_shader, nil, card.children.center)
        end
    end
}

-- Spectral Cards

--[[ Ward
	Add a Silver Seal
	to 1 selected 
	card in your hand
]]
SMODS.Consumable {
    key = 'ward',
    set = 'Spectral',
	loc_txt = {
		name = 'Ward',
		text = {
			"Add a {C:inactive}Silver Seal{}",
			"to {C:attention}1{} selected",
			"card in your hand",
		}
	},
	atlas = 'dealers-choice',
    pos = { x = 1, y = 5 },
    config = { extra = { seal = 'deacho_Silver' }, max_highlighted = 1 },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_SEALS[card.ability.extra.seal]
        return { vars = { card.ability.max_highlighted } }
    end,
    use = function(self, card, area, copier)
        local conv_card = G.hand.highlighted[1]
        G.E_MANAGER:add_event(Event({
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                return true
            end
        }))

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                conv_card:set_seal(card.ability.extra.seal, nil, true)
				conv_card:set_debuff()
                return true
            end
        }))

        delay(0.5)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.2,
            func = function()
                G.hand:unhighlight_all()
                return true
            end
        }))
    end,
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
	atlas = 'dealers-choice',
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
			"{C:mult}+#1#{} Mult every time any other",
			"{C:attention}Joker{} is triggered during scoring",
			"{s:0.8}Ignores Salt and Pepper"
		}
	},
	config = { extra = { mult = 2 }, active = nil },
	rarity = 1,
	atlas = 'dealers-choice',
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
	config = { extra = { chips = 10 }, active = nil },
	rarity = 1,
	atlas = 'dealers-choice',
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
	atlas = 'dealers-choice',
	pos = { x = 6, y = 2 },
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

--[[ Proxy
	All cards of rank X count
	as cards of rank Y instead
]]

function rank_to_string(rank)
	if rank == 11 then
		return "Jack"
	elseif rank == 12 then
		return "Queen"
	elseif rank == 13 then
		return "King"
	elseif rank == 14 then
		return "Ace"
	end
	return tostring(rank)
end

SMODS.Joker {
	key = 'proxy',
	loc_txt = {
		name = 'Proxy',
		text = {
			"All {C:attention}#1#s{} count",
			"as {C:attention}#2#s{} instead",
		}
	},
	config = { extra = { proxy_a = 0, proxy_b = 0 } },
	rarity = 1,
	atlas = 'dealers-choice',
	pos = { x = 1, y = 0 },
	cost = 3,
	blueprint_compat = false,
	loc_vars = function(self, info_queue, card)
		if not G.GAME.deacho_proxy or card.ability.extra.proxy_a == 0 or card.ability.extra.proxy_b == 0 then
			return { vars = { 'X', 'Y' } }
		end
		return { vars = { rank_to_string(card.ability.extra.proxy_a), rank_to_string(card.ability.extra.proxy_b) } }
	end,
	add_to_deck = function(self, card, from_debuff)
        if not G.GAME.deacho_proxy then G.GAME.deacho_proxy = 0 end
		G.GAME.deacho_proxy = G.GAME.deacho_proxy + 1
		if not from_debuff then
			if not G.GAME.deacho_proxy_a then G.GAME.deacho_proxy_a = {} end
			if not G.GAME.deacho_proxy_b then G.GAME.deacho_proxy_b = {} end
			card.ability.extra.proxy_a = math.random(2, SMODS.Rank.max_id.value)
			card.ability.extra.proxy_b = math.random(2, SMODS.Rank.max_id.value)
			if card.ability.extra.proxy_b == card.ability.extra.proxy_a then
				card.ability.extra.proxy_b = card.ability.extra.proxy_b < 14 and card.ability.extra.proxy_b + 1 or 2
			end
		end
		G.GAME.deacho_proxy_a[card.sort_id] = card.ability.extra.proxy_a
		G.GAME.deacho_proxy_b[card.sort_id] = card.ability.extra.proxy_b
    end,
    remove_from_deck = function(self, card, from_debuff)
		G.GAME.deacho_proxy_a[card.sort_id] = nil
		G.GAME.deacho_proxy_b[card.sort_id] = nil
		if G.GAME.deacho_proxy > 1 then
        	G.GAME.deacho_proxy = G.GAME.deacho_proxy - 1
		else
			G.GAME.deacho_proxy = nil
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
	atlas = 'dealers-choice',
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
	atlas = 'dealers-choice',
	pos = { x = 6, y = 1 },
	cost = 6,
	blueprint_compat = true,
	eternal_compat = false,
	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(card, card.ability.extra.chance, card.ability.extra.odds, 'deacho_deathbed')
		return { vars = { numerator, denominator, card.ability.extra.upgrade } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = card.ability.extra.xmult
			}
		end
		if context.end_of_round and context.game_over == false then
			if SMODS.pseudorandom_probability(card, 'deacho_deathbed', card.ability.extra.chance, card.ability.extra.odds) then
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
	X2 Mult for each time this card
	was destroyed or sold this run
]]
SMODS.Joker {
	key = 'rasputin',
	loc_txt = {
		name = 'Rasputin',
		text = {
			"{X:mult,C:white}X#1#{} Mult",
			"{X:mult,C:white}X#2#{} Mult for each time this card",
			"was {C:attention}destroyed{} or {C:attention}sold{} this run"
		}
	},
	config = { extra = { xmult = 2, bonus_xmult = 2 } },
	rarity = 2,
	atlas = 'dealers-choice',
	pos = { x = 7, y = 2 },
	cost = 6,
	blueprint_compat = true,
	eternal_compat = false,
	loc_vars = function(self, info_queue, card)
		if G.GAME.deacho_rasputin == nil then
			G.GAME.deacho_rasputin = 0
		end
		return { vars = { card.ability.extra.xmult + G.GAME.deacho_rasputin, card.ability.extra.bonus_xmult } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = card.ability.extra.xmult + G.GAME.deacho_rasputin
			}
		end
		if context.blueprint and context.selling_self then
			G.GAME.deacho_rasputin = G.GAME.deacho_rasputin + card.ability.extra.bonus_xmult
		end
	end,
	remove_from_deck = function(self, card, from_debuff)
		if not from_debuff then
			G.GAME.deacho_rasputin = G.GAME.deacho_rasputin + card.ability.extra.bonus_xmult
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
			"{C:dark_edition}edition{} every {C:money}#1#${} {C:inactive}[#2#]{} spent",
			"{C:inactive}(Currently Level {C:dark_edition}#3#{C:inactive})"
		}
	},
	config = { extra = { money_tracker = 0, level = 0, level_cost = 40, foil_chips = 50, holo_mult = 10, poly_xmult = 1.5 } },
	rarity = 2,
	atlas = 'dealers-choice',
	pos = { x = 0, y = 2 },
	soul_pos = { x = -1, y = 0},
	cost = 6,
	blueprint_compat = false,
	loc_vars = function(self, info_queue, card)
		if card.ability.extra.level > 0 then info_queue[#info_queue+1] = {key = 'deacho_foil', set = 'Other' } end
		if card.ability.extra.level > 1 then info_queue[#info_queue+1] = {key = 'deacho_holo', set = 'Other' } end
		if card.ability.extra.level > 2 then info_queue[#info_queue+1] = {key = 'deacho_poly', set = 'Other' } end
		if card.ability.extra.level > 3 then info_queue[#info_queue+1] = {key = 'deacho_negative', set = 'Other' } end
		local remaining_exp = 0
		if card.ability.extra.level < 4 then
			remaining_exp = card.ability.extra.level_cost - card.ability.extra.money_tracker
		end
		-- Bandaid fix for changing sprite when save is loaded
		card.children.center:set_sprite_pos({x = card.ability.extra.level, y = 2})
		local level_print = ""
		if card.ability.extra.level == 4 then
			card.children.floating_sprite:set_sprite_pos({ x = 5, y = 2})
			level_print = "MAX"
		else
			level_print = tostring(card.ability.extra.level)
		end
		return { vars = {
			card.ability.extra.level_cost,
			remaining_exp,
			level_print,
		 } }
	end,
	calculate = function(self, card, context)
		if not context.blueprint and context.deacho_spend_money and card.ability.extra.level < 4 and (context.locked_card == nil or context.locked_card == card) then
			card.ability.extra.money_tracker = card.ability.extra.money_tracker + context.deacho_spent_money
			if card.ability.extra.money_tracker >= card.ability.extra.level_cost and card.ability.extra.level < 4 then
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.4,
					func = function()
						play_sound('tarot1')
						card:juice_up(0.3, 0.5)
						return true
					end
				}))
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.15,
					func = function()
						card:flip()
						play_sound('card1')
						card:juice_up(0.3, 0.3)
						return true
					end
				}))
				delay(0.2)
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.1,
					func = function()
						card.ability.extra.money_tracker = card.ability.extra.money_tracker - card.ability.extra.level_cost
						card.ability.extra.level = card.ability.extra.level + 1
						card.children.center:set_sprite_pos({x = card.ability.extra.level, y = 2})
						if card.ability.extra.level == 4 then
							G.jokers.config.card_limit = G.jokers.config.card_limit + 1
							card.children.floating_sprite:set_sprite_pos({ x = 5, y = 2})
						end
						attention_text({
							text = "Level Up!",
							scale = 1.3,
							hold = 1.4,
							major = card,
							backdrop_colour = G.C.FILTER,
							offset = { x = 0, y = 0 },
							silent = true
						})
						return true
					end
				}))
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.15,
					func = function()
						if card.ability.extra.money_tracker >= card.ability.extra.level_cost and card.ability.extra.level < 4 then
							SMODS.calculate_context({deacho_spend_money = true, deacho_spent_money = 0, locked_card = card})
						end
						card:flip()
						play_sound('tarot2')
						card:juice_up(0.3, 0.3)
						return true
					end
				}))
			end
			return {}
		end
		if not context.blueprint and context.joker_main then
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
	end,
	add_to_deck = function(self, card, from_debuff)
        if card.ability.extra.level == 4 then
			G.jokers.config.card_limit = G.jokers.config.card_limit + 1
		end
    end,
    remove_from_deck = function(self, card, from_debuff)
        if card.ability.extra.level == 4 then
			G.jokers.config.card_limit = G.jokers.config.card_limit - 1
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
	atlas = 'dealers-choice',
	pos = { x = 4, y = 0 },
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
	Played Sevens either give +7 chips,
	+7 Mult, or +$7 when scored
]]
SMODS.Joker {
	key = '777',
	loc_txt = {
		name = 'Lucky Sevens',
		text = {
			"Played {C:attention}Sevens{} either give {C:chips}+#1#{} chips,",
			"{C:mult}+#1#{} Mult or {C:money}$#1#{} when scored"
		}
	},
	config = { extra = { jackpot = 7 } },
	rarity = 2,
	atlas = 'dealers-choice',
	pos = { x = 8, y = 1 },
	cost = 5,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.jackpot } }
	end,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.play then
			if context.other_card:get_id() == 7 then
				local reward = math.random(3)
				if reward == 1 then
					return {
						chips = card.ability.extra.jackpot
					}
				elseif reward == 2 then
					return {
						mult = card.ability.extra.jackpot
					}
				elseif reward == 3 then
					ease_dollars(card.ability.extra.jackpot)
					return {
						message = "$" .. tostring(card.ability.extra.jackpot),
						colour = G.C.MONEY
					}
				end
			end
		end
	end
}

--[[ Sidewalk
	Gives X0.1 chips for each unique
	scoring rank in the current hand
]]
SMODS.Joker {
    key = "sidewalk",
	loc_txt = {
		name = 'Sidewalk',
		text = {
			"Gives {X:chips,C:white}X#1#{} chips for each unique",
			"scoring {C:attention}rank{} in the {C:attention}current hand{}",
		}
	},
	atlas = 'dealers-choice',
    pos = { x = 2, y = 0 },
    rarity = 2,
    blueprint_compat = true,
    cost = 5,
    config = { extra = { xchips = 0.1, message_a = "Hop", message_b = "Skip" } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xchips } }
    end,
    calculate = function(self, card, context)
		if context.before then
			G.GAME.deacho_sidewalk_scored_ranks[context.blueprint and context.blueprint_card.sort_id or card.sort_id] = {}
			G.GAME.deacho_sidewalk_score[context.blueprint and context.blueprint_card.sort_id or card.sort_id] = 0
		end
        if context.individual and context.cardarea == G.play and not G.GAME.deacho_sidewalk_scored_ranks[context.blueprint and context.blueprint_card.sort_id or card.sort_id][context.other_card:get_id()] then
			G.GAME.deacho_sidewalk_scored_ranks[context.blueprint and context.blueprint_card.sort_id or card.sort_id][context.other_card:get_id()] = true
			G.GAME.deacho_sidewalk_score[context.blueprint and context.blueprint_card.sort_id or card.sort_id] = G.GAME.deacho_sidewalk_score[context.blueprint and context.blueprint_card.sort_id or card.sort_id] + 1
			local retmsg = ""
			if G.GAME.deacho_sidewalk_message then
				retmsg = card.ability.extra.message_a
				G.GAME.deacho_sidewalk_message = nil
			else
				retmsg = card.ability.extra.message_b
				G.GAME.deacho_sidewalk_message = true
			end
            return {
				message = retmsg,
				colour = G.GAME.deacho_hopscotch_colors[ math.random( #G.GAME.deacho_hopscotch_colors ) ]
            }
        end
		if context.joker_main then
			return {
				xchips = 1 + G.GAME.deacho_sidewalk_score[context.blueprint and context.blueprint_card.sort_id or card.sort_id] * card.ability.extra.xchips
			}
		end
    end,
	add_to_deck = function (self, card, from_debuff)
		if not G.GAME.deacho_sidewalk_scored_ranks then
			G.GAME.deacho_sidewalk_scored_ranks = {}
		end
		if not G.GAME.deacho_sidewalk_score then
			G.GAME.deacho_sidewalk_score = {}
		end
		if not G.GAME.deacho_hopscotch_colors then
			G.GAME.deacho_hopscotch_colors = {
				HEX('d6f8ff'),
				HEX('c7e5ff'),
				HEX('ffd6f8'),
				HEX('a2ffaf'),
				HEX('f4ffa4'),
				HEX('f5e4ff'),
				HEX('ffbc7e'),
				HEX('ff9b9b'),
			}
		end
	end
}

--[[ Pedigree
	Common Jokers may not appear
]]
SMODS.Joker {
    key = "pedigree",
	loc_txt = {
		name = 'Pedigree',
		text = {
			"{C:common}Common{} Jokers may not appear",
		}
	},
	atlas = 'dealers-choice',
    pos = { x = 3, y = 0 },
    rarity = 2,
    blueprint_compat = false,
    cost = 6,
    config = { extra = { common_weight = 0 } },
	add_to_deck = function (self, card, from_debuff)
		if not G.GAME.deacho_pedigree then
			G.GAME.deacho_pedigree = 1
			G.GAME.common_mod = 0
		else
			G.GAME.deacho_pedigree = G.GAME.deacho_pedigree + 1
		end
	end,
	remove_from_deck = function (self, card, from_debuff)
		if G.GAME.deacho_pedigree > 1 then
			G.GAME.deacho_pedigree = G.GAME.deacho_pedigree - 1
		else
			G.GAME.deacho_pedigree = nil
			G.GAME.common_mod = 1
		end
	end
}

--[[ Scalper
	Only Mega Booster Packs 
	may appear in shops
]]
SMODS.Joker {
    key = "scalper",
	loc_txt = {
		name = 'Scalper',
		text = {
			"Only {C:attention}Mega{} Booster Packs",
			"may appear in shops"
		}
	},
	atlas = 'dealers-choice',
    pos = { x = 5, y = 0 },
    rarity = 2,
    blueprint_compat = false,
    cost = 7,
    config = { extra = { } },
	add_to_deck = function (self, card, from_debuff)
		if not G.GAME.scalper then
			G.GAME.deacho_scalper = 1
			G.GAME.banned_keys.p_arcana_normal_1 = true
			G.GAME.banned_keys.p_arcana_normal_2 = true
			G.GAME.banned_keys.p_arcana_normal_3 = true
			G.GAME.banned_keys.p_arcana_normal_4 = true
			G.GAME.banned_keys.p_arcana_jumbo_1 = true
			G.GAME.banned_keys.p_arcana_jumbo_2 = true
			G.GAME.banned_keys.p_celestial_normal_1 = true
			G.GAME.banned_keys.p_celestial_normal_2 = true
			G.GAME.banned_keys.p_celestial_normal_3 = true
			G.GAME.banned_keys.p_celestial_normal_4 = true
			G.GAME.banned_keys.p_celestial_jumbo_1 = true
			G.GAME.banned_keys.p_celestial_jumbo_2 = true
			G.GAME.banned_keys.p_spectral_normal_1 = true
			G.GAME.banned_keys.p_spectral_normal_2 = true
			G.GAME.banned_keys.p_spectral_jumbo_1 = true
			G.GAME.banned_keys.p_standard_normal_1 = true
			G.GAME.banned_keys.p_standard_normal_2 = true
			G.GAME.banned_keys.p_standard_normal_3 = true
			G.GAME.banned_keys.p_standard_normal_4 = true
			G.GAME.banned_keys.p_standard_jumbo_1 = true
			G.GAME.banned_keys.p_standard_jumbo_2 = true
			G.GAME.banned_keys.p_buffoon_normal_1 = true
			G.GAME.banned_keys.p_buffoon_normal_2 = true
			G.GAME.banned_keys.p_buffoon_jumbo_1 = true
		else
			G.GAME.deacho_scalper = G.GAME.deacho_scalper + 1
		end
	end,
	remove_from_deck = function (self, card, from_debuff)
		if G.GAME.deacho_scalper > 1 then
			G.GAME.deacho_scalper = G.GAME.deacho_scalper - 1
		else
			G.GAME.deacho_scalper = nil
			G.GAME.banned_keys.p_arcana_normal_1 = nil
			G.GAME.banned_keys.p_arcana_normal_2 = nil
			G.GAME.banned_keys.p_arcana_normal_3 = nil
			G.GAME.banned_keys.p_arcana_normal_4 = nil
			G.GAME.banned_keys.p_arcana_jumbo_1 = nil
			G.GAME.banned_keys.p_arcana_jumbo_2 = nil
			G.GAME.banned_keys.p_celestial_normal_1 = nil
			G.GAME.banned_keys.p_celestial_normal_2 = nil
			G.GAME.banned_keys.p_celestial_normal_3 = nil
			G.GAME.banned_keys.p_celestial_normal_4 = nil
			G.GAME.banned_keys.p_celestial_jumbo_1 = nil
			G.GAME.banned_keys.p_celestial_jumbo_2 = nil
			G.GAME.banned_keys.p_spectral_normal_1 = nil
			G.GAME.banned_keys.p_spectral_normal_2 = nil
			G.GAME.banned_keys.p_spectral_jumbo_1 = nil
			G.GAME.banned_keys.p_standard_normal_1 = nil
			G.GAME.banned_keys.p_standard_normal_2 = nil
			G.GAME.banned_keys.p_standard_normal_3 = nil
			G.GAME.banned_keys.p_standard_normal_4 = nil
			G.GAME.banned_keys.p_standard_jumbo_1 = nil
			G.GAME.banned_keys.p_standard_jumbo_2 = nil
			G.GAME.banned_keys.p_buffoon_normal_1 = nil
			G.GAME.banned_keys.p_buffoon_normal_2 = nil
			G.GAME.banned_keys.p_buffoon_jumbo_1 = nil
		end
	end
}

--[[ Kitchen Sink
	When Blind is selected gain all unused
	discards from the previous round
	(Currently 0)
]]
SMODS.Joker {
	key = 'letthatsinkin',
	loc_txt = {
		name = 'Kitchen Sink',
		text = {
			"When {C:attention}Blind{} is selected, gain all unused",
			"discards from the previous round",
			"{C:inactive}(Will give {C:red}+#1#{C:inactive} Discards next blind)"
		}
	},
	config = { extra = { discards = 0, display_discards = 0 } },
	rarity = 2,
	atlas = 'dealers-choice',
	pos = { x = 6, y = 0 },
	cost = 4,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.display_discards } }
	end,
	calculate = function(self, card, context)
		if context.setting_blind and card.ability.extra.discards > 0 then
			if not context.blueprint then
				card.ability.extra.display_discards = 0
			end
			ease_discard(card.ability.extra.discards)
			return {
				message = '+' .. tostring(card.ability.extra.discards) .. ' Discards',
				colour = G.C.FILTER,
				card = card
			}
		end
        if context.end_of_round and context.cardarea == G.jokers and not context.blueprint and context.game_over == false then
			card.ability.extra.discards = G.GAME.current_round.discards_left
			card.ability.extra.display_discards = card.ability.extra.discards
            return {
                message = 'Let that sink in...',
				colour = G.C.RED,
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
	config = { extra = { display_hands = 0, hands = 0 } },
	rarity = 3,
	atlas = 'dealers-choice',
	pos = { x = 4, y = 1 },
	cost = 10,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.display_hands } }
	end,
	calculate = function(self, card, context)
		if context.setting_blind and card.ability.extra.hands > 0 then
			if not context.blueprint then
				card.ability.extra.display_hands = 0
			end
			ease_hands_played(card.ability.extra.hands)
			return {
				message = '+' .. tostring(card.ability.extra.hands) .. ' Hands',
				colour = G.C.FILTER,
				card = card
			}
		end
        if context.end_of_round and context.cardarea == G.jokers and not context.blueprint and context.game_over == false then
			if G.GAME.blind.boss then
				card.ability.extra.hands = 0
				card.ability.extra.display_hands = card.ability.extra.hands
            	return {
            	    message = 'Adjourned!',
					colour = G.C.FILTER,
					card = card
            	}
			else
				card.ability.extra.hands = G.GAME.current_round.hands_left
				card.ability.extra.display_hands = card.ability.extra.hands
				ease_hands_played(-G.GAME.current_round.hands_left)
            	return {
            	    message = 'Hold It!',
					colour = G.C.BLUE,
					card = card
            	}
			end
			
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
	atlas = 'dealers-choice',
	pos = { x = 5, y = 1 },
	cost = 8,
	blueprint_compat = true,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xchips } }
	end,
	calculate = function(self, card, context)
		if context.deacho_xmult then
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
	atlas = 'dealers-choice',
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
	Events with a probability of 1 in 5 or higher always occur
	Events with a probability less than 1 in 5 never occur
]]
G.deacho_nosuprises_threshold = 5
SMODS.Joker {
	key = 'nosuprises',
	loc_txt = {
		name = 'No Suprises',
		text = {
			"Events with a {C:green}probability{} of {C:green}1{} in {C:green}#1#{} or higher {C:attention}always{} occur",
			"Events with a {C:green}probability{} less than {C:green}1{} in {C:green}#1#{} {C:attention}never{} occur"
		}
	},
	rarity = 3,
	atlas = 'dealers-choice',
	pos = { x = 0, y = 3 },
	cost = 8,
	blueprint_compat = false,
	loc_vars = function(self, info_queue, card)
		return { vars = { G.deacho_nosuprises_threshold } }
	end,
	add_to_deck = function(self, card, from_debuff)
        if G.GAME.deacho_nosuprises then
			G.GAME.deacho_nosuprises = G.GAME.deacho_nosuprises + 1
		else
			G.GAME.deacho_nosuprises = 1
		end
    end,
    remove_from_deck = function(self, card, from_debuff)
		if G.GAME.deacho_nosuprises > 1 then
        	G.GAME.deacho_nosuprises = G.GAME.deacho_nosuprises - 1
		else
			G.GAME.deacho_nosuprises = nil
		end
	end
}