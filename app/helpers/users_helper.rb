module UsersHelper
	def gap_solo_flex?
    if @game_account.game_id == 1
      if @game_account.flex_mmr.nil?
        get_game_rank_game_account_url(@game_account)
      end
      value1 = (@game_account.mmr / 200).floor
      value2 = (@game_account.flex_mmr / 200).floor
      numbers = [value1, value2].sort.reverse
      gap = numbers.first - numbers.last
      if gap >= 2 && value2 == numbers.last
        return true
      else
        return false
      end
    else
      return false
    end
  end
end
