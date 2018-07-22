module ApplicationHelper

  def controller?(controller)
    # Add une asterisque avant le paramètre (*controller) pour le transformer en params[:controller]
    # controller.include?(params[:controller])
    controller_name == controller
  end

  def action?(action)
    # action.include?(params[:action])
    action_name == action
  end

  def generate_parrainage_link(user)
    @user = user
    @invitation = Invitation.new(sender_id: @user.id)
    @token = Digest::SHA1.hexdigest([@user.id, Time.now, rand].join)
    @invitation.token = @token
    @invitation.save
    if @user.urls.first.nil?
      generate_url(@user)
    end
  end

  def generate_url(user)
    @user = user
    @invitation = @user.invitations.first
    chars = ["0".."9", "A".."Z", "a".."z"].map { |range| range.to_a }.flatten
    @url = Url.new(user: @user)
    @url.short = loop do
      short = 6.times.map{chars.sample}.join
      break short if Url.find_by_short(short).nil?
    end
    @url.original = sign_up_url(token: @invitation.token)
    @url.save
  end

  # Always use the Twitter Bootstrap pagination renderer
  def will_paginate(collection_or_options = nil, options = {})
    if collection_or_options.is_a? Hash
      options, collection_or_options = collection_or_options, nil
    end
    unless options[:renderer]
      options = options.merge :renderer => BootstrapPagination::Rails
    end
    super *[collection_or_options, options].compact
  end

  def mmr_gold_mini?
    unless current_user.account.nil? or current_user.account.real_game_id.nil?
      @mmrs = [current_user.account.mmr] + [current_user.account.flex_mmr]
      @mmrs.reject(&:nil?).sort.last >= current_user.account.game.mentorat_mmr
    end
  end

  def has_soloq?
    current_user.account.game.has_soloq
  end

  def has_teamq?
    current_user.account.game.has_teamq
  end

  def account_rank_gap?(account1, account2)
    @account1 = account1
    @account2 = account2

    if @account1.game_id == 1
      if @account1.flex_mmr.nil?
        get_game_rank_game_account_url(@account1)
      end
      if @account2.flex_mmr.nil?
        get_game_rank_game_account_url(@account2)
      end
      value1 = (@account1.flex_mmr / 200).floor
      value2 = (@account2.flex_mmr / 200).floor
      numbers = [value1, value2].sort.reverse
      gap = numbers.first - numbers.last
      gap >= 2
    elsif @account1.game_id == 2
      numbers = [@account1.mmr, @account2.mmr].sort.reverse
      gap = numbers.first - numbers.last
      gap > 1000
    else
      false
    end
  end

  def value_rank_gap?(value1, value2, game_id)
    if game_id == 1
      @value1 = (value1 / 200).floor
      @value2 = (value2 / 200).floor

      gap >= 2
    elsif game_id == 2
      @value1 = value1
      @value2 = value2
      gap > 1000
    else
      false
    end
  end
end
