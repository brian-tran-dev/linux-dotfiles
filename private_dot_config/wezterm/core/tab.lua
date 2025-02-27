local is_tab_title_set = {}
return {
	mark = function(tab_id)
		is_tab_title_set[tab_id] = true
	end,

	not_marked = function(tab_id)
		return is_tab_title_set[tab_id] == nil
	end
}
