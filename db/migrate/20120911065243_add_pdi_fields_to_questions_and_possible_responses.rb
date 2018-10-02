class AddPdiFieldsToQuestionsAndPossibleResponses < ActiveRecord::Migration
  def change
    add_column :questions, :external_id_field, :string
    add_column :possible_responses, :external_id_field, :string
  end
end
