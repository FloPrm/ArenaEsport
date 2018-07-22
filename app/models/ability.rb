class Ability
  include CanCan::Ability

  #définition des droits des utilisateurs pour pouvoir utiliser cancancan

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #ROLES = %w[admin moderator standard arena_p captain_p banned].freeze
    user ||= User.new # guest user (not logged in)
    if user.role == nil
        can :read, :all #for guest without roles
    end
    if user.role == "banned"
       can :read, :all #only guest's rights
    end
    if user.role == "standard"
        can :read, :all
        can :update, User
        can :update, History, user_id: user.id
        can :update, Article
    end
    if user.role == "arena_p"
        can :read, :all
        can :update, User
        can :update, Article
        can :update, History, user_id: user.id
        can :manage, Champion
    end
    if user.role == "captain_p"
        can :read, :all
        can :update, User
        can :update, Article
        can :manage, Champion
        can :update, History, user_id: user.id
        can :manage, Friendship
    end
    if user.role == "moderator" #super user, but not allmighty
        can :read, :all?
        can :update, User
        can :destroy, User
        can :update, Team
        can :manage, Article
    end
    if user.role == "admin"
        can :manage, :all
    end
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end
