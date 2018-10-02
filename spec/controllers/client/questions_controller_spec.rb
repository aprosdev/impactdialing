require 'rails_helper'

describe Client::QuestionsController, :type => :controller do
  let(:account) { create(:account) }
  before(:each) do
    @user = create(:user, account_id: account.id)
  end



  describe "index" do
    it "should return questions for a script" do
      active_script = create(:script, :account => account, :active => true)
      question1 = create(:question, text: "abc", script_order: 1, script: active_script)
      question2 = create(:question, text: "def", script_order: 2, script: active_script)
      get :index, script_id: active_script.id, :api_key=> account.api_key, :format => "json"
      expect(response.body).to eq("[#{question1.to_json},#{question2.to_json}]")
    end
  end

  describe "show" do
    it "should return question " do
      active_script = create(:script, :account => account, :active => true)
      question      = create(:question, text: "abc", script_order: 1, script: active_script)

      get :show, script_id: active_script.id, id: question.id,  :api_key=> account.api_key, :format => "json"
      expect(response.body).to eq question.to_json
    end

    it "should 404 if script not found" do
      active_script = create(:script, :account => account, :active => true)
      question = create(:question, text: "abc", script_order: 1, script: active_script)
      get :show, script_id: 100, id: question.id,  :api_key=> account.api_key, :format => "json"
      expect(response.body).to eq("{\"message\":\"Resource not found\"}")
    end

    it "should 404 if question not found in script" do
      active_script = create(:script, :account => account, :active => true)
      question = create(:question, text: "abc", script_order: 1, script: active_script)
      get :show, script_id: active_script.id, id: 100,  :api_key=> account.api_key, :format => "json"
      expect(response.body).to eq("{\"message\":\"Resource not found\"}")
    end


  end

  describe "destroy" do
    it "should delete question" do
      active_script = create(:script, :account => account, :active => true)
      question = create(:question, text: "abc", script_order: 1, script: active_script)
      delete :destroy, script_id: active_script.id, id: question.id,  :api_key=> account.api_key, :format => "json"
      expect(response.body).to eq("{\"message\":\"Question Deleted\",\"status\":\"ok\"}")
    end
  end

  describe "create" do
    it "should create question" do
      active_script = create(:script, :account => account, :active => true)
      post :create, script_id: active_script.id, question: {text: "Hi", script_order: 1},  :api_key=> account.api_key, :format => "json"
      question = active_script.questions.first
      expect(response.body).to eq question.to_json
    end

    it "should throw validation error" do
      active_script = create(:script, :account => account, :active => true)
      post :create, script_id: active_script.id, question: {text: "Hi"},  :api_key=> account.api_key, :format => "json"
      expect(response.body).to eq("{\"errors\":{\"script_order\":[\"can't be blank\",\"is not a number\"]}}")
    end

  end

  describe "update" do
    it "should update a question" do
      active_script = create(:script, :account => account, :active => true)
      question = create(:question, text: "abc", script_order: 1, script: active_script)
      put :update, script_id: active_script.id, id: question.id, question: {text: "Hi"},  :api_key=> account.api_key, :format => "json"
      expect(response.body).to eq("{\"message\":\"Question updated\"}")
      expect(question.reload.text).to eq("Hi")
    end

    it "should throw validation error" do
      active_script = create(:script, :account => account, :active => true)
      question = create(:question, text: "abc", script_order: 1, script: active_script)
      put :update, script_id: active_script.id, id: question.id, question: {text: "Hi", script_order: nil},  :api_key=> account.api_key, :format => "json"
      expect(response.body).to eq("{\"errors\":{\"script_order\":[\"can't be blank\",\"is not a number\"]}}")
    end

  end




end
