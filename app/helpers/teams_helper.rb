module TeamsHelper
	#si tu aimes te servir des helper lâche toi, j'en ai pas encore l'habitude perso

  def remplacants?
    @team.teamings.where(active:true).joins(:user).where.not(:users => { state: 2 }).count > 0
  end

  def captain?
    ((can? :manage, Friendship) or @team.teamings.where(user: current_user, active:true, captain:true).present?)
  end

  def simplify_age(age)
    if age < 14
			return 14
    elsif age > 25
			return 25
    else
			return age
		end
  end

  def simplify_hour(h)
  	if h < 9
  		return h + 24
  	else
  		return h
    end
  end

  def compatible_hours?(team)
    @team = team
    @members = @team.members
    @week_start = @members.pluck(:week_start).reject(&:nil?).sort.last
    @week_end = @members.pluck(:week_end).reject(&:nil?).sort.first
    @we_start = @members.pluck(:we_start).reject(&:nil?).sort.last
    @we_end = @members.pluck(:we_end).reject(&:nil?).sort.first
    if (@members.where(week_start:0).present? or @members.where(week_end:0).present?) && (@members.where(we_start:0).present? or @members.where(we_end:0).present?)
      return false
    elsif @week_start >= @week_end && @we_start >= @we_end
      return false
    else
      return true
    end
  end

  def game_info_url(account)
    @account = account
    if @account.game_id == 1
      return "https://euw.op.gg/summoner/userName=" + @account.name.downcase.gsub(/\s+/, '')
    elsif @account.game_id == 2
      name = @account.name.gsub(/\s+/, '').split('#')
      return "https://www.overbuff.com/players/pc/" + name.first + "-" + name.last
    end
  end

end
