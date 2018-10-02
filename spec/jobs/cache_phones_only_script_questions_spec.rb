require 'rails_helper'

describe 'CachePhonesOnlyScriptQuestions' do
  include FakeCallData

  def update_script(script)
    questions = script.questions.order('id').to_a

    script.update_attributes!({
      questions_attributes: [
        {
          id: questions[0].id,
          text: "Updated Question #{questions[0].id}",
          possible_responses_attributes: [
            {
              id: questions[0].possible_responses[0].id,
              value: "Updated PossibleResponse #{questions[0].possible_responses[0].id}",
              keypad: 23
            },
            {
              id: questions[0].possible_responses[1].id,
              value: "Updated PossibleResponse #{questions[0].possible_responses[1].id}",
              keypad: 24
            }
          ]
        },
        {
          id: questions[1].id,
          text: "Updated Question #{questions[1].id}",
          possible_responses_attributes: [
            {
              id: questions[1].possible_responses[0].id,
              value: "Updated PossibleResponse #{questions[1].possible_responses[0].id}",
              keypad: 25
            },
            {
              id: questions[1].possible_responses[1].id,
              value: "Updated PossibleResponse #{questions[1].possible_responses[1].id}",
              keypad: 26
            }
          ]
        }
      ]
    })
  end

  before do
    Question.destroy_all
    PossibleResponse.destroy_all
    admin   = create(:user)
    account = admin.account
    @script = create_campaign_with_script(:bare_power, account).first
  end

  after do
    RedisQuestion.clear_list(@script.id)
    @script.questions.pluck(:id).each do |question_id|
      RedisPossibleResponse.clear_list(question_id)
    end
    RedisQuestion.redis.del(RedisQuestion.checksum_key(@script.id))
  end

  describe '.add_to_queue(script_id, action)' do
    it 'can queue itself, whynot?' do
      expect(Resque).to receive(:enqueue).with(CachePhonesOnlyScriptQuestions, 42, 'mice')

      CachePhonesOnlyScriptQuestions.add_to_queue(42, 'mice')
    end
  end

  describe '.perform(script_id, "seed")' do
    it 'seeds the question & possible response cache if no cache data will be overwritten' do
      qlist_length = CachePhonesOnlyScriptQuestions.redis.llen(RedisQuestion.key(@script.id))
      expect(qlist_length).to be_zero

      CachePhonesOnlyScriptQuestions.perform(@script.id, 'seed')

      qlist_length = RedisQuestion.redis.llen(RedisQuestion.key(@script.id))
      expected     = @script.questions.count
      expect(qlist_length).to(eq(expected), [
        "Expected RedisQuestion to have #{expected} questions cached",
        "Got #{qlist_length}"
      ].join("\n"))

      question = @script.questions.first
      rlist_length = RedisPossibleResponse.redis.llen(RedisPossibleResponse.key(question.id))
      expect(rlist_length).to eq question.possible_responses.count
    end

    it 'does nothing if cache will be overwritten' do
      CachePhonesOnlyScriptQuestions.perform(@script.id, 'seed')

      new_text = 'Updated Question Text that should not appear in cache'
      @script.questions.update_all(text: new_text)

      CachePhonesOnlyScriptQuestions.perform(@script.id, 'seed')

      question = RedisQuestion.get_question_to_read(@script.id, 0)
      expect(question['question_text']).to_not eq new_text
    end

    it 'sets TTL for relevant keys' do
      CachePhonesOnlyScriptQuestions.perform(@script.id, 'seed')

      actual   = RedisQuestion.redis.ttl(RedisQuestion.key(@script.id))
      expected = (5.hours + 59.minutes)

      expect(actual > expected).to be_truthy

      @script.questions.each do |question|
        oops = "Expected key[#{RedisPossibleResponse.key(question.id)}] to have TTL but it did not\n"

        actual = RedisPossibleResponse.redis.ttl(RedisPossibleResponse.key(question.id))

        expect(actual > expected).to(be_truthy, oops)
      end
    end
  end

  describe '.perform(script_id, "update")' do
    context 'questions or possible responses have changed and exist in cache' do
      before do
        CachePhonesOnlyScriptQuestions.perform(@script.id, 'seed')

        update_script(@script)
        CachePhonesOnlyScriptQuestions.perform(@script.id, 'update')
      end

      let(:questions){ Question.where(1).to_a }

      it 'updates questions cache' do
        question = RedisQuestion.get_question_to_read(@script.id, 0)

        expect(question['question_text']).to eq questions[0].text

        question = RedisQuestion.get_question_to_read(@script.id, 1)
        expect(question['question_text']).to eq questions[1].text
      end

      it 'updates possible responses cache' do
        updated_questions = @script.questions[0..1]
        question_ids      = updated_questions.map(&:id)

        actuals = RedisPossibleResponse.possible_responses(question_ids.first)
        expect(actuals[0]['value']).to eq Question.find(question_ids.first).possible_responses.find_by_keypad(actuals[0]['keypad']).value
        expect(actuals[1]['value']).to eq Question.find(question_ids.first).possible_responses.find_by_keypad(actuals[1]['keypad']).value

        actuals = RedisPossibleResponse.possible_responses(question_ids.last)
        expect(actuals[0]['value']).to eq Question.find(question_ids.last).possible_responses.find_by_keypad(actuals[0]['keypad']).value
        expect(actuals[1]['value']).to eq Question.find(question_ids.last).possible_responses.find_by_keypad(actuals[1]['keypad']).value
      end
    end

    context 'neither questions nor possible responses have changed and exist in cache' do
      before do
        CachePhonesOnlyScriptQuestions.perform(@script.id, 'seed')
      end
      it 'does not modify the cache' do
        expect(RedisQuestion.cached?(@script.id)).to be_truthy
        expect(RedisQuestion).to_not receive(:persist_questions)
        expect(RedisPossibleResponse).to_not receive(:persist_possible_response)

        CachePhonesOnlyScriptQuestions.perform(@script.id, 'update')
      end
    end

    context 'questions or possible responses have changed but do not exist in cache' do
      before do
        CachePhonesOnlyScriptQuestions.perform(@script.id, 'update')
      end
      it 'does not seed questions cache (cache is seeded at CallinController#identify)' do
        actual = RedisQuestion.cached?(@script.id)
        expect(actual).to be_falsey
      end

      it 'does not seed possible responses cache (cache is seeded at CallinController#identify)' do
        @script.questions.each do |question|
          oops   = "Expected RedisPossibleResponse to not have an entry for question: #{question.id}"
          actual = RedisPossibleResponse.cached?(question.id)

          expect(actual).to(be_falsey, oops)
        end
      end
    end

    context 'script is not active' do
      before do
        CachePhonesOnlyScriptQuestions.perform(@script.id, 'seed')
        @script.campaigns.update_all(active: false)
        @script.update_attributes!(active: false)
        CachePhonesOnlyScriptQuestions.perform(@script.id, 'seed')
      end

      it 'deletes the RedisQuestion list' do
        expect(RedisQuestion.cached?(@script.id)).to be_falsey
      end

      it 'deletes the RedisPossibleResponse lists' do
        @script.questions.each do |question|
          expect(RedisPossibleResponse.cached?(@script.id)).to be_falsey
        end
      end
    end
  end
end
