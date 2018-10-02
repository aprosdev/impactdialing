require 'rails_helper'

describe VoterListsController, :type => :controller do

  describe "API Usage (JSON)" do
    let(:account) { create(:account) }
    before(:each) do
      @user = create(:user, account_id: account.id)
    end

    describe "index" do
      it "should list voter lists for a campaign" do
        voter_list = create(:voter_list)
        campaign = create(:campaign, :account => account, :active => true, voter_lists: [voter_list])
        get :index, campaign_id: campaign.id, :api_key=> account.api_key, :format => "json"
        expect(response.body).to eq campaign.voter_lists.select([:id, :name, :enabled]).to_json
      end
    end

    describe "show" do
      it "should shows voter list " do
        voter_list = create(:voter_list)
        campaign = create(:campaign, :account => account, :active => true, voter_lists: [voter_list, create(:voter_list)])
        get :show, campaign_id: campaign.id, id: voter_list.id, :api_key=> account.api_key, :format => "json"
        expect(response.body).to eq VoterList.select([:id, :name, :enabled]).find(voter_list.id).to_json
      end

      it "should throws 404 if campaign not found " do
        voter_list = create(:voter_list)
        campaign = create(:campaign, :account => account, :active => true, voter_lists: [voter_list, create(:voter_list)])
        get :show, campaign_id: 100, id: voter_list.id, :api_key=> account.api_key, :format => "json"
        expect(response.body).to eq( "{\"message\":\"Resource not found\"}" )
      end

      it "should throws 404 if voter list not found " do
        voter_list = create(:voter_list)
        campaign = create(:campaign, :account => account, :active => true, voter_lists: [voter_list, create(:voter_list)])
        get :show, campaign_id: campaign.id, id: 100, :api_key=> account.api_key, :format => "json"
        expect(response.body).to eq( "{\"message\":\"Resource not found\"}" )
      end

    end

    describe "enable" do
      it "should enable voter list " do
        voter_list = create(:voter_list, enabled: false)
        campaign = create(:campaign, :account => account, :active => true, voter_lists: [voter_list, create(:voter_list)])
        put :enable, campaign_id: campaign.id, id: voter_list.id, :api_key=> account.api_key, :format => "json"
        expect(response.body).to eq( "{\"message\":\"Voter List enabled\"}")
      end
    end

    describe "disable" do
      it "should disable voter list " do
        voter_list = create(:voter_list, enabled: true)
        campaign = create(:campaign, :account => account, :active => true, voter_lists: [voter_list, create(:voter_list)])
        put :disable, campaign_id: campaign.id, id: voter_list.id, :api_key=> account.api_key, :format => "json"
        expect(response.body).to eq( "{\"message\":\"Voter List disabled\"}")
      end
    end

    describe "update" do
      it "should update voter list " do
        voter_list = create(:voter_list, enabled: true, name: "abc")
        campaign = create(:campaign, :account => account, :active => true, voter_lists: [voter_list, create(:voter_list)])
        put :update, campaign_id: campaign.id, id: voter_list.id, voter_list: {name: "xyz"}, :api_key=> account.api_key, :format => "json"
        expect(response.body).to eq( "{\"message\":\"Voter List updated\"}" )
        expect(voter_list.reload.name).to  eq('xyz')
      end
    end

    describe "destroy" do
      it "should update voter list " do
        voter_list = create(:voter_list, enabled: true, name: "abc")
        campaign = create(:campaign, :account => account, :active => true, voter_lists: [voter_list, create(:voter_list)])
        delete :destroy, campaign_id: campaign.id, id: voter_list.id, :api_key=> account.api_key, :format => "json"
        expect(response.body).to eq( "{\"message\":\"This operation is not permitted\"}")
      end
    end

    describe "create" do
      let(:campaign) do
        create(:campaign, {
          :account => account,
          :active => true
        })
      end

      let(:params) do
        {
          campaign_id: campaign.id,
          voter_list: {
            name: "abc.csv",
            separator: ",",
            headers: "[]",
            csv_to_system_map: {
              'ID' => 'custom_id',
              'Phone' => 'phone'
            }
          },
          api_key: account.api_key,
          format: "json"
        }
      end

      context 'API' do
        context 'uploading a valid voter list' do
          let(:file_upload){ '/files/valid_voters_list.csv' }
          let(:csv_upload) do
            {
              'datafile' => fixture_file_upload(file_upload)
            }
          end

          def vcr(&block)
            VCR.use_cassette('API CSV voter list upload', match_requests_on: [:host, :method]) do
              yield
            end
          end

          it 'creates a new VoterList record' do
            vcr do
              expect{
                post :create, params.merge(upload: csv_upload, skip_wireless: 0)
              }.to change{ VoterList.count }.by(1)
            end
          end

          it 'preserves submitted attributes' do
            vcr do
              submitted_params                              = params.merge(upload: csv_upload)
              submitted_params[:voter_list][:skip_wireless] = '0'
              post :create, submitted_params
              list = VoterList.last

              expect(list.name).to eq submitted_params[:voter_list][:name]
              expect(list.separator).to eq submitted_params[:voter_list][:separator]
              expect(list.headers).to eq submitted_params[:voter_list][:headers]
              expect(list.csv_to_system_map).to eq submitted_params[:voter_list][:csv_to_system_map]
              expect(list.campaign_id).to eq submitted_params[:campaign_id]
              expect(list.skip_wireless).to be_falsey
            end
          end

          it "renders voter_list attributes as json" do
            vcr do
              post :create, params.merge(upload: csv_upload)
              expect(response.body).to eq VoterList.select([
                 :id, :name,
                 :campaign_id,
                 :enabled,
                 :skip_wireless,
                 :purpose
              ]).last.to_json
            end
          end

          it 'queues VoterListUploadJob' do
            vcr do
              post :create, params.merge(upload: csv_upload)
            end
            expect([:resque, :import]).to have_queued(CallList::Jobs::Import).with(VoterList.last.id, account.users.first.email)
          end
        end

        context 'uploading voter lists that are not CSV or TSV format' do
          let(:file_upload){ '/files/valid_voters_list.xlsx' }
          let(:csv_upload) do
            {
              'datafile' => fixture_file_upload(file_upload)
            }
          end
          it 'renders a json error message telling the consumer of the incorrect file format' do
            VCR.use_cassette('API invalid file format voter list upload', match_requests_on: [:host, :method]) do
              post :create, params.merge(upload: csv_upload)
              expect(response.body).to eq("{\"errors\":{\"base\":[\"Wrong file format. Please upload a comma-separated value (CSV) or tab-delimited text (TXT) file. If your list is in Excel format (XLS or XLSX), use \\\"Save As\\\" to change it to one of these formats.\"]}}")
            end
          end
        end

        context 'upload requested when no file is submitted' do
          it 'renders a json error message telling the consumer to upload a file' do
            post :create, params.merge(upload: nil)
            expect(response.body).to eq("{\"errors\":{\"uploaded_file_name\":[\"can't be blank\"],\"base\":[\"Please upload a file.\"]}}")
          end
        end
      end
    end

    describe 'column_mapping' do
      let(:campaign) do
        create(:campaign, {
          :account => account,
          :active => true
        })
      end

      let(:params) do
        {
          campaign_id: campaign.id,
          voter_list: {
            name: "abc.csv",
            separator: ",",
            headers: "[]",
            csv_to_system_map: {
              'Phone' => 'Phone'
            },
            s3path: "abc"
          },
          api_key: account.api_key,
          format: "html"
        }
      end

      context 'an empty file is uploaded' do
        let(:file_upload){ '/files/voter_list_empty.csv' }
        let(:csv_upload) do
          {
            'datafile' => fixture_file_upload(file_upload)
          }
        end

        it 'renders an error message telling the consumer that no headers were found in the file' do
          post :column_mapping, params.merge(upload: csv_upload)
          expect(response).to be_success
        end
      end

      context 'a file with only headers is uploaded' do
        let(:file_upload){ '/files/voter_list_only_headers.csv' }
        let(:csv_upload) do
          {
            'datafile' => fixture_file_upload(file_upload)
          }
        end

        it 'renders an error message telling the user that headers were found but no data rows' do
          post :column_mapping, params.merge(upload: csv_upload)
          expect(response).to be_success
        end
      end
    end
  end
end
