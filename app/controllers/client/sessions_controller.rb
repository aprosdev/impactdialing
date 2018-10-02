module Client
  class SessionsController < ClientController
    skip_before_filter :check_login, :only => :create
    skip_before_filter :check_tos_accepted, :only => [:create, :destroy]

    if instrument_actions?
      instrument_action :create, :destroy
    end

    def create
      user = User.authenticate(params[:email], params[:password])
      if user
        session[:user] = user.id
        redirect_to client_root_path
      else
        flash_now(:error, "The email or password you entered was incorrect. Please try again.")
        render 'client/sessions/new'
      end
    end

    def destroy
      session[:user]           = nil
      session[:internal_admin] = nil
      flash_message(:notice, "You have been logged out.")
      redirect_to login_path
    end
  end
end
