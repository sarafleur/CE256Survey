Rails.application.routes.draw do
  resources :answers
  get '/admin' =>'admin#index'
  post '/admin/data' => 'admin#data'
  get '/admin/data' => 'admin#data'
  get '/admin/csv' => 'admin#export_csv'


  #Survey routes
  get '/' => 'answers#open_page'
  get '/new' => 'answers#new_survey'
  post '/new' => 'answers#new_survey_creation'
  get '/page1' => 'answers#render_page1'
  post '/page1' => 'answers#answer_page1'
  get '/page1bis' => 'answers#render_page1bis'
  post '/page1bis' => 'answers#answer_page1bis'
  get '/page2' => 'answers#render_page2'
  post '/page2' => 'answers#answer_page2'
  get '/page3' => 'answers#render_page3'
  post '/page3' => 'answers#answer_page3'
  get '/activity1' => 'answers#render_activity1'
  post '/activity1' => 'answers#answer_activity1'
  get '/activity2' => 'answers#render_activity2'
  post '/activity2' => 'answers#answer_activity2'
  get '/last' => 'answers#render_last'
  get 'skip' => 'answers#render_activity1'




  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
