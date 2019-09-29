Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root   'tasks#index'

  get    '/terms_of_service', to: 'pages#terms_of_service'

  get    '/signup', to: 'users#new'
  post   '/signup', to: 'users#create'
  get    '/thanks', to: 'users#thanks'
  get    '/user_profile', to: 'users#edit'

  get    '/resend_activation', to: 'account_activations#resend'
  get    '/password_resets/confirmation', to: 'password_resets#sent', as: :password_reset_sent

  get    '/login',  to: 'sessions#new'
  post   '/login',  to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  get    'settings/edit'
  post   'settings/toggle_display_quotes'

  get    'task_categories/delete_confirmation/:id', to: 'task_categories#delete_confirmation', as: :task_category_delete_with_confirmation

  get    'tasks/upcoming', to: 'tasks#upcoming', as: :upcoming_tasks
  get    'tasks/search', to: 'tasks#search', as: :search_tasks
  post   'task/toggle_task_status/:id', to: 'tasks#toggle_task_status', as: :toggle_task_status
  post   'task/advance_overdue_tasks', to: 'tasks#advance_overdue_tasks', as: :advance_overdue_tasks

  resources :users,               except: [:index, :show, :edit]
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :tasks
  resources :task_categories,     except: [:new]
  resources :quotes,              except: [:new]
end
