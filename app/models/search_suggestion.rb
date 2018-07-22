class SearchSuggestion < ActiveRecord::Base

  def self.terms_for(prefix)
    Rails.cache.fetch(["search-terms", prefix]) do
      suggestions = where("term like ?", "%#{prefix}%")
      suggestions.order("popularity desc").limit(5).pluck(:term)
    end
  end

  def self.index_champions
    Champion.find_each do |champion|
      index_term(champion.name)
    end
  end

  def self.index_term(term)
    where(term: term.downcase).first_or_initialize.tap do |suggestion|
      suggestion.increment! :popularity
    end
  end

end
