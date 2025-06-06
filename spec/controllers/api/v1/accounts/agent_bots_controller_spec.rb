require 'rails_helper'

RSpec.describe 'Agent Bot API', type: :request do
  let!(:account) { create(:account) }
  let!(:agent_bot) { create(:agent_bot, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/agent_bots' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/agent_bots"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all the agent_bots in account along with global agent bots' do
        global_bot = create(:agent_bot)
        get "/api/v1/accounts/#{account.id}/agent_bots",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(agent_bot.name)
        expect(response.body).to include(global_bot.name)
        expect(response.body).to include(agent_bot.access_token.token)
        expect(response.body).not_to include(global_bot.access_token.token)
      end

      it 'properly differentiates between system bots and account bots' do
        global_bot = create(:agent_bot)
        get "/api/v1/accounts/#{account.id}/agent_bots",
            headers: agent.create_new_auth_token,
            as: :json

        response_data = response.parsed_body
        # Find the global bot in the response
        global_bot_response = response_data.find { |bot| bot['id'] == global_bot.id }
        # Find the account bot in the response
        account_bot_response = response_data.find { |bot| bot['id'] == agent_bot.id }

        # Verify system_bot attribute and outgoing_url for global bot
        expect(global_bot_response['system_bot']).to be(true)
        expect(global_bot_response).not_to include('outgoing_url')

        # Verify account bot has system_bot attribute false and includes outgoing_url
        expect(account_bot_response['system_bot']).to be(false)
        expect(account_bot_response).to include('outgoing_url')

        # Verify both bots have thumbnail field
        expect(global_bot_response).to include('thumbnail')
        expect(account_bot_response).to include('thumbnail')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/agent_bots/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the agent bot' do
        get "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(agent_bot.name)
        expect(response.body).to include(agent_bot.access_token.token)
      end

      it 'will show a global agent bot' do
        global_bot = create(:agent_bot)
        get "/api/v1/accounts/#{account.id}/agent_bots/#{global_bot.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(global_bot.name)
        expect(response.body).not_to include(global_bot.access_token.token)

        # Test for system_bot attribute and webhook URL not being exposed
        expect(response.parsed_body['system_bot']).to be(true)
        expect(response.parsed_body).not_to include('outgoing_url')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/agent_bots' do
    let(:valid_params) { { name: 'test' } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/agent_bots", params: valid_params }.not_to change(Label, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates the agent bot when administrator' do
        expect do
          post "/api/v1/accounts/#{account.id}/agent_bots", headers: admin.create_new_auth_token,
                                                            params: valid_params
        end.to change(AgentBot, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it 'would not create the agent bot when agent' do
        expect do
          post "/api/v1/accounts/#{account.id}/agent_bots", headers: agent.create_new_auth_token,
                                                            params: valid_params
        end.not_to change(AgentBot, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/agent_bots/:id' do
    let(:valid_params) { { name: 'test_updated' } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
              params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the agent bot' do
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(agent_bot.reload.name).to eq('test_updated')
        expect(response.body).to include(agent_bot.access_token.token)
      end

      it 'would not update the agent bot when agent' do
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
              headers: agent.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(agent_bot.reload.name).not_to eq('test_updated')
      end

      it 'would not update a global agent bot' do
        global_bot = create(:agent_bot)
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{global_bot.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:not_found)
        expect(agent_bot.reload.name).not_to eq('test_updated')
        expect(response.body).not_to include(global_bot.access_token.token)
      end

      it 'updates avatar and includes thumbnail in response' do
        # no avatar before upload
        expect(agent_bot.avatar.attached?).to be(false)
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
              headers: admin.create_new_auth_token,
              params: valid_params.merge(avatar: file)

        expect(response).to have_http_status(:success)
        agent_bot.reload
        expect(agent_bot.avatar.attached?).to be(true)

        # Verify thumbnail is included in the response
        expect(response.parsed_body).to include('thumbnail')
      end

      it 'updated avatar with avatar_url' do
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
              headers: admin.create_new_auth_token,
              params: valid_params.merge(avatar_url: 'http://example.com/avatar.png'),
              as: :json
        expect(response).to have_http_status(:success)
        expect(Avatar::AvatarFromUrlJob).to have_been_enqueued.with(agent_bot, 'http://example.com/avatar.png')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agent_bots/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes an agent bot when administrator' do
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(account.agent_bots.size).to eq(0)
      end

      it 'would not delete the agent bot when agent' do
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(account.agent_bots.size).not_to eq(0)
      end

      it 'would not delete a global agent bot' do
        global_bot = create(:agent_bot)
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{global_bot.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
        expect(account.agent_bots.size).not_to eq(0)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agent_bots/:id/avatar' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        agent_bot.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      end

      it 'delete agent_bot avatar' do
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}/avatar",
               headers: admin.create_new_auth_token,
               as: :json

        expect { agent_bot.avatar.attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/agent_bots/:id/reset_access_token' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}/reset_access_token"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'regenerates the access token when administrator' do
        old_token = agent_bot.access_token.token

        post "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}/reset_access_token",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        agent_bot.reload
        expect(agent_bot.access_token.token).not_to eq(old_token)
        json_response = response.parsed_body
        expect(json_response['access_token']).to eq(agent_bot.access_token.token)
      end

      it 'would not reset the access token when agent' do
        old_token = agent_bot.access_token.token

        post "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}/reset_access_token",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        agent_bot.reload
        expect(agent_bot.access_token.token).to eq(old_token)
      end

      it 'would not reset access token for a global agent bot' do
        global_bot = create(:agent_bot)
        old_token = global_bot.access_token.token

        post "/api/v1/accounts/#{account.id}/agent_bots/#{global_bot.id}/reset_access_token",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
        global_bot.reload
        expect(global_bot.access_token.token).to eq(old_token)
      end
    end
  end
end
