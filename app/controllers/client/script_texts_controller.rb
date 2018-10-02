module Client
  class ScriptTextsController < ClientController
    before_filter :load_and_verify_script
    before_filter :load_script_text, only: [:show, :destroy, :update]
    respond_to :json

    if instrument_actions?
      instrument_action :index, :create, :show, :update, :destroy
    end

    def index
      respond_with(@script.script_texts)
    end
    
    def show
      respond_with(@script_text)
    end
    
    def destroy
      @script_text.destroy
      render :json => { message: 'Script Text Deleted', status: :ok}
    end
    
    def create
      script_text = @script.script_texts.new(script_text_params)
      script_text.save
      respond_with script_text,  location: client_script_script_texts_path      
    end


    def update
      @script_text.update_attributes(script_text_params)
      respond_with @script_text,  location: client_script_script_texts_path do |format|         
        format.json { render :json => {message: "Script Text updated" }, :status => :ok } if @script_text.errors.empty?
      end            
    end

    
  private
    def load_script_text
      begin
        @script_text = @script.script_texts.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        render :json=> {"message"=>"Resource not found"}, :status => :not_found
        return
      end
    end
    
    def load_and_verify_script
      begin
        @script = Script.find(params[:script_id])
      rescue ActiveRecord::RecordNotFound => e
        render :json=> {"message"=>"Resource not found"}, :status => :not_found
        return
      end
      if @script.account != account
        render :json => {message: 'Cannot access script.'}, :status => :unauthorized
        return
      end
    end
    
    def script_text_params
      params.require(:script_text).permit(:content, :script_id, :script_order)
    end    
  end
end
