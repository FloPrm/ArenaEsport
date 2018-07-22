Rails.application.routes.draw do

  resources :urls
  match "/riot.txt" => redirect("/assets/riot.txt"), via: [:get]
  mount ActionCable.server => '/cable'
  mount Ckeditor::Engine => '/ckeditor'

  # get "/:locale " => "home#index"
  root to: redirect("/#{I18n.locale}", status: 302), as: "i18n_root"

  scope "(:locale)", locale: /fr|en/ do

    resources :karmas
    resources :pollings
    resources :notes
    resources :wallet_histories
    resources :badges
    resources :histories
    resources :tournaments
    resources :feedbacks
    resources :mentors
    resources :search_suggestions
    resources :champions
    resources :articles
    resources :legal
    resources :plannings
    resources :whitelists
    resources :messages
    resources :discord
    # resources :home
    resources :contacts

    resources :users do
      member do
        get :user_preview
        get :avatar_modal
        put :avatar
        get :leave_search_modal
        get :leave_search
        get :edit_role_modal
        patch :edit_role
        patch :edit_state
        put :add_champion
        put :remove_champion
        put :change_language
        put :search_team
      end
    end

    resources :game_accounts do
      member do
        get :get_game_rank
        get :refresh
        get :refresh_account
        get :activate_game_account
        post :choose_game
      end
    end

    resources :teams do
      member do
        get :preview
        get :add_user
        get :remove_user
        get :leave_modal
        get :dissolution_modal
        get :listing
        get :role_collection
        post :role_collection
        get :add_role
        post :add_role
        post :change_role
        get :modify_modal
        put :modify
        put :tofit
        put :remplacement
        put :start
        put :dissolution
        get :tabs_refresh
      end
    end

    resources :games do
      member do
        put :roles
      end
    end

    resources :polls do
      member do
        get :tabs
        put :choices
      end
    end

    resources :compositions do
      member do
        put :add_champion
        put :remove_champion
        put :ratio
      end
    end

    resources :team_applications do
      member do
        get :reject
        put :answer
      end
    end

    get 'recruitment_center' => 'team_applications#recruitment_center', as: "recruitment_center"

    resources :subscription_plans do
      member do
        put :select_duration
        get :informations
        put :payment
        get :payment_response
        get :payment_result
        get :restricted_content
      end
    end

    resources :subscriptions do
      member do
        post :renewal
        put :state
      end
    end

    resources :wallets do
      member do
        get :virtual_currency
        put :manager
        get :informations
        post :payment
        get :payment_response
        get :payment_result
      end
    end

    resources :discord do
      member do
        get :team_preview
      end
    end

    resources :achievements do
      member do
        put :add_user
      end
    end

    resources :seances do
      member do
        put :validate
      end
    end

    resources :mentorats do
      member do
        get :mentorat_preview
        put :change_teacher
        put :claim
        put :stop
      end
    end

    resources :premades do
      member do
        put :leave
        put :kick
      end
    end

    resources :invitations do
      member do
        get :generate_parrainage_link
        put :accept
        put :decline
      end
    end

    resources :friendships do
      member do
        put :accept
        put :decline
        put :remove
        put :block
        put :unblock
      end
    end

    resources :votes do
      member do
        put :election
      end
    end

    resources :teamings do
      member do
        put :swap
        put :swaper
        put :swap_captain
        put :advices_validation
      end
    end

    resources :notifications do
      member do
        put :mark_as_read
        get :mark_read
      end
    end

    devise_for :users, skip: :omniauth_callbacks, :controllers => { :registrations => "users/registrations" }

    devise_scope :user do
      get "sign_up", to: "devise/registrations#new"
      get '/users/:id/password/edit', to: "devise/passwords#edit", as: "reset_pw"
      put '/update_password', to: "devise/passwords#update", as: "update_pw"
      get '/registration/edit' => 'devise/registrations#edit'
      post "/registration/create" => "users/registrations#create", as: "create_user"
      get "/password/reset" => "devise/passwords#edit"
      get "login", to: "devise/sessions#new"
      get "logout", to: "devise/sessions#destroy"
    end

=begin
    devise_for :users, skip: :omniauth_callbacks, :controllers => { registrations: "registrations" } do
      get 'users/sign_up' => 'devise/registrations#new'
      #get '/users/edit' => 'devise/registrations#edit'
    end

    devise_scope :user do
     get "sign_up", to: "devise/registrations#new"
     get "login", to: "devise/sessions#new"
     get "logout", to: "devise/sessions#destroy"
   end
=end

    get 'dashboard' => 'users#dashboard'
    get 'second_step' => 'game_accounts#second_step'
    get 'third_step' => 'users#third_step'
    get 'searching_team' => 'users#searching_team'
    get 'leave_team' => 'users#leave_team'

    get 'subscription/manager' => 'subscriptions#manager', as: 'subscriptions_manager'

    get 'about' => 'home#about'
    get 'admin_panel' => 'home#admin_panel'
    get 'codename_fifty' => 'home#code'
    get 'analytics' => 'home#analytics'
    get 'parrainages' => 'users#parrainages'
    get 'join_us' => 'home#join_us'
    get 'our_partners' => 'home#our_partners', as: 'our_partners'
    get 'our_streamers' => 'home#our_streamers', as: 'our_streamers'
    get 'our_team' => 'home#our_team', as: 'our_team'
    get 'pricing' => 'home#pricing', as: 'pricing'
    get 'pantheon' => 'home#pantheon', as: 'pantheon'
    get 'profil'  => 'home#profil_user_type'
    get 'unsubscribe' => 'home#unsubscribe', as: 'unsubscribe'
    get 'eula' => 'legal#eula', as: 'eula'
    get 'cgu' => 'legal#cgu', as: 'cgu'

    scope '/wallets', :controller => :wallets do
      post :notification
    end

    get 'index.php/joueurs-lol' => 'home#old_page'
    get 'index.php/joueurs-ow' => 'home#old_page'
    get 'index.php' => 'home#old_page'
    get '/index.php/*path' => 'home#old_page'
    get '/components/*path' => 'home#old_page'
    get '/images/*path' => 'home#old_page'
    get '/administrator/*path' => 'home#old_page'
    get '/modules/*path' => 'home#old_page'

    get 'team_builder' => 'teams#team_builder'

    post 'analytics_search', :to => 'home#analytics_search', :as => 'analytics_search'

    get 'contact' => 'contacts#new'

    root to: "home#index"

  end

  get '/:short_url', to: 'urls#show'

end
